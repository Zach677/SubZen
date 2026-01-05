//
//  Subscription.swift
//  SubZen
//
//  Created by Star on 2025/4/13.
//

import Foundation

// MARK: - CycleUnit Enum

enum CycleUnit: String, Codable, CaseIterable {
    case day
    case week
    case month
    case year

    /// Units available for user selection in custom picker (excludes day)
    static var selectableUnits: [CycleUnit] {
        [.week, .month, .year]
    }

    var calendarComponent: Calendar.Component {
        switch self {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }

    var localizedName: String {
        switch self {
        case .day: String(localized: "day")
        case .week: String(localized: "week")
        case .month: String(localized: "month")
        case .year: String(localized: "year")
        }
    }

    var localizedPluralName: String {
        switch self {
        case .day: String(localized: "days")
        case .week: String(localized: "weeks")
        case .month: String(localized: "months")
        case .year: String(localized: "years")
        }
    }

    /// Approximate days per unit for progress calculations
    var approximateDays: Int {
        switch self {
        case .day: 1
        case .week: 7
        case .month: 30
        case .year: 365
        }
    }
}

// MARK: - BillingCycle Enum

enum BillingCycle: Codable, Equatable, Hashable {
    case weekly
    case monthly
    case yearly
    case custom(value: Int, unit: CycleUnit)

    /// Preset cases for UI segmented control
    static var presetCases: [BillingCycle] {
        [.weekly, .monthly, .yearly]
    }

    /// Returns the calendar component for date calculations
    var calendarComponent: Calendar.Component {
        switch self {
        case .weekly: .weekOfYear
        case .monthly: .month
        case .yearly: .year
        case let .custom(_, unit): unit.calendarComponent
        }
    }

    /// Returns the value for date calculations
    var calendarValue: Int {
        switch self {
        case .weekly, .monthly, .yearly: 1
        case let .custom(value, _): value
        }
    }

    /// Returns a short display name for UI labels
    var displayUnit: String {
        switch self {
        case .weekly: String(localized: "week")
        case .monthly: String(localized: "month")
        case .yearly: String(localized: "year")
        case let .custom(value, unit):
            value == 1 ? unit.localizedName : unit.localizedPluralName
        }
    }

    /// Localized display name suitable for segmented controls or pickers
    var localizedName: String {
        switch self {
        case .weekly:
            return String(localized: "Weekly")
        case .monthly:
            return String(localized: "Monthly")
        case .yearly:
            return String(localized: "Yearly")
        case let .custom(value, unit):
            let unitName = value == 1 ? unit.localizedName : unit.localizedPluralName
            return String(localized: "Every \(value) \(unitName)")
        }
    }

    /// Short display name for segmented control
    var shortLocalizedName: String {
        switch self {
        case .weekly: String(localized: "Weekly")
        case .monthly: String(localized: "Monthly")
        case .yearly: String(localized: "Yearly")
        case .custom: String(localized: "Custom")
        }
    }

    var isCustom: Bool {
        if case .custom = self { return true }
        return false
    }

    /// Approximate number of days in this billing cycle
    var cycleDurationInDays: Int {
        switch self {
        case .weekly: 7
        case .monthly: 30
        case .yearly: 365
        case let .custom(value, unit): value * unit.approximateDays
        }
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type, value, unit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "weekly": self = .weekly
        case "monthly": self = .monthly
        case "yearly": self = .yearly
        case "custom":
            let value = try container.decode(Int.self, forKey: .value)
            let unit = try container.decode(CycleUnit.self, forKey: .unit)
            self = .custom(value: value, unit: unit)
        default:
            self = .monthly
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .weekly:
            try container.encode("weekly", forKey: .type)
        case .monthly:
            try container.encode("monthly", forKey: .type)
        case .yearly:
            try container.encode("yearly", forKey: .type)
        case let .custom(value, unit):
            try container.encode("custom", forKey: .type)
            try container.encode(value, forKey: .value)
            try container.encode(unit, forKey: .unit)
        }
    }
}

// MARK: - TrialPeriod

struct TrialPeriod: Codable, Equatable, Hashable {
    let value: Int
    let unit: CycleUnit

    static let presetCases: [TrialPeriod] = [
        TrialPeriod(value: 7, unit: .day),
        TrialPeriod(value: 14, unit: .day),
    ]

    var calendarComponent: Calendar.Component { unit.calendarComponent }
    var calendarValue: Int { value }

    var durationInDays: Int { value * unit.approximateDays }

    var localizedName: String {
        let unitName = value == 1 ? unit.localizedName : unit.localizedPluralName
        return String(localized: "\(value) \(unitName)")
    }

    func endDate(from startDate: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(byAdding: calendarComponent, value: calendarValue, to: startDate)
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
        case .emptyName:
            String(localized: "Subscription name cannot be empty")
        case .negativePriceQuestionablePrice:
            String(localized: "Subscription price must be greater than 0")
        case .invalidCurrency:
            String(localized: "Invalid currency code")
        case .futureBillingDate:
            String(localized: "Last billing date cannot be in the future")
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
    var trialPeriod: TrialPeriod?
    var currencyCode: String
    var reminderIntervals: [Int] // Days before expiration to send reminders (e.g., [1, 7, 14])

    init(
        name: String = "",
        price: Decimal = 0.0,
        cycle: BillingCycle = .monthly,
        lastBillingDate: Date = .now,
        trialPeriod: TrialPeriod? = nil,
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
        self.trialPeriod = trialPeriod
        self.currencyCode = normalizedCurrencyCode
        self.reminderIntervals = reminderIntervals
    }

    /// Input validation
    private static func validateInputs(
        name: String, price: Decimal, lastBillingDate: Date, currencyCode: String
    ) throws {
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
        case id, name, price, cycle, lastBillingDate, trialPeriod, currencyCode, reminderIntervals
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        price = try container.decode(Decimal.self, forKey: .price)

        // BillingCycle handles both new format and legacy string format
        cycle = try container.decode(BillingCycle.self, forKey: .cycle)

        lastBillingDate = try container.decode(Date.self, forKey: .lastBillingDate)
        trialPeriod = try container.decodeIfPresent(TrialPeriod.self, forKey: .trialPeriod)
        currencyCode = try container.decode(String.self, forKey: .currencyCode).uppercased()

        // Handle backward compatibility for reminderIntervals (default to empty array)
        reminderIntervals = (try? container.decode([Int].self, forKey: .reminderIntervals)) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(price, forKey: .price)
        try container.encode(cycle, forKey: .cycle)
        try container.encode(lastBillingDate, forKey: .lastBillingDate)
        try container.encodeIfPresent(trialPeriod, forKey: .trialPeriod)
        try container.encode(currencyCode, forKey: .currencyCode)
        try container.encode(reminderIntervals, forKey: .reminderIntervals)
    }

    // MARK: - Equatable

    static func == (lhs: Subscription, rhs: Subscription) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.price == rhs.price && lhs.cycle == rhs.cycle
            && lhs.lastBillingDate == rhs.lastBillingDate && lhs.currencyCode == rhs.currencyCode
            && lhs.trialPeriod == rhs.trialPeriod && lhs.reminderIntervals == rhs.reminderIntervals
    }

    // MARK: - priceLabel formatting

    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: price as NSDecimalNumber) ?? "\(price)"
    }

    // MARK: - Billing Date Calculations

    func trialEndDate(calendar: Calendar = .current) -> Date? {
        guard let trialPeriod else { return nil }
        return trialPeriod.endDate(from: lastBillingDate, calendar: calendar)
    }

    func isInTrial(on currentDate: Date = .now, calendar: Calendar = .current) -> Bool {
        guard let trialEnd = trialEndDate(calendar: calendar) else { return false }
        return calendar.isDate(trialEnd, inSameDayAs: currentDate) || trialEnd > currentDate
    }

    private func billingAnchorDate(calendar: Calendar = .current) -> Date {
        trialEndDate(calendar: calendar) ?? lastBillingDate
    }

    /// Calculate remaining days until next billing date
    var remainingDays: Int {
        let currentDate = Date()
        let calendar = Calendar.current

        if let trialEnd = trialEndDate(calendar: calendar) {
            if calendar.isDate(trialEnd, inSameDayAs: currentDate) {
                return 0
            }
            if trialEnd > currentDate {
                let startOfCurrentDay = calendar.startOfDay(for: currentDate)
                let startOfTrialEndDay = calendar.startOfDay(for: trialEnd)
                let components = calendar.dateComponents(
                    [.day], from: startOfCurrentDay, to: startOfTrialEndDay
                )
                return max(0, components.day ?? 0)
            }
        }

        var probe = billingAnchorDate(calendar: calendar)
        while true {
            guard
                let next = calendar.date(
                    byAdding: cycle.calendarComponent,
                    value: cycle.calendarValue,
                    to: probe
                )
            else { break }

            if calendar.isDate(next, inSameDayAs: currentDate) {
                return 0
            }

            // If the next boundary is in the future (and not today), stop probing.
            if next > currentDate { break }

            // Advance probe and continue.
            probe = next
        }

        let nextBillingDate = calculateNextBillingDate()
        let startOfCurrentDay = calendar.startOfDay(for: currentDate)
        let startOfNextBillingDay = calendar.startOfDay(for: nextBillingDate)
        let components = calendar.dateComponents(
            [.day], from: startOfCurrentDay, to: startOfNextBillingDay
        )
        return max(0, components.day ?? 0)
    }

    /// Calculate next billing date using precise Calendar calculations
    private func calculateNextBillingDate() -> Date {
        let calendar = Calendar.current
        let currentDate = Date()

        // Start from billing anchor date and find next future billing date
        var nextBillingDate = billingAnchorDate(calendar: calendar)

        while nextBillingDate <= currentDate {
            nextBillingDate =
                calendar.date(
                    byAdding: cycle.calendarComponent,
                    value: cycle.calendarValue,
                    to: nextBillingDate
                ) ?? nextBillingDate
        }

        return nextBillingDate
    }

    /// Next billing date (public accessor)
    func nextBillingDate() -> Date {
        calculateNextBillingDate()
    }

    // MARK: - Expiration Progress

    /// Approximate number of days in the current billing cycle
    var cycleDurationInDays: Int {
        cycle.cycleDurationInDays
    }

    private var currentPeriodDurationInDays: Int {
        guard let trialPeriod, let trialEnd = trialEndDate() else {
            return cycleDurationInDays
        }

        let calendar = Calendar.current
        let now = Date()

        if calendar.isDate(trialEnd, inSameDayAs: now) || trialEnd > now {
            return trialPeriod.durationInDays
        }

        return cycleDurationInDays
    }

    /// Progress toward expiration (0.0 = just renewed, 1.0 = expiring today)
    var expirationProgress: Double {
        let total = Double(currentPeriodDurationInDays)
        let remaining = Double(remainingDays)
        return max(0.0, min(1.0, 1.0 - remaining / total))
    }
}
