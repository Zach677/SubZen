//
//  UITextField+Factory.swift
//  SubZen
//

import UIKit

extension UITextField {
    /// Creates a text field configured for form input with common settings
    static func makeFormTextField(placeholder: String, keyboardType: UIKeyboardType = .default) -> UITextField {
        UITextField().with {
            $0.borderStyle = .none
            $0.placeholder = placeholder
            $0.clearButtonMode = .whileEditing
            $0.autocapitalizationType = .none
            $0.autocorrectionType = .no
            $0.keyboardType = keyboardType
        }
    }
}
