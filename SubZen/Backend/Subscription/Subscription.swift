//
//  Subscription.swift
//  SubZen
//
//  Created by Star on 2025/4/13.
//

import Foundation

// MARK: - BillingCycle Enum

enum BillingCycle: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    /// Returns the calendar component for date calculations
    var calendarComponent: Calendar.Component {
        switch self {
        case .daily: .day
        case .weekly: .weekOfYear
        case .monthly: .month
        case .yearly: .year
        }
    }

    /// Returns the value for date calculations
    var calendarValue: Int { 1 }

    /// Returns a short display name for UI labels
    var displayUnit: String {
        switch self {
        case .daily: "day"
        case .weekly: "week"
        case .monthly: "month"
        case .yearly: "year"
        }
    }
}

// MARK: - SubscriptionValidationError

enum SubscriptionValidationError: LocalizedError {
    case emptyName
    case negativePriceQuestionablePrice
    case invalidCurrency
    case futureBillingDate

    var errorDescription: String? {
        switch self {
        case .emptyName: "Subscription name cannot be empty"
        case .negativePriceQuestionablePrice: "Subscription price must be greater than 0"
        case .invalidCurrency: "Invalid currency code"
        case .futureBillingDate: "Last billing date cannot be in the future"
        }
    }
}

// MARK: - Subscription Model

final class Subscription: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var price: Decimal
    var cycle: BillingCycle
    var lastBillingDate: Date
    var currencyCode: String
    var reminderIntervals: [Int] // Days before expiration to send reminders (e.g., [1, 7, 14])

    init(
        name: String = "",
        price: Decimal = 0.0,
        cycle: BillingCycle = .monthly,
        lastBillingDate: Date = .now,
        currencyCode: String = "USD",
        reminderIntervals: [Int] = []
    ) throws {
        let normalizedCurrencyCode = currencyCode.uppercased()

        try Self.validateInputs(
            name: name,
            price: price,
            lastBillingDate: lastBillingDate,
            currencyCode: normalizedCurrencyCode
        )

        self.name = name
        self.price = price
        self.cycle = cycle
        self.lastBillingDate = lastBillingDate
        self.currencyCode = normalizedCurrencyCode
        self.reminderIntervals = reminderIntervals
    }

    /// Convenience initializer for existing data migration
    convenience init(
        name: String = "",
        price: Decimal = 0.0,
        cycleString: String = "Monthly",
        lastBillingDate: Date = .now,
        currencyCode: String = "USD",
        reminderIntervals: [Int] = []
    ) {
        let cycle = BillingCycle(rawValue: cycleString) ?? .monthly
        try! self.init(name: name, price: price, cycle: cycle, lastBillingDate: lastBillingDate, currencyCode: currencyCode, reminderIntervals: reminderIntervals)
    }

    /// Input validation
    private static func validateInputs(name: String, price: Decimal, lastBillingDate: Date, currencyCode: String) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SubscriptionValidationError.emptyName
        }

        guard price > 0 else {
            throw SubscriptionValidationError.negativePriceQuestionablePrice
        }

        guard lastBillingDate <= Date() else {
            throw SubscriptionValidationError.futureBillingDate
        }

        // Basic currency validation (you can enhance this with Currency enum validation)
        guard currencyCode.count == 3 else {
            throw SubscriptionValidationError.invalidCurrency
        }

        guard CurrencyList.supports(code: currencyCode) else {
            throw SubscriptionValidationError.invalidCurrency
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, price, cycle, lastBillingDate, currencyCode, reminderIntervals
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        price = try container.decode(Decimal.self, forKey: .price)

        // Handle backward compatibility for string-based cycle
        if let cycleString = try? container.decode(String.self, forKey: .cycle) {
            cycle = BillingCycle(rawValue: cycleString) ?? .monthly
        } else {
            cycle = try container.decode(BillingCycle.self, forKey: .cycle)
        }

        lastBillingDate = try container.decode(Date.self, forKey: .lastBillingDate)
        currencyCode = try container.decode(String.self, forKey: .currencyCode).uppercased()

        // Handle backward compatibility for reminderIntervals (default to empty array)
        reminderIntervals = (try? container.decode([Int].self, forKey: .reminderIntervals)) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(price, forKey: .price)
        try container.encode(cycle.rawValue, forKey: .cycle) // Encode as string for compatibility
        try container.encode(lastBillingDate, forKey: .lastBillingDate)
        try container.encode(currencyCode, forKey: .currencyCode)
        try container.encode(reminderIntervals, forKey: .reminderIntervals)
    }

    // MARK: - Equatable

    static func == (lhs: Subscription, rhs: Subscription) -> Bool {
        lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.price == rhs.price &&
            lhs.cycle == rhs.cycle &&
            lhs.lastBillingDate == rhs.lastBillingDate &&
            lhs.currencyCode == rhs.currencyCode &&
            lhs.reminderIntervals == rhs.reminderIntervals
    }

    // MARK: - priceLabel formatting

    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: price as NSDecimalNumber) ?? "\(price)"
    }

    // MARK: - Billing Date Calculations

    /// Calculate remaining days until next billing date
    var remainingDays: Int {
        let nextBillingDate = calculateNextBillingDate()
        let currentDate = Date()

        // Use startOfDay to avoid truncating partial days when calculating the gap.
        let calendar = Calendar.current
        let startOfCurrentDay = calendar.startOfDay(for: currentDate)
        let startOfNextBillingDay = calendar.startOfDay(for: nextBillingDate)
        let components = calendar.dateComponents([.day], from: startOfCurrentDay, to: startOfNextBillingDay)

        // Return 0 if past billing date (needs immediate renewal)
        return max(0, components.day ?? 0)
    }

    /// Calculate next billing date using precise Calendar calculations
    private func calculateNextBillingDate() -> Date {
        let calendar = Calendar.current
        let currentDate = Date()

        // Start from last billing date and find next future billing date
        var nextBillingDate = lastBillingDate

        while nextBillingDate <= currentDate {
            nextBillingDate = calendar.date(
                byAdding: cycle.calendarComponent,
                value: cycle.calendarValue,
                to: nextBillingDate
            ) ?? nextBillingDate
        }

        return nextBillingDate
    }

    /// Get next billing date (public accessor)
    func getNextBillingDate() -> Date {
        calculateNextBillingDate()
    }
}
