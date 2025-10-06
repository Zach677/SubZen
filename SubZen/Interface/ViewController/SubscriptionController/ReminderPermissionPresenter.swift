import Foundation
import UserNotifications

struct ReminderPermissionViewState {
    let isBannerVisible: Bool
    let message: String?
}

final class ReminderPermissionPresenter {
    private let notificationPermissionService: NotificationPermissionService
    private let authorizedStatuses: Set<UNAuthorizationStatus> = [.authorized, .provisional, .ephemeral]

    init(notificationPermissionService: NotificationPermissionService) {
        self.notificationPermissionService = notificationPermissionService
    }

    func makeViewState(hasReminderSelection: Bool) -> ReminderPermissionViewState {
        let status = notificationPermissionService.permissionStatus
        let hasRequested = notificationPermissionService.hasRequestedPermission
        let isAuthorized = authorizedStatuses.contains(status)

        let shouldShowBanner = hasReminderSelection && hasRequested && !isAuthorized
        let message: String?

        if shouldShowBanner {
            switch status {
            case .denied:
                message = String(localized: "Notifications are turned off. Tap to open notification settings.")
            case .notDetermined:
                fallthrough
            default:
                message = String(localized: "Enable notifications to receive reminders. Tap to open notification settings.")
            }
        } else {
            message = nil
        }

        return ReminderPermissionViewState(
            isBannerVisible: shouldShowBanner,
            message: message
        )
    }

    func shouldRequestPermissionOnSelectionChange(hasReminderSelection: Bool) -> Bool {
        hasReminderSelection && notificationPermissionService.shouldRequestPermission()
    }
}
