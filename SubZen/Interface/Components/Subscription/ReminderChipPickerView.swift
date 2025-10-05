import SnapKit
import UIKit

final class ReminderChipPickerView: UIView {
    private let stackView = UIStackView()
    private let spacing: CGFloat
    private let chipContentInsets: NSDirectionalEdgeInsets
    private let chipCornerRadius: CGFloat

    private var buttons: [UIButton] = []
    private var options: [Int] = []
    private var reduceTransparencyActive = UIAccessibility.isReduceTransparencyEnabled

    var selectedInterval: Int? {
        didSet { updateSelectionAppearance() }
    }

    init(
        spacing: CGFloat,
        chipContentInsets: NSDirectionalEdgeInsets,
        chipCornerRadius: CGFloat
    ) {
        self.spacing = spacing
        self.chipContentInsets = chipContentInsets
        self.chipCornerRadius = chipCornerRadius
        super.init(frame: .zero)
        configureView()
        buildHierarchy()
        setupConstraints()
    }

    private func configureView() {
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillProportionally
        stackView.spacing = spacing
        stackView.isLayoutMarginsRelativeArrangement = true
    }

    private func buildHierarchy() {
        addSubview(stackView)
    }

    private func setupConstraints() {
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(options: [Int]) {
        guard self.options != options else { return }
        self.options = options
        rebuildButtons()
    }

    func updateAppearance(reduceTransparencyActive newValue: Bool) {
        reduceTransparencyActive = newValue
        updateSelectionAppearance()
    }

    private func rebuildButtons() {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        buttons.removeAll()

        for option in options {
            let button = makeButton(for: option)
            stackView.addArrangedSubview(button)
            buttons.append(button)
        }

        let spacer = UIView()
        spacer.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        stackView.addArrangedSubview(spacer)

        updateSelectionAppearance()
    }

    private func makeButton(for days: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = days
        button.accessibilityLabel = "\(days)-day reminder"
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        button.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
        return button
    }

    private func updateSelectionAppearance() {
        for button in buttons {
            let isSelected = button.tag == selectedInterval
            button.configuration = EditSubscriptionButtonStyler.reminderChipConfiguration(
                for: button.tag,
                isSelected: isSelected,
                reduceTransparencyActive: reduceTransparencyActive,
                contentInsets: chipContentInsets,
                cornerRadius: chipCornerRadius
            )
            if isSelected {
                button.accessibilityTraits.insert(.selected)
            } else {
                button.accessibilityTraits.remove(.selected)
            }
        }
    }

    @objc private func handleTap(_ sender: UIButton) {
        if selectedInterval == sender.tag {
            selectedInterval = nil
        } else {
            selectedInterval = sender.tag
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}
