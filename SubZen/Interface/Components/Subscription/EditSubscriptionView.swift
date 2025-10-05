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
        $0.configuration = EditSubscriptionButtonStyler.makeCurrencyButtonBaseConfiguration(
            contentInsets: Layout.currencyButtonContentInsets
        )
        $0.tintColor = .secondaryLabel
        $0.layer.cornerRadius = Layout.currencyButtonCornerRadius
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

    let reminderLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.text = "Remind Me"
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

    private let floatingSaveBar = FloatingSaveBarView(
        containerLayoutMargins: Layout.saveContentMargins,
        buttonContentInsets: Layout.saveButtonInsets,
        cornerRadius: Layout.saveCornerRadius,
        minimumButtonHeight: Layout.saveButtonMinHeight
    )

    private let reminderPickerView = ReminderChipPickerView(
        cornerRadius: Layout.segmentedCornerRadius
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

    private lazy var nameSectionView = makeVerticalFormSection(label: nameLabel, content: nameTextField)
    private lazy var priceSectionView = makeVerticalFormSection(label: priceLabel, content: priceInputStackView)
    private lazy var cycleSectionView = makeVerticalFormSection(label: cycleLabel, content: cycleSegmentedControl)
    private lazy var dateSectionView = makeVerticalFormSection(label: dateLabel, content: datePicker, alignment: .leading)
    private lazy var reminderSectionView = makeVerticalFormSection(label: reminderLabel, content: reminderPickerView)

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

    init() {
        super.init(frame: .zero)

        configureView()
        buildHierarchy()
        setupConstraints()
        setupInteractions()
        registerObservers()
        reminderPickerView.configure(options: reminderOptions)
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
        floatingSaveBar.saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        currencyButton.addTarget(self, action: #selector(currencyTapped), for: .touchUpInside)

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
        floatingSaveBar.updateAppearance(reduceTransparencyActive: reduceTransparency)
        EditSubscriptionButtonStyler.applyCurrencyButtonStyle(
            to: currencyButton,
            reduceTransparencyActive: reduceTransparency,
            contentInsets: Layout.currencyButtonContentInsets
        )
        EditSubscriptionSelectionStyler.applySegmentedStyle(
            to: cycleSegmentedControl,
            reduceTransparencyActive: reduceTransparency
        )
        reminderPickerView.updateAppearance(reduceTransparencyActive: reduceTransparency)
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

    func setReminderIntervals(_ intervals: [Int]) {
        reminderPickerView.selectedInterval = intervals.first
    }

    func getReminderIntervals() -> [Int] {
        guard let interval = reminderPickerView.selectedInterval else { return [] }
        return [interval]
    }

    func updateSelectedCurrencyDisplay(with currency: Currency) {
        let code = currency.code
        let symbol = CurrencyList.displaySymbol(for: code)
        let title = "\(currency.name) \(symbol) \(code)"
        currencyButton.setTitle(title, for: .normal)
        currencyButton.accessibilityLabel = "Selected currency: \(currency.name) \(code)"
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
