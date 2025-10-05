//
//  SubscriptionNotificationManager.swift
//  SubZen
//
//  Created by Star on 2025/10/4.
//

import Foundation

class SubscriptionNotificationManager {
    static let shared = SubscriptionNotificationManager()

    private let notificationService: SubscriptionNotificationScheduling

    init(notificationService: SubscriptionNotificationScheduling = SubscriptionNotificationService()) {
        self.notificationService = notificationService
    }

    // MARK: - Public Methods

    /// Schedule notifications for a subscription based on its reminder intervals
    func scheduleNotifications(for subscription: Subscription) async {
        do {
            try await notificationService.scheduleNotifications(for: subscription)
            print("Successfully scheduled notifications for subscription: \(subscription.name)")
        } catch {
            print("Failed to schedule notifications for subscription: \(subscription.name), error: \(error)")
        }
    }

    /// Cancel all notifications for a subscription
    func cancelNotifications(for subscription: Subscription) async {
        await notificationService.cancelNotifications(for: subscription)
        print("Cancelled notifications for subscription: \(subscription.name)")
    }

    /// Update notifications for a subscription (cancel old ones and schedule new ones)
    func updateNotifications(for subscription: Subscription) async {
        // Cancel existing notifications
        await cancelNotifications(for: subscription)

        // Schedule new notifications if there are reminder intervals
        if !subscription.reminderIntervals.isEmpty {
            await scheduleNotifications(for: subscription)
        }
    }

    /// Handle subscription creation - schedule notifications if reminder intervals are set
    func handleSubscriptionCreated(_ subscription: Subscription) async {
        if !subscription.reminderIntervals.isEmpty {
            await scheduleNotifications(for: subscription)
        }
    }

    /// Handle subscription update - update notifications
    func handleSubscriptionUpdated(_ subscription: Subscription) async {
        await updateNotifications(for: subscription)
    }

    /// Handle subscription deletion - cancel all notifications
    func handleSubscriptionDeleted(_ subscription: Subscription) async {
        await cancelNotifications(for: subscription)
    }

    /// Cancel all scheduled notifications
    func cancelAllNotifications() async {
        await notificationService.cancelAllScheduledNotifications()
    }
}
