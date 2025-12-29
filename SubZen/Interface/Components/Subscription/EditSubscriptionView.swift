//
//  EditSubscriptionView.swift
//  SubZen
//
//  Created by Star on 2025/8/14.
//

import SnapKit
import UIKit

@MainActor
final class EditSubscriptionView: UIView {
    private enum Layout {
        static let groupSpacing: CGFloat = 8
        static let stackSpacing: CGFloat = 20
        static let textFieldCornerRadius: CGFloat = 18
        static let textFieldHeight: CGFloat = 52
        static let textFieldLeftPadding: CGFloat = 16
        static let textFieldRightPadding: CGFloat = 12
        static let currencyButtonCornerRadius: CGFloat = 18
        static let currencyButtonContentInsets = NSDirectionalEdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 14)
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

    private let reminderOptions = [1, 3, 7]

    let nameLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.text = String(localized: "Subscription Name")
    }

    let nameTextField = UITextField().with {
        $0.borderStyle = .none
        $0.placeholder = String(localized: "Enter subscription name")
        $0.clearButtonMode = .whileEditing
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
    }

    let priceLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.text = String(localized: "Price")
    }

    let priceTextField = UITextField().with {
        $0.borderStyle = .none
        $0.placeholder = String(localized: "Enter price")
        $0.keyboardType = .decimalPad
        $0.clearButtonMode = .whileEditing
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
    }

    let currencyButton = UIButton(type: .system).with {
        var configuration = EditSubscriptionButtonStyler.makeCurrencyButtonBaseConfiguration(
            contentInsets: Layout.currencyButtonContentInsets
        )
        configuration.title = String(localized: "Select")
        $0.configuration = configuration
        $0.tintColor = .secondaryLabel
        $0.layer.cornerRadius = Layout.currencyButtonCornerRadius
        $0.layer.cornerCurve = .continuous
        $0.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.6)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        $0.setContentHuggingPriority(.required, for: .horizontal)
    }

    let cycleLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.text = String(localized: "Cycle")
    }

    let cycleSegmentedControl = UISegmentedControl(
        items: BillingCycle.presetCases.map(\.shortLocalizedName) + [String(localized: "Custom")]
    )

    let dateLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.text = String(localized: "Last Billing Date")
    }

    let reminderLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.text = String(localized: "Remind Me")
    }

    let datePicker = UIDatePicker().with {
        $0.datePickerMode = .date
        $0.preferredDatePickerStyle = .compact
        $0.maximumDate = Date()
        $0.isHidden = true
    }

    let dateValueButton = UIButton(type: .system).with {
        var configuration = EditSubscriptionButtonStyler.makeCurrencyButtonBaseConfiguration(
            contentInsets: Layout.currencyButtonContentInsets
        )
        configuration.image = UIImage(systemName: "calendar")
        $0.configuration = configuration
        $0.tintColor = .systemBlue
        $0.layer.cornerRadius = Layout.currencyButtonCornerRadius
        $0.layer.cornerCurve = .continuous
        $0.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.6)
        $0.contentHorizontalAlignment = .fill
    }

    let nextBillingHintLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
    }

    private let scrollView = UIScrollView().with {
        $0.alwaysBounceVertical = true
        $0.keyboardDismissMode = .onDrag
        $0.showsVerticalScrollIndicator = false
        $0.backgroundColor = .clear
    }

    private let floatingSaveBar = FloatingSaveBarView(
        containerLayoutMargins: Layout.saveContentMargins,
        buttonContentInsets: Layout.saveButtonInsets,
        cornerRadius: Layout.saveCornerRadius,
        minimumButtonHeight: Layout.saveButtonMinHeight
    )

    private let reminderPickerView = ReminderChipPickerView(
        cornerRadius: Layout.segmentedCornerRadius
    )

    let customCyclePickerView = CustomCyclePickerView()

    private let bottomSpacer = UIView().with {
        $0.isUserInteractionEnabled = false
    }

    private lazy var priceInputStackView = UIStackView().with {
        $0.axis = .horizontal
        $0.spacing = Layout.groupSpacing
        $0.alignment = .fill
        $0.distribution = .fill
        $0.addArrangedSubview(priceTextField)
        $0.addArrangedSubview(currencyButton)
    }

    private let reminderBannerView = ReminderPermissionBannerView()

    private lazy var reminderContentStack = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = Layout.groupSpacing
        $0.alignment = .fill
        $0.addArrangedSubview(reminderPickerView)
        $0.addArrangedSubview(reminderBannerView)
    }

    private lazy var cycleContentStack = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = Layout.groupSpacing
        $0.alignment = .fill
        $0.addArrangedSubview(cycleSegmentedControl)
        $0.addArrangedSubview(customCyclePickerView)
    }

    private lazy var dateContentStack = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = 8
        $0.alignment = .fill
        $0.addArrangedSubview(dateValueButton)
        $0.addArrangedSubview(nextBillingHintLabel)
    }

    private lazy var nameSectionView = makeVerticalFormSection(label: nameLabel, content: nameTextField)
    private lazy var priceSectionView = makeVerticalFormSection(label: priceLabel, content: priceInputStackView)
    private lazy var cycleSectionView = makeVerticalFormSection(label: cycleLabel, content: cycleContentStack)
    private lazy var dateSectionView = makeVerticalFormSection(label: dateLabel, content: dateContentStack)
    private lazy var reminderSectionView = makeVerticalFormSection(label: reminderLabel, content: reminderContentStack)

    private lazy var mainStackView = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = Layout.stackSpacing
        $0.alignment = .fill
        $0.distribution = .fill
        $0.addArrangedSubview(nameSectionView)
        $0.addArrangedSubview(priceSectionView)
        $0.addArrangedSubview(cycleSectionView)
        $0.addArrangedSubview(dateSectionView)
        $0.addArrangedSubview(reminderSectionView)
        $0.addArrangedSubview(bottomSpacer)
    }

    private var traitChangeRegistrations: [any UITraitChangeRegistration] = []

    var onSaveTapped: (() -> Void)?
    var onCurrencyTapped: (() -> Void)?
    var onReminderSelectionChanged: ((Int?) -> Void)?
    var onReminderBannerTapped: (() -> Void)?
    var onCycleSegmentChanged: ((Int) -> Void)?
    var onCustomCycleChanged: ((Int, CycleUnit) -> Void)?
    var onDateTapped: (() -> Void)?

    init() {
        super.init(frame: .zero)

        configureView()
        buildHierarchy()
        setupConstraints()
        setupInteractions()
        registerObservers()
        reminderPickerView.configure(options: reminderOptions)
        reminderPickerView.onSelectionChanged = { [weak self] selected in
            self?.onReminderSelectionChanged?(selected)
        }
        reminderBannerView.onTap = { [weak self] in
            self?.onReminderBannerTapped?()
        }
        customCyclePickerView.onSelectionChanged = { [weak self] value, unit in
            self?.onCustomCycleChanged?(value, unit)
        }
        customCyclePickerView.isHidden = true
        updateMaterialAppearance()
    }

    private func configureView() {
        backgroundColor = .systemBackground

        priceTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        priceTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        [nameTextField, priceTextField].forEach { applyRoundedInputStyle(to: $0) }
        EditSubscriptionSelectionStyler.configureSegmentedControl(
            cycleSegmentedControl,
            cornerRadius: Layout.segmentedCornerRadius
        )
    }

    private func buildHierarchy() {
        addSubview(scrollView)
        addSubview(floatingSaveBar)

        scrollView.addSubview(mainStackView)
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(floatingSaveBar.snp.top)
        }

        mainStackView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(scrollView.frameLayoutGuide).inset(Layout.scrollHorizontalInset)
            make.top.equalTo(scrollView.contentLayoutGuide).offset(Layout.scrollVerticalInset)
            make.bottom.equalTo(scrollView.contentLayoutGuide).inset(Layout.scrollVerticalInset)
        }

        floatingSaveBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(keyboardLayoutGuide.snp.top)
        }

        bottomSpacer.snp.makeConstraints { make in
            make.height.equalTo(Layout.bottomSpacerHeight)
        }
    }

    private func setupInteractions() {
        floatingSaveBar.saveButton.addTarget(
            self,
            action: #selector(saveTapped),
            for: UIControl.Event.touchUpInside
        )
        currencyButton.addTarget(
            self,
            action: #selector(currencyTapped),
            for: UIControl.Event.touchUpInside
        )
        cycleSegmentedControl.addTarget(
            self,
            action: #selector(cycleSegmentChanged(_:)),
            for: UIControl.Event.valueChanged
        )
        dateValueButton.addTarget(
            self,
            action: #selector(dateTapped),
            for: UIControl.Event.touchUpInside
        )

        if #available(iOS 26.0, *) {
            let interaction = UIScrollEdgeElementContainerInteraction()
            interaction.scrollView = scrollView
            interaction.edge = .bottom
            floatingSaveBar.addInteraction(interaction)
        }
    }

    private func registerObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleReduceTransparencyStatusChanged),
            name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil
        )

        traitChangeRegistrations.append(
            registerForTraitChanges([
                UITraitUserInterfaceStyle.self,
                UITraitAccessibilityContrast.self,
            ]) { (view: EditSubscriptionView, _) in
                view.updateMaterialAppearance()
            }
        )
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
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [
                    .foregroundColor: UIColor.placeholderText,
                    .font: UIFont.systemFont(ofSize: 15, weight: .regular),
                ]
            )
        }
    }

    private func updateMaterialAppearance() {
        let reduceTransparency = UIAccessibility.isReduceTransparencyEnabled
        let saveTitle = String(localized: "Save")
        floatingSaveBar.updateAppearance(
            reduceTransparencyActive: reduceTransparency,
            title: saveTitle
        )

        let fallbackCurrencyTitle = String(localized: "Select")
        if currencyButton.configuration == nil {
            var configuration = EditSubscriptionButtonStyler.makeCurrencyButtonBaseConfiguration(
                contentInsets: Layout.currencyButtonContentInsets
            )
            configuration.title = fallbackCurrencyTitle
            currencyButton.configuration = configuration
        }

        EditSubscriptionButtonStyler.applyCurrencyButtonStyle(
            to: currencyButton,
            reduceTransparencyActive: reduceTransparency,
            contentInsets: Layout.currencyButtonContentInsets
        )

        if currencyButton.currentTitle?.isEmpty != false {
            currencyButton.setTitle(fallbackCurrencyTitle, for: UIControl.State.normal)
        }
        EditSubscriptionSelectionStyler.applySegmentedStyle(
            to: cycleSegmentedControl,
            reduceTransparencyActive: reduceTransparency
        )
        reminderPickerView.updateAppearance(reduceTransparencyActive: reduceTransparency)
        reminderBannerView.updateAppearance(reduceTransparencyActive: reduceTransparency)
        customCyclePickerView.updateAppearance(reduceTransparencyActive: reduceTransparency)

        EditSubscriptionButtonStyler.applyCurrencyButtonStyle(
            to: dateValueButton,
            reduceTransparencyActive: reduceTransparency,
            contentInsets: Layout.currencyButtonContentInsets
        )
        dateValueButton.configuration?.image = UIImage(systemName: "calendar")
        dateValueButton.tintColor = .systemBlue
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let containerHeight = floatingSaveBar.bounds.height
        let targetInset = containerHeight + Layout.additionalBottomInset

        if abs(scrollView.contentInset.bottom - targetInset) > 0.5 {
            scrollView.contentInset.bottom = targetInset
            scrollView.verticalScrollIndicatorInsets.bottom = targetInset
        }
    }

    @objc private func handleReduceTransparencyStatusChanged() {
        updateMaterialAppearance()
    }

    @objc private func saveTapped() {
        onSaveTapped?()
    }

    @objc private func currencyTapped() {
        onCurrencyTapped?()
    }

    @objc private func cycleSegmentChanged(_ sender: UISegmentedControl) {
        onCycleSegmentChanged?(sender.selectedSegmentIndex)
    }

    @objc private func dateTapped() {
        onDateTapped?()
    }

    func setReminderIntervals(_ intervals: [Int]) {
        reminderPickerView.selectedInterval = intervals.first
    }

    func setCustomPickerVisible(_ visible: Bool, animated: Bool) {
        let isCurrentlyHidden = customCyclePickerView.isHidden
        guard isCurrentlyHidden == visible else { return }

        let animations = { [weak self] in
            self?.customCyclePickerView.isHidden = !visible
            self?.customCyclePickerView.alpha = visible ? 1 : 0
            self?.mainStackView.layoutIfNeeded()
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

    func selectedReminderIntervals() -> [Int] {
        guard let interval = reminderPickerView.selectedInterval else { return [] }
        return [interval]
    }

    func updateSelectedCurrencyDisplay(with currency: Currency) {
        let code = currency.code
        let symbol = CurrencyList.displaySymbol(for: code)

        // Avoid redundant display when symbol already contains the currency code prefix
        // e.g., for CNY with symbol "CN¥", display "Yuan Renminbi ¥ CNY" instead of "Yuan Renminbi CN¥ CNY"
        let displaySymbol: String = if symbol.hasPrefix(code) || symbol.hasPrefix(String(code.prefix(2))) {
            // Symbol contains code prefix (e.g., "CN¥"), clean it to just the symbol part
            symbol.trimmingCharacters(in: CharacterSet.letters)
        } else {
            // Normal case: code and symbol are distinct
            symbol
        }

        let title = String(localized: "\(currency.name) \(displaySymbol) \(code)")
        currencyButton.setTitle(title, for: UIControl.State.normal)
        if var configuration = currencyButton.configuration {
            configuration.title = title
            currencyButton.configuration = configuration
        }
        currencyButton.accessibilityLabel = String(localized: "Selected currency: \(currency.name) \(currency.code)")
    }

    func updateReminderPermissionBanner(isVisible: Bool, message: String?) {
        reminderBannerView.update(message: message)
        reminderBannerView.isHidden = !isVisible
    }

    func updateLastBillingDisplay(dateString: String) {
        dateValueButton.setTitle(dateString, for: .normal)
        if var configuration = dateValueButton.configuration {
            configuration.title = dateString
            dateValueButton.configuration = configuration
        }
    }

    func updateNextBillingHint(hint: String, highlightRange: NSRange?) {
        let attributedString = NSMutableAttributedString(string: hint)
        if let range = highlightRange {
            attributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: range)
            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 13, weight: .semibold), range: range)
        }
        nextBillingHintLabel.attributedText = attributedString
    }

    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil
        )
        traitChangeRegistrations.removeAll()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    private func makeVerticalFormSection(
        label: UILabel,
        content: UIView,
        alignment: UIStackView.Alignment = .fill
    ) -> UIStackView {
        UIStackView().with {
            $0.axis = .vertical
            $0.spacing = Layout.groupSpacing
            $0.alignment = alignment
            $0.addArrangedSubview(label)
            $0.addArrangedSubview(content)
        }
    }
}
