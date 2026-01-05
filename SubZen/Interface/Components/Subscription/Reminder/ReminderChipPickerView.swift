import SnapKit
import UIKit

final class ReminderChipPickerView: UIView {
    private enum Layout {
        static let stackSpacing: CGFloat = 8
    }

    private let segmentedControl = UISegmentedControl()
    private let customPickerView = ValueUnitPickerView(
        labelText: String(localized: "Custom"),
        units: [.day],
        initialValue: 5,
        initialUnit: .day
    )
    private let expandableView: ExpandableSegmentedControlView

    private var options: [Int] = []
    private var customInterval: Int = 5
    private var reduceTransparencyActive = UIAccessibility.isReduceTransparencyEnabled
    private var isProgrammaticSelectionUpdate = false
    private var isCustomSelected = false

    var selectedInterval: Int? {
        didSet { updateSelection() }
    }

    var onSelectionChanged: ((Int?) -> Void)?

    init(cornerRadius: CGFloat) {
        expandableView = ExpandableSegmentedControlView(
            segmentedControl: segmentedControl,
            customContentView: customPickerView,
            cornerRadius: cornerRadius,
            spacing: Layout.stackSpacing
        )
        super.init(frame: .zero)
        configureView()
        buildHierarchy()
        setupConstraints()
    }

    private func configureView() {
        segmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        segmentedControl.addTarget(self, action: #selector(handleValueChanged(_:)), for: .valueChanged)

        customPickerView.onSelectionChanged = { [weak self] value, _ in
            guard let self else { return }
            isCustomSelected = true
            customInterval = value
            selectedInterval = value
            onSelectionChanged?(selectedInterval)
        }
    }

    private func buildHierarchy() {
        addSubview(expandableView)
    }

    private func setupConstraints() {
        expandableView.snp.makeConstraints { make in
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
        segmentedControl.insertSegment(withTitle: String(localized: "Custom"), at: options.count, animated: false)

        if let selectedInterval {
            if options.contains(selectedInterval) {
                isCustomSelected = false
            } else {
                isCustomSelected = true
                customInterval = selectedInterval
            }
        } else {
            isCustomSelected = false
        }

        updateSelection()
        updateAppearance(reduceTransparencyActive: reduceTransparencyActive)
    }

    func updateAppearance(reduceTransparencyActive newValue: Bool) {
        reduceTransparencyActive = newValue
        expandableView.updateAppearance(reduceTransparencyActive: newValue)
    }

    private func updateSelection() {
        isProgrammaticSelectionUpdate = true
        if let selectedInterval {
            if isCustomSelected {
                segmentedControl.selectedSegmentIndex = options.count
                customPickerView.configure(value: selectedInterval, unit: .day)
                customInterval = selectedInterval
                expandableView.setCustomContentVisible(true, animated: false, layoutView: superview)
            } else if let index = options.firstIndex(of: selectedInterval) {
                segmentedControl.selectedSegmentIndex = index
                expandableView.setCustomContentVisible(false, animated: false, layoutView: superview)
            } else {
                isCustomSelected = true
                segmentedControl.selectedSegmentIndex = options.count
                customPickerView.configure(value: selectedInterval, unit: .day)
                customInterval = selectedInterval
                expandableView.setCustomContentVisible(true, animated: false, layoutView: superview)
            }
        } else {
            segmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
            isCustomSelected = false
            expandableView.setCustomContentVisible(false, animated: false, layoutView: superview)
        }
        isProgrammaticSelectionUpdate = false
    }

    @objc private func handleValueChanged(_ sender: UISegmentedControl) {
        guard !isProgrammaticSelectionUpdate else { return }

        let selectedIndex = sender.selectedSegmentIndex
        guard selectedIndex != UISegmentedControl.noSegment else {
            expandableView.setCustomContentVisible(false, animated: true, layoutView: superview)
            isCustomSelected = false
            selectedInterval = nil
            return
        }

        if selectedIndex == options.count {
            customPickerView.configure(value: customInterval, unit: .day)
            expandableView.setCustomContentVisible(true, animated: true, layoutView: superview)
            isCustomSelected = true
            selectedInterval = customInterval
            onSelectionChanged?(selectedInterval)
            return
        }

        let value = options[selectedIndex]
        let wasCustomSelected = isCustomSelected
        if wasCustomSelected {
            expandableView.setCustomContentVisible(false, animated: true, layoutView: superview)
        }
        isCustomSelected = false

        if !wasCustomSelected, selectedInterval == value {
            selectedInterval = nil
        } else {
            selectedInterval = value
        }
        onSelectionChanged?(selectedInterval)
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
