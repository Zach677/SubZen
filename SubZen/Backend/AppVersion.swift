//
//  AppVersion.swift
//  SubZen
//

import Foundation

enum AppVersion {
    static let version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    static let build: Int = .init(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "") ?? 0

    static var displayString: String {
        #if DEBUG
            String(format: String(localized: "Version %@ (%d)"), version, build) + " 🐛"
        #else
            String(format: String(localized: "Version %@ (%d)"), version, build)
        #endif
    }
}
