//
//  ValueUnitPickerView.swift
//  SubZen
//
//  Created by Star on 2026/1/5.
//

import SnapKit
import UIKit

class ValueUnitPickerView: UIView {
    private enum Layout {
        static let pickerHeight: CGFloat = 160
        static let cornerRadius: CGFloat = 16
        static let labelTopPadding: CGFloat = 12
        static let labelLeadingPadding: CGFloat = 16
    }

    private let valuePicker = UIPickerView()
    private let unitPicker = UIPickerView()
    private let containerView = UIView()
    private let headerLabel = UILabel()

    private let valueRange: [Int]
    private let units: [CycleUnit]

    private var selectedValue: Int
    private var selectedUnit: CycleUnit

    var onSelectionChanged: ((Int, CycleUnit) -> Void)?

    init(
        labelText: String,
        units: [CycleUnit],
        initialValue: Int,
        initialUnit: CycleUnit,
        valueRange: ClosedRange<Int> = 1 ... 99
    ) {
        self.valueRange = Array(valueRange)
        self.units = units
        selectedValue = initialValue
        selectedUnit = initialUnit

        super.init(frame: .zero)

        headerLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        headerLabel.textColor = .secondaryLabel
        headerLabel.text = labelText

        configureView()
        buildHierarchy()
        setupConstraints()
        configure(value: initialValue, unit: initialUnit)
        updateAppearance(reduceTransparencyActive: UIAccessibility.isReduceTransparencyEnabled)
    }

    private func configureView() {
        precondition(!units.isEmpty)

        containerView.layer.cornerRadius = Layout.cornerRadius
        containerView.layer.cornerCurve = .continuous

        valuePicker.dataSource = self
        valuePicker.delegate = self
        unitPicker.dataSource = self
        unitPicker.delegate = self
    }

    private func buildHierarchy() {
        addSubview(containerView)
        containerView.addSubview(headerLabel)
        containerView.addSubview(valuePicker)
        containerView.addSubview(unitPicker)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        headerLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.labelTopPadding)
            make.leading.equalToSuperview().offset(Layout.labelLeadingPadding)
        }

        valuePicker.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(-8)
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview()
            make.height.equalTo(Layout.pickerHeight)
            make.width.equalTo(unitPicker)
        }

        unitPicker.snp.makeConstraints { make in
            make.top.equalTo(valuePicker)
            make.leading.equalTo(valuePicker.snp.trailing).offset(4)
            make.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview()
            make.height.equalTo(Layout.pickerHeight)
        }
    }

    func configure(value: Int, unit: CycleUnit) {
        let previousValue = selectedValue
        selectedValue = value
        selectedUnit = unit

        if let valueIndex = valueRange.firstIndex(of: value) {
            valuePicker.selectRow(valueIndex, inComponent: 0, animated: false)
        }

        if previousValue != value {
            unitPicker.reloadAllComponents()
        }

        if let unitIndex = units.firstIndex(of: unit) {
            unitPicker.selectRow(unitIndex, inComponent: 0, animated: false)
        }
    }

    func currentSelection() -> (value: Int, unit: CycleUnit) {
        (selectedValue, selectedUnit)
    }

    func updateAppearance(reduceTransparencyActive: Bool) {
        containerView.backgroundColor =
            reduceTransparencyActive
                ? UIColor.secondarySystemBackground
                : UIColor.secondarySystemBackground.withAlphaComponent(0.7)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate

extension ValueUnitPickerView: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in _: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent _: Int) -> Int {
        pickerView == valuePicker ? valueRange.count : units.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent _: Int) -> String? {
        if pickerView == valuePicker {
            return "\(valueRange[row])"
        }

        let unit = units[row]
        return selectedValue == 1 ? unit.localizedName : unit.localizedPluralName
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent _: Int) {
        if pickerView == valuePicker {
            selectedValue = valueRange[row]
            unitPicker.reloadAllComponents()
        } else {
            selectedUnit = units[row]
        }
        onSelectionChanged?(selectedValue, selectedUnit)
    }

    func pickerView(_: UIPickerView, widthForComponent _: Int) -> CGFloat {
        140
    }
}

final class CustomCyclePickerView: ValueUnitPickerView {
    init() {
        super.init(
            labelText: String(localized: "Every"),
            units: CycleUnit.selectableUnits,
            initialValue: 2,
            initialUnit: .month
        )
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}

final class CustomTrialPickerView: ValueUnitPickerView {
    init() {
        super.init(
            labelText: String(localized: "For"),
            units: [.day, .week, .month],
            initialValue: 7,
            initialUnit: .day
        )
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}
