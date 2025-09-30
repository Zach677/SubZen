//
//  EditSubscriptionView.swift
//  SubZen
//
//  Created by Star on 2025/8/14.
//

import SnapKit
import UIKit

@MainActor
class EditSubscriptionView: UIView {
    private enum Layout {
        static let groupSpacing: CGFloat = 8
        static let stackSpacing: CGFloat = 20
        static let textFieldCornerRadius: CGFloat = 18
        static let textFieldHeight: CGFloat = 52
        static let textFieldLeftPadding: CGFloat = 16
        static let textFieldRightPadding: CGFloat = 12
        static let saveCornerRadius: CGFloat = 28
        static let saveContentMargins = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 20, trailing: 20)
        static let saveButtonInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        static let saveButtonMinHeight: CGFloat = 50
        static let scrollHorizontalInset: CGFloat = 20
        static let scrollVerticalInset: CGFloat = 28
        static let bottomSpacerHeight: CGFloat = 24
        static let additionalBottomInset: CGFloat = 16
        static let segmentedCornerRadius: CGFloat = 14
    }

    let nameLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.text = "Subscription Name"
    }

    let nameTextField = UITextField().with {
        $0.borderStyle = .none
        $0.placeholder = "Enter subscription name"
        $0.clearButtonMode = .whileEditing
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
    }

    let priceLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.text = "Price"
    }

    let priceTextField = UITextField().with {
        $0.borderStyle = .none
        $0.placeholder = "Enter price"
        $0.keyboardType = .decimalPad
        $0.clearButtonMode = .whileEditing
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
    }

    let currencyButton = UIButton(type: .system).with {
        var configuration = UIButton.Configuration.tinted()
        configuration.title = "Select"
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 14)
        configuration.titleAlignment = .leading
        configuration.baseForegroundColor = .label
        configuration.baseBackgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.95)
        configuration.background.strokeColor = UIColor.separator.withAlphaComponent(0.25)
        configuration.background.strokeWidth = 1
        configuration.background.visualEffect = UIBlurEffect(style: .systemChromeMaterial)
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 8
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        configuration.image = UIImage(systemName: "chevron.down")
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var attributes = incoming
            attributes.font = .systemFont(ofSize: 15, weight: .medium)
            return attributes
        }
        $0.configuration = configuration
        $0.tintColor = .secondaryLabel
        $0.layer.cornerRadius = 18
        $0.layer.cornerCurve = .continuous
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
        $0.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.6)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        $0.setContentHuggingPriority(.required, for: .horizontal)
    }

    let cycleLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.text = "Cycle"
    }

    let cycleSegmentedControl = UISegmentedControl(items: BillingCycle.allCases.map(\.rawValue))

    let dateLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.text = "Last Billing Date"
    }

    let datePicker = UIDatePicker().with {
        $0.datePickerMode = .date
        $0.preferredDatePickerStyle = .compact
        $0.maximumDate = Date()
    }

    private let scrollView = UIScrollView().with {
        $0.alwaysBounceVertical = true
        $0.keyboardDismissMode = .interactive
        $0.showsVerticalScrollIndicator = false
        $0.backgroundColor = .clear
    }

    private let floatingSaveContainer = UIView().with {
        $0.clipsToBounds = false
        $0.layer.masksToBounds = false
    }

    private let floatingSaveContentView = UIView().with {
        $0.clipsToBounds = true
        $0.layer.cornerRadius = Layout.saveCornerRadius
        $0.layer.cornerCurve = .continuous
        $0.layer.maskedCorners = [
            .layerMinXMinYCorner, .layerMaxXMinYCorner,
        ]
        $0.directionalLayoutMargins = Layout.saveContentMargins
    }

    private let floatingSaveBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial)).with {
        $0.clipsToBounds = true
        $0.layer.cornerRadius = Layout.saveCornerRadius
        $0.layer.cornerCurve = .continuous
        $0.layer.maskedCorners = [
            .layerMinXMinYCorner, .layerMaxXMinYCorner,
        ]
        $0.isUserInteractionEnabled = false
        $0.isHidden = true
    }

    private var reduceTransparencyActive = UIAccessibility.isReduceTransparencyEnabled

    private var traitChangeRegistrations: [any UITraitChangeRegistration] = []

    let saveButton = UIButton(type: .system).with {
        $0.tintColor = .accent
    }

    private let bottomSpacer = UIView().with {
        $0.isUserInteractionEnabled = false
    }

    lazy var nameStackView = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = Layout.groupSpacing
        $0.addArrangedSubview(nameLabel)
        $0.addArrangedSubview(nameTextField)
    }

    lazy var priceInputStackView = UIStackView().with {
        $0.axis = .horizontal
        $0.spacing = Layout.groupSpacing
        $0.alignment = .fill
        $0.distribution = .fill
        $0.addArrangedSubview(priceTextField)
        $0.addArrangedSubview(currencyButton)
    }

    lazy var priceStackView = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = Layout.groupSpacing
        $0.addArrangedSubview(priceLabel)
        $0.addArrangedSubview(priceInputStackView)
    }

    lazy var cycleStackView = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = Layout.groupSpacing
        $0.addArrangedSubview(cycleLabel)
        $0.addArrangedSubview(cycleSegmentedControl)
    }

    lazy var dateStackView = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = Layout.groupSpacing
        $0.alignment = .leading
        $0.addArrangedSubview(dateLabel)
        $0.addArrangedSubview(datePicker)
    }

    lazy var mainStackView = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = Layout.stackSpacing
        $0.alignment = .fill
        $0.distribution = .fill
        $0.addArrangedSubview(nameStackView)
        $0.addArrangedSubview(priceStackView)
        $0.addArrangedSubview(cycleStackView)
        $0.addArrangedSubview(dateStackView)
        $0.addArrangedSubview(bottomSpacer)
    }

    private func applyRoundedInputStyle(to textField: UITextField) {
        textField.borderStyle = .none
        textField.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.96)
        textField.layer.cornerRadius = Layout.textFieldCornerRadius
        textField.layer.cornerCurve = .continuous
        textField.layer.masksToBounds = true
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.separator.withAlphaComponent(0.18).cgColor
        textField.heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.textFieldHeight).isActive = true
        textField.tintColor = .systemBlue

        let paddingView = { (width: CGFloat) -> UIView in
            UIView(frame: CGRect(x: 0, y: 0, width: width, height: 0))
        }

        textField.leftView = paddingView(Layout.textFieldLeftPadding)
        textField.leftViewMode = .always
        textField.rightView = paddingView(Layout.textFieldRightPadding)
        textField.rightViewMode = .always

        if let placeholder = textField.placeholder, !placeholder.isEmpty {
            textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [
                .foregroundColor: UIColor.placeholderText,
                .font: UIFont.systemFont(ofSize: 15, weight: .regular),
            ])
        }
    }

    private func configureSaveButton() {
        if #available(iOS 26.0, *), !reduceTransparencyActive {
            var configuration = UIButton.Configuration.prominentGlass()
            configuration.title = "Save"
            configuration.buttonSize = .large
            configuration.contentInsets = Layout.saveButtonInsets
            configuration.baseForegroundColor = .label
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var attributes = incoming
                attributes.font = .systemFont(ofSize: 17, weight: .semibold)
                return attributes
            }
            saveButton.configuration = configuration
            saveButton.tintColor = .accent.withAlphaComponent(0.7)
        } else {
            var configuration = UIButton.Configuration.borderedProminent()
            configuration.title = "Save"
            configuration.buttonSize = .large
            configuration.contentInsets = Layout.saveButtonInsets
            configuration.baseBackgroundColor = .systemBlue
            configuration.baseForegroundColor = .white
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var attributes = incoming
                attributes.font = .systemFont(ofSize: 17, weight: .semibold)
                return attributes
            }
            saveButton.configuration = configuration
            saveButton.tintColor = .accent.withAlphaComponent(0.7)
        }
    }

    private func updateMaterialAppearance() {
        let reduceTransparency = UIAccessibility.isReduceTransparencyEnabled
        reduceTransparencyActive = reduceTransparency

        if reduceTransparency {
            let fallbackColor = UIColor.secondarySystemBackground.withAlphaComponent(0.95)
            floatingSaveBackgroundView.isHidden = false
            floatingSaveBackgroundView.effect = nil
            floatingSaveBackgroundView.backgroundColor = fallbackColor
            floatingSaveBackgroundView.contentView.backgroundColor = fallbackColor
            floatingSaveContentView.backgroundColor = fallbackColor
        } else {
            floatingSaveBackgroundView.isHidden = true
            floatingSaveBackgroundView.effect = nil
            floatingSaveBackgroundView.backgroundColor = .clear
            floatingSaveBackgroundView.contentView.backgroundColor = .clear
            floatingSaveContentView.backgroundColor = .clear
        }
        configureSaveButton()
        currencyButton.setNeedsUpdateConfiguration()
    }

    init() {
        super.init(frame: .zero)

        configureView()
        buildHierarchy()
        setupConstraints()
        setupInteractions()
        registerObservers()
        updateMaterialAppearance()
    }

    private func configureView() {
        backgroundColor = .systemBackground

        priceTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        priceTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        [nameTextField, priceTextField].forEach { applyRoundedInputStyle(to: $0) }

        cycleSegmentedControl.selectedSegmentTintColor = UIColor.accent.withAlphaComponent(0.22)
        cycleSegmentedControl.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.7)
        cycleSegmentedControl.layer.cornerRadius = Layout.segmentedCornerRadius
        cycleSegmentedControl.layer.cornerCurve = .continuous
        cycleSegmentedControl.layer.masksToBounds = true
        cycleSegmentedControl.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 15, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel,
        ], for: .normal)
        cycleSegmentedControl.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
            .foregroundColor: UIColor.label,
        ], for: .selected)
    }

    private func buildHierarchy() {
        addSubview(scrollView)
        addSubview(floatingSaveContainer)

        scrollView.addSubview(mainStackView)
        floatingSaveContainer.addSubview(floatingSaveContentView)
        floatingSaveContentView.addSubview(floatingSaveBackgroundView)
        floatingSaveContentView.addSubview(saveButton)
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(floatingSaveContainer.snp.top)
        }

        mainStackView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(scrollView.frameLayoutGuide).inset(Layout.scrollHorizontalInset)
            make.top.equalTo(scrollView.contentLayoutGuide).offset(Layout.scrollVerticalInset)
            make.bottom.equalTo(scrollView.contentLayoutGuide).inset(Layout.scrollVerticalInset)
        }

        floatingSaveContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.keyboardLayoutGuide.snp.top)
        }

        floatingSaveContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        floatingSaveBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        saveButton.snp.makeConstraints { make in
            make.top.equalTo(floatingSaveContentView.layoutMarginsGuide.snp.top)
            make.leading.equalTo(floatingSaveContentView.layoutMarginsGuide.snp.leading)
            make.trailing.equalTo(floatingSaveContentView.layoutMarginsGuide.snp.trailing)
            make.bottom.equalTo(floatingSaveContentView.layoutMarginsGuide.snp.bottom)
            make.height.greaterThanOrEqualTo(Layout.saveButtonMinHeight)
        }

        bottomSpacer.snp.makeConstraints { make in
            make.height.equalTo(Layout.bottomSpacerHeight)
        }
    }

    private func setupInteractions() {
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        currencyButton.addTarget(self, action: #selector(currencyTapped), for: .touchUpInside)

        currencyButton.configurationUpdateHandler = { [weak self] button in
            guard var configuration = button.configuration else { return }
            let reduce = self?.reduceTransparencyActive ?? UIAccessibility.isReduceTransparencyEnabled

            configuration.baseForegroundColor = .label
            configuration.background.strokeColor = UIColor.separator.withAlphaComponent(reduce ? 0.5 : 0.25)

            if reduce {
                configuration.baseBackgroundColor = UIColor.secondarySystemBackground
                configuration.background.visualEffect = nil
            } else {
                configuration.baseBackgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.95)
                configuration.background.visualEffect = UIBlurEffect(style: .systemChromeMaterial)
            }

            button.configuration = configuration
        }

        if #available(iOS 26.0, *) {
            let interaction = UIScrollEdgeElementContainerInteraction()
            interaction.scrollView = scrollView
            interaction.edge = .bottom
            floatingSaveContainer.addInteraction(interaction)
        }
    }

    private func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleReduceTransparencyStatusChanged), name: UIAccessibility.reduceTransparencyStatusDidChangeNotification, object: nil)

        traitChangeRegistrations.append(registerForTraitChanges([
            UITraitUserInterfaceStyle.self,
            UITraitAccessibilityContrast.self,
        ]) { (view: EditSubscriptionView, _) in
            view.updateMaterialAppearance()
        })
    }

    var onSaveTapped: (() -> Void)?
    var onCurrencyTapped: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()

        let containerHeight = floatingSaveContainer.bounds.height
        let targetInset = containerHeight + Layout.additionalBottomInset

        if abs(scrollView.contentInset.bottom - targetInset) > 0.5 {
            scrollView.contentInset.bottom = targetInset
            scrollView.verticalScrollIndicatorInsets.bottom = targetInset
        }
    }

    @objc private func handleReduceTransparencyStatusChanged() {
        updateMaterialAppearance()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIAccessibility.reduceTransparencyStatusDidChangeNotification, object: nil)
        traitChangeRegistrations.removeAll()
    }

    @objc private func saveTapped() {
        onSaveTapped?()
    }

    @objc private func currencyTapped() {
        onCurrencyTapped?()
    }

    func updateSelectedCurrencyDisplay(with currency: Currency) {
        let code = currency.code
        let symbol = CurrencyList.displaySymbol(for: code)
        let title = "\(currency.name) \(symbol) \(code)"
        currencyButton.setTitle(title, for: .normal)
        currencyButton.accessibilityLabel = "Selected currency: \(currency.name) \(code)"
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}
