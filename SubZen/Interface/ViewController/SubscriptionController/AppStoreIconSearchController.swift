//
//  AppStoreIconSearchController.swift
//  SubZen
//
//  Created by Codex on 2026/1/7.
//

import UIKit

final class AppStoreIconSearchController: UITableViewController {
    private enum Constants {
        static let reuseIdentifier = "AppStoreIconSearchCell"
        static let debounceNanoseconds: UInt64 = 350_000_000
        static let minimumQueryLength = 2
    }

    private let iconRemoteService: SubscriptionIconRemoteService
    private var results: [AppStoreSearchResult] = []
    private var shouldFocusSearchOnAppear = true

    private var activeSearchToken = UUID()
    private var queryTask: Task<Void, Never>?
    private var artworkTasks: [IndexPath: Task<Void, Never>] = [:]
    private let artworkCache = NSCache<NSURL, UIImage>()

    var onSelectResult: ((AppStoreSearchResult) -> Void)?
    var onSelectAppID: ((Int) -> Void)?

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchResultsUpdater = self
        controller.searchBar.autocapitalizationType = .none
        controller.searchBar.autocorrectionType = .no
        controller.searchBar.delegate = self
        return controller
    }()

    private let loadingIndicator = UIActivityIndicatorView(style: .medium).with {
        $0.hidesWhenStopped = true
    }

    init(iconRemoteService: SubscriptionIconRemoteService) {
        self.iconRemoteService = iconRemoteService
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String(localized: "Fetch App Store Icon")
        navigationItem.searchController = searchController
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: loadingIndicator)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(handleCloseTapped)
        )
        definesPresentationContext = true

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.reuseIdentifier)
        tableView.keyboardDismissMode = .onDrag
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard shouldFocusSearchOnAppear else { return }
        shouldFocusSearchOnAppear = false

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.searchController.isActive = true
            self.searchController.searchBar.searchTextField.becomeFirstResponder()
        }
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        results.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.reuseIdentifier, for: indexPath)
        let result = results[indexPath.row]

        var content = UIListContentConfiguration.subtitleCell()
        content.text = result.name
        content.textProperties.font = .systemFont(ofSize: 17, weight: .semibold)
        content.secondaryText = result.sellerName
        content.secondaryTextProperties.font = .systemFont(ofSize: 15, weight: .regular)
        content.secondaryTextProperties.color = .secondaryLabel

        content.image = UIImage.subZenAppIconPlaceholder
        content.imageProperties.maximumSize = CGSize(width: 34, height: 34)
        content.imageProperties.cornerRadius = 8

        cell.contentConfiguration = content

        var background = UIBackgroundConfiguration.listGroupedCell()
        background = background.updated(for: cell.configurationState)
        cell.backgroundConfiguration = background

        loadArtworkIfNeeded(for: result, into: cell, at: indexPath)
        return cell
    }

    override func tableView(_ tableView: UITableView, didEndDisplaying _: UITableViewCell, forRowAt indexPath: IndexPath) {
        artworkTasks[indexPath]?.cancel()
        artworkTasks[indexPath] = nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selection = results[indexPath.row]
        let onSelect = onSelectResult
        dismiss(animated: true) {
            onSelect?(selection)
        }
    }

    private func setLoading(_ isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }

    private func loadArtworkIfNeeded(for result: AppStoreSearchResult, into cell: UITableViewCell, at indexPath: IndexPath) {
        guard let url = result.listArtworkURL else { return }

        if let cached = artworkCache.object(forKey: url as NSURL) {
            if var content = cell.contentConfiguration as? UIListContentConfiguration {
                content.image = cached
                cell.contentConfiguration = content
            }
            return
        }

        artworkTasks[indexPath]?.cancel()
        artworkTasks[indexPath] = Task { [weak self, weak cell] in
            guard let self else { return }
            do {
                let data = try await iconRemoteService.fetchImageData(from: url)
                guard let image = UIImage(data: data) else { return }
                artworkCache.setObject(image, forKey: url as NSURL)

                await MainActor.run {
                    guard let cell, self.tableView.indexPath(for: cell) == indexPath else { return }
                    if var content = cell.contentConfiguration as? UIListContentConfiguration {
                        content.image = image
                        cell.contentConfiguration = content
                    }
                }
            } catch {
                return
            }
        }
    }

    private func clearResults() {
        activeSearchToken = UUID()
        queryTask?.cancel()
        queryTask = nil

        artworkTasks.values.forEach { $0.cancel() }
        artworkTasks.removeAll()

        results = []
        tableView.reloadData()
        setLoading(false)
    }

    private func search(for query: String) {
        let token = UUID()
        activeSearchToken = token
        queryTask?.cancel()
        queryTask = Task { [weak self] in
            guard let self else { return }

            try? await Task.sleep(nanoseconds: Constants.debounceNanoseconds)
            guard !Task.isCancelled else { return }

            let shouldContinue = await MainActor.run { () -> Bool in
                guard token == self.activeSearchToken else { return false }
                self.setLoading(true)
                return true
            }
            guard shouldContinue else { return }

            do {
                let results = try await iconRemoteService.searchAppStoreApps(term: query)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard token == self.activeSearchToken else { return }
                    self.results = results
                    self.artworkTasks.values.forEach { $0.cancel() }
                    self.artworkTasks.removeAll()
                    self.tableView.reloadData()
                    self.setLoading(false)
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard token == self.activeSearchToken else { return }
                    self.clearResults()
                }
            }
        }
    }

    @objc private func handleCloseTapped() {
        dismiss(animated: true)
    }
}

extension AppStoreIconSearchController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = (searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= Constants.minimumQueryLength else {
            clearResults()
            return
        }

        search(for: query)
    }
}

extension AppStoreIconSearchController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let query = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= Constants.minimumQueryLength else { return }

        let onSelectAppID = onSelectAppID
        guard let appID = AppStoreAppIDParser.parseAppID(from: query) else { return }
        dismiss(animated: true) {
            onSelectAppID?(appID)
        }
    }
}
