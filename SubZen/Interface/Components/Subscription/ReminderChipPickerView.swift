import SnapKit
import UIKit

final class ReminderChipPickerView: UIView {
    private let segmentedControl = UISegmentedControl()
    private let cornerRadius: CGFloat

    private var options: [Int] = []
    private var reduceTransparencyActive = UIAccessibility.isReduceTransparencyEnabled
    private var isProgrammaticSelectionUpdate = false

    var selectedInterval: Int? {
        didSet { updateSelection() }
    }

    init(cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
        super.init(frame: .zero)
        configureView()
        buildHierarchy()
        setupConstraints()
    }

    private func configureView() {
        segmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        segmentedControl.addTarget(self, action: #selector(handleValueChanged(_:)), for: .valueChanged)
        EditSubscriptionSelectionStyler.configureSegmentedControl(
            segmentedControl,
            cornerRadius: cornerRadius
        )
    }

    private func buildHierarchy() {
        addSubview(segmentedControl)
    }

    private func setupConstraints() {
        segmentedControl.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(options: [Int]) {
        guard self.options != options else { return }
        self.options = options

        segmentedControl.removeAllSegments()
        for (index, option) in options.enumerated() {
            segmentedControl.insertSegment(withTitle: Self.title(for: option), at: index, animated: false)
        }

        if let selected = selectedInterval, !options.contains(selected) {
            selectedInterval = nil
        } else {
            updateSelection()
        }

        updateAppearance(reduceTransparencyActive: reduceTransparencyActive)
    }

    func updateAppearance(reduceTransparencyActive newValue: Bool) {
        reduceTransparencyActive = newValue
        EditSubscriptionSelectionStyler.applySegmentedStyle(
            to: segmentedControl,
            reduceTransparencyActive: newValue
        )
    }

    private func updateSelection() {
        isProgrammaticSelectionUpdate = true
        if let selected = selectedInterval, let index = options.firstIndex(of: selected) {
            segmentedControl.selectedSegmentIndex = index
        } else {
            segmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        }
        isProgrammaticSelectionUpdate = false
    }

    @objc private func handleValueChanged(_ sender: UISegmentedControl) {
        guard !isProgrammaticSelectionUpdate else { return }

        let selectedIndex = sender.selectedSegmentIndex
        guard selectedIndex != UISegmentedControl.noSegment else {
            selectedInterval = nil
            return
        }

        let value = options[selectedIndex]
        if selectedInterval == value {
            selectedInterval = nil
        } else {
            selectedInterval = value
        }
    }

    private static func title(for days: Int) -> String {
        switch days {
        case 1:
            String(localized: "1 day before")
        case 3:
            String(localized: "3 days before")
        case 7:
            String(localized: "7 days before")
        default:
            String(localized: "\(days) days before")
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}
