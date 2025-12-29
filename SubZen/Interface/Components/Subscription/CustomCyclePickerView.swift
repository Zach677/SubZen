//
//  CustomCyclePickerView.swift
//  SubZen
//
//  Created by Star on 2025/12/29.
//

import SnapKit
import UIKit

final class CustomCyclePickerView: UIView {
    private enum Layout {
        static let pickerHeight: CGFloat = 160
        static let cornerRadius: CGFloat = 16
        static let labelTopPadding: CGFloat = 12
        static let labelLeadingPadding: CGFloat = 16
    }

    private let valuePicker = UIPickerView()
    private let unitPicker = UIPickerView()
    private let containerView = UIView()
    private let everyLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        $0.textColor = .secondaryLabel
        $0.text = String(localized: "Every")
    }

    private let valueRange = Array(1 ... 99)
    private let units = CycleUnit.selectableUnits

    private var selectedValue: Int = 2
    private var selectedUnit: CycleUnit = .month
    private var reduceTransparencyActive = UIAccessibility.isReduceTransparencyEnabled

    var onSelectionChanged: ((Int, CycleUnit) -> Void)?

    init() {
        super.init(frame: .zero)
        configureView()
        buildHierarchy()
        setupConstraints()
    }

    private func configureView() {
        containerView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.7)
        containerView.layer.cornerRadius = Layout.cornerRadius
        containerView.layer.cornerCurve = .continuous

        valuePicker.dataSource = self
        valuePicker.delegate = self
        unitPicker.dataSource = self
        unitPicker.delegate = self

        // Set initial selection: 2 months
        valuePicker.selectRow(1, inComponent: 0, animated: false) // "2"
        unitPicker.selectRow(1, inComponent: 0, animated: false) // "month"
    }

    private func buildHierarchy() {
        addSubview(containerView)
        containerView.addSubview(everyLabel)
        containerView.addSubview(valuePicker)
        containerView.addSubview(unitPicker)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        everyLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.labelTopPadding)
            make.leading.equalToSuperview().offset(Layout.labelLeadingPadding)
        }

        valuePicker.snp.makeConstraints { make in
            make.top.equalTo(everyLabel.snp.bottom).offset(-8)
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
        selectedValue = value
        selectedUnit = unit

        if let valueIndex = valueRange.firstIndex(of: value) {
            valuePicker.selectRow(valueIndex, inComponent: 0, animated: false)
        }
        if let unitIndex = units.firstIndex(of: unit) {
            unitPicker.selectRow(unitIndex, inComponent: 0, animated: false)
        }
    }

    func currentSelection() -> (value: Int, unit: CycleUnit) {
        (selectedValue, selectedUnit)
    }

    func updateAppearance(reduceTransparencyActive newValue: Bool) {
        reduceTransparencyActive = newValue
        containerView.backgroundColor =
            newValue
                ? UIColor.secondarySystemBackground
                : UIColor.secondarySystemBackground.withAlphaComponent(0.7)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate

extension CustomCyclePickerView: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in _: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent _: Int) -> Int {
        pickerView == valuePicker ? valueRange.count : units.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent _: Int) -> String? {
        if pickerView == valuePicker {
            return "\(valueRange[row])"
        } else {
            let unit = units[row]
            return selectedValue == 1 ? unit.localizedName : unit.localizedPluralName
        }
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
