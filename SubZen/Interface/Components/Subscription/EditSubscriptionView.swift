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
    }

    private let floatingSaveContainer = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial)).with {
        $0.clipsToBounds = true
        $0.layer.masksToBounds = true
    }

    private let floatingSeparator = UIView().with {
        $0.backgroundColor = UIColor.separator.withAlphaComponent(0.4)
    }

    private var reduceTransparencyActive = UIAccessibility.isReduceTransparencyEnabled

    private var traitChangeRegistrations: [any UITraitChangeRegistration] = []

    let saveButton = UIButton(type: .system).with {
        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .large
        configuration.title = "Save"
        configuration.baseForegroundColor = .tintColor
        configuration.baseBackgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.65)
        configuration.background.visualEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        configuration.background.strokeColor = UIColor.separator.withAlphaComponent(0.35)
        configuration.background.strokeWidth = 1
        configuration.background.cornerRadius = 24
        configuration.titleAlignment = .center
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 22, bottom: 16, trailing: 22)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var attributes = incoming
            attributes.font = .systemFont(ofSize: 17, weight: .semibold)
            return attributes
        }
        $0.configuration = configuration
        $0.layer.cornerRadius = 24
        $0.layer.cornerCurve = .continuous
        $0.layer.masksToBounds = false
        $0.layer.shadowColor = UIColor.black.withAlphaComponent(0.25).cgColor
        $0.layer.shadowOpacity = 0.22
        $0.layer.shadowRadius = 18
        $0.layer.shadowOffset = CGSize(width: 0, height: 8)
    }

    private let bottomSpacer = UIView().with {
        $0.isUserInteractionEnabled = false
    }

    lazy var nameStackView = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = 8
        $0.addArrangedSubview(nameLabel)
        $0.addArrangedSubview(nameTextField)
    }

    lazy var priceInputStackView = UIStackView().with {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.alignment = .fill
        $0.distribution = .fill
        $0.addArrangedSubview(priceTextField)
        $0.addArrangedSubview(currencyButton)
    }

    lazy var priceStackView = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = 8
        $0.addArrangedSubview(priceLabel)
        $0.addArrangedSubview(priceInputStackView)
    }

    lazy var cycleStackView = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = 8
        $0.addArrangedSubview(cycleLabel)
        $0.addArrangedSubview(cycleSegmentedControl)
    }

    lazy var dateStackView = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = 8
        $0.alignment = .leading
        $0.addArrangedSubview(dateLabel)
        $0.addArrangedSubview(datePicker)
    }

    lazy var mainStackView = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = 20
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
        textField.layer.cornerRadius = 18
        textField.layer.cornerCurve = .continuous
        textField.layer.masksToBounds = true
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.separator.withAlphaComponent(0.18).cgColor
        textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
        textField.tintColor = .systemBlue

        let paddingView = { (width: CGFloat) -> UIView in
            UIView(frame: CGRect(x: 0, y: 0, width: width, height: 0))
        }

        textField.leftView = paddingView(16)
        textField.leftViewMode = .always
        textField.rightView = paddingView(12)
        textField.rightViewMode = .always

        if let placeholder = textField.placeholder, !placeholder.isEmpty {
            textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [
                .foregroundColor: UIColor.placeholderText,
                .font: UIFont.systemFont(ofSize: 15, weight: .regular),
            ])
        }
    }

    private func updateMaterialAppearance() {
        let reduceTransparency = UIAccessibility.isReduceTransparencyEnabled
        reduceTransparencyActive = reduceTransparency

        if reduceTransparency {
            floatingSaveContainer.effect = nil
            floatingSaveContainer.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.95)
        } else {
            floatingSaveContainer.effect = UIBlurEffect(style: .systemUltraThinMaterial)
            floatingSaveContainer.backgroundColor = .clear
        }

        saveButton.setNeedsUpdateConfiguration()
        currencyButton.setNeedsUpdateConfiguration()
    }

    init() {
        super.init(frame: .zero)

        backgroundColor = .systemBackground
        scrollView.backgroundColor = .clear

        addSubview(scrollView)
        addSubview(floatingSaveContainer)

        scrollView.addSubview(mainStackView)
        floatingSaveContainer.contentView.addSubview(floatingSeparator)
        floatingSaveContainer.contentView.addSubview(saveButton)

        floatingSaveContainer.layer.cornerRadius = 28
        floatingSaveContainer.layer.cornerCurve = .continuous
        floatingSaveContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(floatingSaveContainer.snp.top)
        }

        mainStackView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(scrollView.frameLayoutGuide).inset(20)
            make.top.equalTo(scrollView.contentLayoutGuide).offset(28)
            make.bottom.equalTo(scrollView.contentLayoutGuide).inset(28)
        }

        floatingSaveContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.keyboardLayoutGuide.snp.top)
        }

        floatingSeparator.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        saveButton.snp.makeConstraints { make in
            make.top.equalTo(floatingSaveContainer.contentView.layoutMarginsGuide.snp.top)
            make.leading.equalTo(floatingSaveContainer.contentView.layoutMarginsGuide.snp.leading)
            make.trailing.equalTo(floatingSaveContainer.contentView.layoutMarginsGuide.snp.trailing)
            make.bottom.equalTo(floatingSaveContainer.contentView.layoutMarginsGuide.snp.bottom)
            make.height.greaterThanOrEqualTo(50)
        }

        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        currencyButton.addTarget(self, action: #selector(currencyTapped), for: .touchUpInside)

        saveButton.configurationUpdateHandler = { [weak self] button in
            guard var configuration = button.configuration else { return }
            let reduce = self?.reduceTransparencyActive ?? UIAccessibility.isReduceTransparencyEnabled
            let isHighlighted = button.isHighlighted
            let isEnabled = button.isEnabled
            let foreground = isEnabled ? UIColor.tintColor : UIColor.tertiaryLabel
            let baseFill = reduce ? UIColor.secondarySystemBackground : UIColor.secondarySystemBackground.withAlphaComponent(0.65)
            let highlightAdjust: CGFloat = isHighlighted ? 0.8 : 1

            configuration.baseForegroundColor = foreground
            configuration.baseBackgroundColor = baseFill.withAlphaComponent(reduce ? highlightAdjust : highlightAdjust * 0.9)
            configuration.background.strokeColor = UIColor.separator.withAlphaComponent(reduce ? 0.5 : (isHighlighted ? 0.4 : 0.35))
            configuration.background.visualEffect = reduce ? nil : UIBlurEffect(style: .systemUltraThinMaterial)

            button.layer.shadowOpacity = isEnabled ? (reduce ? 0.18 : (isHighlighted ? 0.16 : 0.22)) : 0

            button.configuration = configuration
        }

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

        priceTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        priceTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        [nameTextField, priceTextField].forEach { applyRoundedInputStyle(to: $0) }

        cycleSegmentedControl.selectedSegmentTintColor = UIColor.systemBlue.withAlphaComponent(0.2)
        cycleSegmentedControl.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.7)
        cycleSegmentedControl.layer.cornerRadius = 14
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

        bottomSpacer.snp.makeConstraints { make in
            make.height.equalTo(24)
        }

        floatingSaveContainer.contentView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 20, trailing: 20)

        NotificationCenter.default.addObserver(self, selector: #selector(handleReduceTransparencyStatusChanged), name: UIAccessibility.reduceTransparencyStatusDidChangeNotification, object: nil)

        traitChangeRegistrations.append(registerForTraitChanges([
            UITraitUserInterfaceStyle.self,
            UITraitAccessibilityContrast.self,
        ]) { (view: EditSubscriptionView, _) in
            view.updateMaterialAppearance()
        })

        updateMaterialAppearance()
    }

    var onSaveTapped: (() -> Void)?
    var onCurrencyTapped: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()

        let containerHeight = floatingSaveContainer.bounds.height
        let targetInset = containerHeight + 16

        if abs(scrollView.contentInset.bottom - targetInset) > 0.5 {
            scrollView.contentInset.bottom = targetInset
            scrollView.verticalScrollIndicatorInsets.bottom = targetInset
        }

        let shadowPath = UIBezierPath(roundedRect: saveButton.bounds, cornerRadius: saveButton.layer.cornerRadius).cgPath
        if saveButton.layer.shadowPath == nil || saveButton.layer.shadowPath != shadowPath {
            saveButton.layer.shadowPath = shadowPath
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
