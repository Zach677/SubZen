import Foundation

/// A guard that preserves and restores a specific UserDefaults key around tests
/// to avoid polluting the developer's local defaults.
final class UserDefaultsGuard {
    private let key: String
    private var originalData: Data?
    private let defaults: UserDefaults

    init(key: String, defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
        self.originalData = defaults.data(forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }

    deinit {
        // Restore original value to avoid affecting the running environment
        if let originalData {
            defaults.set(originalData, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}

