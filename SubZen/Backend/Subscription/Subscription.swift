//
//  Subscription.swift
//  SubZen
//
//  Created by Star on 2025/4/13.
//

import Foundation

final class Subscription: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var price: Decimal
    var cycle: String
    var lastBillingDate: Date
    var currencyCode: String

    init(
        name: String = "",
        price: Decimal = 0.0,
        cycle: String = "Monthly",
        lastBillingDate: Date = .now,
        currencyCode: String = "USD"
    ) {
        self.name = name
        self.price = price
        self.cycle = cycle
        self.lastBillingDate = lastBillingDate
        self.currencyCode = currencyCode
    }

    enum CodingKeys: String, CodingKey {
        case id, name, price, cycle, lastBillingDate, currencyCode
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        price = try container.decode(Decimal.self, forKey: .price)
        cycle = try container.decode(String.self, forKey: .cycle)
        lastBillingDate = try container.decode(Date.self, forKey: .lastBillingDate)
        currencyCode = try container.decode(String.self, forKey: .currencyCode)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(price, forKey: .price)
        try container.encode(cycle, forKey: .cycle)
        try container.encode(lastBillingDate, forKey: .lastBillingDate)
        try container.encode(currencyCode, forKey: .currencyCode)
    }

    // MARK: - Equatable

    static func == (lhs: Subscription, rhs: Subscription) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.price == rhs.price
            && lhs.cycle == rhs.cycle && lhs.lastBillingDate == rhs.lastBillingDate
            && lhs.currencyCode == rhs.currencyCode
    }

    // MARK: - Billing Date Calculations

    /// 计算剩余天数到下一次账单日期
    var remainingDays: Int {
        let nextBillingDate = calculateNextBillingDate()
        let currentDate = Date()

        // 计算从当前日期到下一个账单日期的天数
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: currentDate, to: nextBillingDate)

        // 如果已经过了账单日期，返回0（表示需要立即续费）
        return max(0, components.day ?? 0)
    }

    /// 计算下一个账单日期
    private func calculateNextBillingDate() -> Date {
        let calendar = Calendar.current
        let currentDate = Date()

        // 获取账单周期天数
        let cycleDays = getCycleDays()

        // 从最后账单日期开始，找到下一个未来的账单日期
        var nextBillingDate = lastBillingDate

        while nextBillingDate <= currentDate {
            nextBillingDate =
                calendar.date(byAdding: .day, value: cycleDays, to: nextBillingDate) ?? nextBillingDate
        }

        return nextBillingDate
    }

    /// 根据cycle字符串获取对应的天数
    private func getCycleDays() -> Int {
        switch cycle {
        case "Daily":
            1
        case "Weekly":
            7
        case "Monthly":
            30 // 简化为30天，你可以根据需要调整为更精确的月份计算
        case "Yearly":
            365 // 简化为365天，你可以根据需要调整为更精确的年份计算
        default:
            30 // 默认为月度
        }
    }
}
