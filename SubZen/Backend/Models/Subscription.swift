//
//  Subscription.swift
//  SubZen
//
//  Created by Star on 2025/4/13.
//

import Foundation

final class Subscription: Codable, Identifiable {
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
}
