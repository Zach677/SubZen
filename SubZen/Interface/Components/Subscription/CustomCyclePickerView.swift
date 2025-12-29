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

    private let pickerView = UIPickerView()
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

        pickerView.dataSource = self
        pickerView.delegate = self

        // Set initial selection: 2 months
        pickerView.selectRow(1, inComponent: 0, animated: false) // "2"
        pickerView.selectRow(1, inComponent: 1, animated: false) // "month"
    }

    private func buildHierarchy() {
        addSubview(containerView)
        containerView.addSubview(everyLabel)
        containerView.addSubview(pickerView)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        everyLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.labelTopPadding)
            make.leading.equalToSuperview().offset(Layout.labelLeadingPadding)
        }

        pickerView.snp.makeConstraints { make in
            make.top.equalTo(everyLabel.snp.bottom).offset(-8) // Negative offset to pull picker closer to label while keeping it below
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(Layout.pickerHeight)
        }
    }

    func configure(value: Int, unit: CycleUnit) {
        selectedValue = value
        selectedUnit = unit

        if let valueIndex = valueRange.firstIndex(of: value) {
            pickerView.selectRow(valueIndex, inComponent: 0, animated: false)
        }
        if let unitIndex = units.firstIndex(of: unit) {
            pickerView.selectRow(unitIndex, inComponent: 1, animated: false)
        }
    }

    func currentSelection() -> (value: Int, unit: CycleUnit) {
        (selectedValue, selectedUnit)
    }

    func updateAppearance(reduceTransparencyActive newValue: Bool) {
        reduceTransparencyActive = newValue
        containerView.backgroundColor = newValue
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
    func numberOfComponents(in _: UIPickerView) -> Int { 2 }

    func pickerView(_: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        component == 0 ? valueRange.count : units.count
    }

    func pickerView(_: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return "\(valueRange[row])"
        } else {
            let unit = units[row]
            // Use plural form based on current value selection
            return selectedValue == 1 ? unit.localizedName : unit.localizedPluralName
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            selectedValue = valueRange[row]
            // Refresh unit column to update singular/plural
            pickerView.reloadComponent(1)
        } else {
            selectedUnit = units[row]
        }
        onSelectionChanged?(selectedValue, selectedUnit)
    }

    func pickerView(_: UIPickerView, widthForComponent component: Int) -> CGFloat {
        component == 0 ? 80 : 120
    }
}
