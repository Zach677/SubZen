import SnapKit
import UIKit

final class ExpandableSegmentedControlView: UIView {
    private let stackView = UIStackView()

    let segmentedControl: UISegmentedControl
    let customContentView: UIView

    init(
        segmentedControl: UISegmentedControl,
        customContentView: UIView,
        cornerRadius: CGFloat,
        spacing: CGFloat = 8,
        isCustomContentInitiallyHidden: Bool = true
    ) {
        self.segmentedControl = segmentedControl
        self.customContentView = customContentView
        super.init(frame: .zero)

        EditSubscriptionSelectionStyler.configureSegmentedControl(
            segmentedControl,
            cornerRadius: cornerRadius
        )

        stackView.axis = .vertical
        stackView.spacing = spacing
        stackView.alignment = .fill
        stackView.distribution = .fill

        addSubview(stackView)
        stackView.addArrangedSubview(segmentedControl)
        stackView.addArrangedSubview(customContentView)

        if isCustomContentInitiallyHidden {
            customContentView.isHidden = true
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func updateAppearance(reduceTransparencyActive: Bool) {
        EditSubscriptionSelectionStyler.applySegmentedStyle(
            to: segmentedControl,
            reduceTransparencyActive: reduceTransparencyActive
        )

        if let pickerView = customContentView as? ValueUnitPickerView {
            pickerView.updateAppearance(reduceTransparencyActive: reduceTransparencyActive)
        }
    }

    func setCustomContentVisible(
        _ visible: Bool,
        animated: Bool,
        layoutView: UIView? = nil
    ) {
        let isCurrentlyHidden = customContentView.isHidden
        guard isCurrentlyHidden == visible else { return }

        let layoutTarget = layoutView ?? superview

        let animations = { [weak self, weak layoutTarget] in
            guard let self else { return }
            customContentView.isHidden = !visible
            customContentView.alpha = visible ? 1 : 0
            stackView.layoutIfNeeded()
            layoutTarget?.layoutIfNeeded()
        }

        if animated {
            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 0.1,
                options: [.curveEaseInOut, .beginFromCurrentState]
            ) {
                animations()
            }
        } else {
            animations()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}
