//
//  CurrencyPickerController.swift
//  SubZen
//
//  Created by Codex on 2025/8/28.
//

import UIKit

final class CurrencyPickerController: UITableViewController {
    private enum Constants {
        static let reuseIdentifier = "CurrencyPickerCell"
    }

    private let allCurrencies: [Currency]
    private var filteredCurrencies: [Currency]
    private var selectedCode: String?
    var onSelectCurrency: ((Currency) -> Void)?

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchResultsUpdater = self
        controller.searchBar.autocapitalizationType = .allCharacters
        controller.searchBar.autocorrectionType = .no
        controller.searchBar.placeholder = String(localized: "currencyPicker.search.placeholder")
        return controller
    }()

    init(currencies: [Currency], selectedCode: String?) {
        let sortedCurrencies = currencies.sorted { lhs, rhs in
            lhs.code < rhs.code
        }
        allCurrencies = sortedCurrencies
        filteredCurrencies = sortedCurrencies
        self.selectedCode = selectedCode?.uppercased()
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "currencyPicker.title")
        navigationItem.searchController = searchController
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(handleCloseTapped))
        definesPresentationContext = true

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.reuseIdentifier)
        tableView.keyboardDismissMode = .onDrag
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        filteredCurrencies.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.reuseIdentifier, for: indexPath)
        let currency = filteredCurrencies[indexPath.row]

        var content = UIListContentConfiguration.subtitleCell()
        content.text = currency.name
        let displaySymbol = CurrencyList.displaySymbol(for: currency.code)
        let symbolPart = displaySymbol.caseInsensitiveCompare(currency.code) == .orderedSame
            ? currency.code
            : "\(displaySymbol) \(currency.code)"
        content.secondaryText = symbolPart
        content.textProperties.font = .systemFont(ofSize: 17, weight: .semibold)
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content

        if currency.code == selectedCode {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let currency = filteredCurrencies[indexPath.row]
        selectedCode = currency.code
        onSelectCurrency?(currency)
        dismiss(animated: true)
    }

    private func filterCurrencies(with query: String?) {
        guard let query, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            filteredCurrencies = allCurrencies
            tableView.reloadData()
            return
        }

        let lowercasedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        filteredCurrencies = allCurrencies.filter { currency in
            let codeMatch = currency.code.lowercased().contains(lowercasedQuery)
            let nameMatch = currency.name.lowercased().contains(lowercasedQuery)
            let symbolMatch = CurrencyList.displaySymbol(for: currency.code).lowercased().contains(lowercasedQuery)
            return codeMatch || nameMatch || symbolMatch
        }
        tableView.reloadData()
    }

    @objc private func handleCloseTapped() {
        dismiss(animated: true)
    }
}

extension CurrencyPickerController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterCurrencies(with: searchController.searchBar.text)
    }
}
