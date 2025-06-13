//
//  Subscription+RemainingDays.swift
//  SubZen
//
//  Created by Star on 2025/4/13.
//

import Foundation

extension Subscription {

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
      return 1
    case "Weekly":
      return 7
    case "Monthly":
      return 30  // 简化为30天，你可以根据需要调整为更精确的月份计算
    case "Yearly":
      return 365  // 简化为365天，你可以根据需要调整为更精确的年份计算
    default:
      return 30  // 默认为月度
    }
  }
}
