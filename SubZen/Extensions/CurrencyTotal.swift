import Foundation

extension Array where Element == Subscription {
    var monthlyTotal: Decimal {
        reduce(0) { total, subscription in
            var currentTotal = total
            switch subscription.cycle {
            case "Monthly":
                currentTotal += subscription.price
            case "Weekly":
                currentTotal += subscription.price * 4
            case "Daily":
                currentTotal += subscription.price * 30
            default:
                break
            }
            return currentTotal
        }
    }

    var yearlyTotal: Decimal {
        reduce(0) { total, subscription in
            var currentTotal = total
            switch subscription.cycle {
            case "Yearly":
                currentTotal += subscription.price
            case "Monthly":
                currentTotal += subscription.price * 12
            case "Weekly":
                currentTotal += subscription.price * 52
            case "Daily":
                currentTotal += subscription.price * 365
            default:
                break
            }
            return currentTotal
        }
    }
}
