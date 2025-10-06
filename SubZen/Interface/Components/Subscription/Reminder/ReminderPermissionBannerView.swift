import SnapKit
import UIKit

final class ReminderPermissionBannerView: UIView {
    private enum Layout {
        static let cornerRadius: CGFloat = 14
        static let contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 14)
        static let spacing: CGFloat = 10
    }

    private let iconView = UIImageView().with {
        $0.image = UIImage(systemName: "exclamationmark.triangle.fill")
        $0.contentMode = .scaleAspectFit
        $0.tintColor = UIColor.systemOrange
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private let messageLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .label
        $0.numberOfLines = 0
    }

    private lazy var contentStack = UIStackView(arrangedSubviews: [iconView, messageLabel]).with {
        $0.axis = .horizontal
        $0.spacing = Layout.spacing
        $0.alignment = .top
    }

    var onTap: (() -> Void)?

    init() {
        super.init(frame: .zero)
        configureView()
        buildHierarchy()
        setupConstraints()
        setupInteraction()
        isHidden = true
    }

    private func configureView() {
        backgroundColor = UIColor.systemYellow.withAlphaComponent(0.2)
        layer.cornerRadius = Layout.cornerRadius
        layer.cornerCurve = .continuous
        isAccessibilityElement = true
        accessibilityTraits = [.button]
        accessibilityHint = String(localized: "Opens notification settings.")
    }

    private func buildHierarchy() {
        addSubview(contentStack)
    }

    private func setupConstraints() {
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.contentInsets)
        }
    }

    private func setupInteraction() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    func update(message: String?) {
        messageLabel.text = message
        accessibilityLabel = message
    }

    func updateAppearance(reduceTransparencyActive: Bool) {
        backgroundColor = reduceTransparencyActive ? .systemYellow : UIColor.systemYellow.withAlphaComponent(0.2)
    }

    @objc private func handleTap() {
        onTap?()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}
