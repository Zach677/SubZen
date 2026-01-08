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
        static let iconSize: CGFloat = textFieldHeight
    }

    private let reminderOptions = [1, 3, 7]

    let nameLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.text = String(localized: "Subscription Name")
    }

    private let iconControl = UIButton(type: .system).with {
        $0.isAccessibilityElement = true
        $0.accessibilityTraits = .button
        $0.contentHorizontalAlignment = .fill
        $0.contentVerticalAlignment = .fill
    }

    private let iconImageView = UIImageView().with {
        $0.contentMode = .scaleAspectFill
        $0.image = UIImage.subZenAppIconPlaceholder
        $0.clipsToBounds = true
    }

    private let iconActivityIndicator = UIActivityIndicatorView(style: .medium).with {
        $0.hidesWhenStopped = true
        $0.stopAnimating()
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

    let billingTypeLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.text = String(localized: "Billing Type")
    }

    let billingTypeSegmentedControl = UISegmentedControl(
        items: [
            String(localized: "Subscription"),
            String(localized: "Lifetime"),
        ]
    )

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

    let trialLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.text = String(localized: "Free Trial")
    }

    let trialSegmentedControl = UISegmentedControl(
        items: [
            String(localized: "None"),
            String(localized: "7 days"),
            String(localized: "14 days"),
            String(localized: "Custom"),
        ]
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

    let trialHintLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
        $0.isHidden = true
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
    let customTrialPickerView = CustomTrialPickerView()

    private lazy var cyclePickerView = ExpandableSegmentedControlView(
        segmentedControl: cycleSegmentedControl,
        customContentView: customCyclePickerView,
        cornerRadius: Layout.segmentedCornerRadius,
        spacing: Layout.groupSpacing
    )

    private lazy var trialPickerView = ExpandableSegmentedControlView(
        segmentedControl: trialSegmentedControl,
        customContentView: customTrialPickerView,
        cornerRadius: Layout.segmentedCornerRadius,
        spacing: Layout.groupSpacing
    )

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

    private lazy var trialContentStack = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = Layout.groupSpacing
        $0.alignment = .fill
        $0.addArrangedSubview(trialPickerView)
        $0.addArrangedSubview(trialHintLabel)
    }

    private lazy var dateContentStack = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = 8
        $0.alignment = .fill
        $0.addArrangedSubview(dateValueButton)
        $0.addArrangedSubview(nextBillingHintLabel)
    }

    private lazy var nameContentStack = UIStackView().with {
        $0.axis = .horizontal
        $0.spacing = Layout.groupSpacing
        $0.alignment = .fill
        $0.distribution = .fill
        $0.addArrangedSubview(iconControl)
        $0.addArrangedSubview(nameTextField)
    }

    private lazy var nameSectionView = makeVerticalFormSection(label: nameLabel, content: nameContentStack)
    private lazy var priceSectionView = makeVerticalFormSection(label: priceLabel, content: priceInputStackView)
    private lazy var billingTypeSectionView = makeVerticalFormSection(label: billingTypeLabel, content: billingTypeSegmentedControl)
    private lazy var cycleSectionView = makeVerticalFormSection(label: cycleLabel, content: cyclePickerView)
    private lazy var trialSectionView = makeVerticalFormSection(label: trialLabel, content: trialContentStack)
    private lazy var dateSectionView = makeVerticalFormSection(label: dateLabel, content: dateContentStack)
    private lazy var reminderSectionView = makeVerticalFormSection(label: reminderLabel, content: reminderContentStack)

    private lazy var mainStackView = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = Layout.stackSpacing
        $0.alignment = .fill
        $0.distribution = .fill
        $0.addArrangedSubview(nameSectionView)
        $0.addArrangedSubview(priceSectionView)
        $0.addArrangedSubview(billingTypeSectionView)
        $0.addArrangedSubview(cycleSectionView)
        $0.addArrangedSubview(trialSectionView)
        $0.addArrangedSubview(dateSectionView)
        $0.addArrangedSubview(reminderSectionView)
        $0.addArrangedSubview(bottomSpacer)
    }

    private var traitChangeRegistrations: [any UITraitChangeRegistration] = []

    var onSaveTapped: (() -> Void)?
    var onCurrencyTapped: (() -> Void)?
    var onReminderSelectionChanged: ((Int?) -> Void)?
    var onReminderBannerTapped: (() -> Void)?
    var onBillingTypeSegmentChanged: ((Int) -> Void)?
    var onCycleSegmentChanged: ((Int) -> Void)?
    var onCustomCycleChanged: ((Int, CycleUnit) -> Void)?
    var onTrialSegmentChanged: ((Int) -> Void)?
    var onCustomTrialChanged: ((Int, CycleUnit) -> Void)?
    var onDateTapped: (() -> Void)?

    init() {
        super.init(frame: .zero)

        configureView()
        buildHierarchy()
        setupConstraints()
        setupInteractions()
        registerObservers()

        iconControl.addSubview(iconImageView)
        iconControl.addSubview(iconActivityIndicator)

        iconControl.snp.makeConstraints { make in
            make.size.equalTo(Layout.iconSize)
        }

        iconImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(6)
        }

        iconActivityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

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
        customTrialPickerView.onSelectionChanged = { [weak self] value, unit in
            self?.onCustomTrialChanged?(value, unit)
        }
        updateMaterialAppearance()
    }

    private func configureView() {
        backgroundColor = .systemBackground

        priceTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        priceTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        [nameTextField, priceTextField].forEach { applyRoundedInputStyle(to: $0) }
        applyRoundedIconStyle(to: iconControl)

        updateIconPreview(image: nil)

        billingTypeSegmentedControl.selectedSegmentIndex = 0
        EditSubscriptionSelectionStyler.configureSegmentedControl(
            billingTypeSegmentedControl,
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
        billingTypeSegmentedControl.addTarget(
            self,
            action: #selector(billingTypeSegmentChanged(_:)),
            for: UIControl.Event.valueChanged
        )
        cycleSegmentedControl.addTarget(
            self,
            action: #selector(cycleSegmentChanged(_:)),
            for: UIControl.Event.valueChanged
        )
        trialSegmentedControl.addTarget(
            self,
            action: #selector(trialSegmentChanged(_:)),
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

    private func applyRoundedIconStyle(to view: UIView) {
        view.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.96)
        view.layer.cornerRadius = Layout.textFieldCornerRadius
        view.layer.cornerCurve = .continuous
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.separator.withAlphaComponent(0.18).cgColor
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
            to: billingTypeSegmentedControl,
            reduceTransparencyActive: reduceTransparency
        )
        cyclePickerView.updateAppearance(reduceTransparencyActive: reduceTransparency)
        trialPickerView.updateAppearance(reduceTransparencyActive: reduceTransparency)
        reminderPickerView.updateAppearance(reduceTransparencyActive: reduceTransparency)
        reminderBannerView.updateAppearance(reduceTransparencyActive: reduceTransparency)

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

    @objc private func billingTypeSegmentChanged(_ sender: UISegmentedControl) {
        onBillingTypeSegmentChanged?(sender.selectedSegmentIndex)
    }

    @objc private func cycleSegmentChanged(_ sender: UISegmentedControl) {
        onCycleSegmentChanged?(sender.selectedSegmentIndex)
    }

    @objc private func trialSegmentChanged(_ sender: UISegmentedControl) {
        onTrialSegmentChanged?(sender.selectedSegmentIndex)
    }

    @objc private func dateTapped() {
        onDateTapped?()
    }

    func setReminderIntervals(_ intervals: [Int]) {
        reminderPickerView.selectedInterval = intervals.first
    }

    func setCustomPickerVisible(_ visible: Bool, animated: Bool) {
        cyclePickerView.setCustomContentVisible(
            visible,
            animated: animated,
            layoutView: mainStackView
        )
    }

    func setCustomTrialPickerVisible(_ visible: Bool, animated: Bool) {
        trialPickerView.setCustomContentVisible(
            visible,
            animated: animated,
            layoutView: mainStackView
        )
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

        let titleKey: String.LocalizationValue = "\(currency.name) \(displaySymbol) \(code)"
        let title = String(localized: titleKey)
        currencyButton.setTitle(title, for: UIControl.State.normal)
        if var configuration = currencyButton.configuration {
            configuration.title = title
            currencyButton.configuration = configuration
        }
        let accessibilityKey: String.LocalizationValue = "Selected currency: \(currency.name) \(currency.code)"
        currencyButton.accessibilityLabel = String(localized: accessibilityKey)
    }

    func updateReminderPermissionBanner(isVisible: Bool, message: String?) {
        reminderBannerView.update(message: message)
        reminderBannerView.isHidden = !isVisible
    }

    func updateIconPreview(image: UIImage?) {
        if let image {
            iconImageView.image = image
            iconControl.accessibilityLabel = String(localized: "Subscription icon")
        } else {
            iconImageView.image = UIImage.subZenAppIconPlaceholder
            iconControl.accessibilityLabel = String(localized: "No subscription icon")
        }
    }

    func setIconMenu(_ menu: UIMenu?) {
        iconControl.menu = menu
        iconControl.showsMenuAsPrimaryAction = menu != nil
    }

    func setIconLoading(_ isLoading: Bool) {
        if isLoading {
            iconActivityIndicator.startAnimating()
        } else {
            iconActivityIndicator.stopAnimating()
        }
        iconControl.isEnabled = !isLoading
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

    func updateTrialHint(hint: String?, highlightRange: NSRange?) {
        guard let hint else {
            trialHintLabel.isHidden = true
            trialHintLabel.attributedText = nil
            return
        }

        trialHintLabel.isHidden = false
        let attributedString = NSMutableAttributedString(string: hint)
        if let range = highlightRange {
            attributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: range)
            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 13, weight: .semibold), range: range)
        }
        trialHintLabel.attributedText = attributedString
    }

    func setLifetimeModeEnabled(_ enabled: Bool, animated: Bool) {
        let update = {
            self.cycleSectionView.isHidden = enabled
            self.trialSectionView.isHidden = enabled
            self.reminderSectionView.isHidden = enabled
            self.nextBillingHintLabel.isHidden = enabled
            self.dateLabel.text = enabled ? String(localized: "Purchase Date") : String(localized: "Last Billing Date")
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: update
            )
        } else {
            update()
        }
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
