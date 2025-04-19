//
//  Subscription.swift
//  SubZen
//
//  Created by Star on 2025/4/13.
//

import Foundation
import SwiftData

@Model
final class Subscription {
  var name: String
  var price: Decimal
  var Cycle: String
  var dateAdded: Date
  var currencyCode: String

  init(
    name: String = "",
    price: Decimal = 0.0,
    Cycle: String = "Monthly",
    dateAdded: Date = .now,
    currencyCode: String = "USD"
  ) {
    self.name = name
    self.price = price
    self.Cycle = Cycle
    self.dateAdded = dateAdded
    self.currencyCode = currencyCode
  }
}
