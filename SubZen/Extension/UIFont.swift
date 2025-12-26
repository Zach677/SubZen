//
//  UIFont.swift
//  SubZen
//

import UIKit

extension UIFont {
    var monospaced: UIFont {
        let descriptor = fontDescriptor.withDesign(.monospaced) ?? fontDescriptor
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
