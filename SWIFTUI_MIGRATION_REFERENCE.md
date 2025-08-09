# SwiftUI到UIKit迁移参考文档

## 原有存储键值对模式 (Storage Key-Value Patterns)

### 1. 订阅数据 (Subscription Data)
```swift
// SubscriptionManager.swift
private let subscriptionsKey = "subscriptions"
// 存储类型: Data (JSON编码的 [Subscription] 数组)
// 读取: JSONDecoder().decode([Subscription].self, from: data)
// 保存: JSONEncoder().encode(subscriptions)
```

### 2. 货币设置 (Currency Settings) 
```swift
// CurrencyTotalService.swift
UserDefaults.standard.string(forKey: "BaseCurrency")
UserDefaults.standard.set(baseCurrency, forKey: "BaseCurrency")
// 存储类型: String (货币代码如 "USD", "CNY")
```

### 3. 通知权限状态 (Notification Permission)
```swift
// NotificationPermissionService.swift
private let hasRequestedPermissionKey = "HasRequestedNotificationPermission"
// 存储类型: Bool
// 用途: 记录是否已经请求过通知权限
```

### 4. 汇率缓存 (Exchange Rate Cache)
```swift
// ExchangeRateService.swift
// 动态键名格式: "exchangeRate_[from]_to_[to]_[date]"
// 例如: "exchangeRate_USD_to_EUR_2024-01-01"
// 存储类型: Data (JSON编码的汇率数据)
```

## 需要替换的SwiftUI响应式模式

### @Published属性 → UIKit委托模式
```swift
// 原SwiftUI模式:
@Published var baseCurrency: String = "USD"
@Published var isCalculating = false
@Published var lastCalculationError: Error?

// UIKit替代模式:
protocol CurrencyServiceDelegate: AnyObject {
    func currencyService(_ service: CurrencyTotalService, didUpdateBaseCurrency currency: String)
    func currencyService(_ service: CurrencyTotalService, calculationStateChanged isCalculating: Bool)
    func currencyService(_ service: CurrencyTotalService, didEncounterError error: Error?)
}
```

## 服务类中的@Published属性清单

### CurrencyTotalService.swift
- `@Published var baseCurrency: String = "USD"`
- `@Published var isCalculating = false`  
- `@Published var lastCalculationError: Error?`

### ExchangeRateService.swift
- `@Published var isLoading = false`

### NotificationPermissionService.swift
- `@Published var permissionStatus: UNAuthorizationStatus = .notDetermined`
- `@Published var hasRequestedPermission = false`

## 注意事项
1. 所有存储键值对可以在UIKit版本中保持不变
2. JSON编码/解码逻辑可以复用
3. 需要将@Published属性替换为委托模式或闭包回调
4. ObservableObject协议需要移除