//
//  UILabel+Factory.swift
//  SubZen
//

import UIKit

extension UILabel {
    /// Creates a label configured as a form field label (medium weight, 16pt)
    static func makeFormFieldLabel(text: String) -> UILabel {
        UILabel().with {
            $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            $0.textColor = .label
            $0.text = text
        }
    }

    /// Creates a label configured as a setting row title (medium weight, 16pt, secondary color)
    static func makeSettingTitleLabel(text: String) -> UILabel {
        UILabel().with {
            $0.text = text
            $0.font = .systemFont(ofSize: 16, weight: .medium)
            $0.textColor = .secondaryLabel
        }
    }
}
