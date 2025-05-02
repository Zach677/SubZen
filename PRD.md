# Subscription Tracker iOS – Lean PRD & Kanban (Markdown)

---
## 1. Background & Goal
- **Problem**  iOS 自带订阅页零散，用户难以把握总体花费 & 到期时间。
- **Goal**  30 秒内一览订阅概况，并在到期前收到提醒。

---
## 2. North‑Star Metric
| Metric | Target |
| ------ | ------ |
| DAU | 5 K |
| 添加订阅转化率 | 70 % |
| 订阅留存率 (3 个月) | 40 % |

---
## 3. Scope
### 3.1  Now (0‑2 mo)
- **F1 手动添加订阅** – 名称 / 金额 / 周期 / 到期日 (`SwiftUI`, `UserDefaults`)
- **F2 订阅列表 + 月/年支出汇总** (`SwiftUI`, `Swift`, `UserDefaults`)
- **F3 本地推送提醒** – 到期前 X 天 (`UserNotifications`)
- **F4 导出 CSV** _(可选)_ (`ShareLink` / `UIActivityViewController`)

### 3.2  Next (3‑4 mo)
- **N1 自动识别 App  Store 订阅** (`StoreKit 2`)
- **N2 iCloud 同步** (`CloudKit` + `UserDefaults`)
- **N3 支出图表** (`Swift Charts`)

### 3.3  Later (5‑6 mo)
- **L1 AI 取消建议** (`Core ML`, `Create ML` / Heuristics)
- **L2 多货币 & 汇率** (外部 API)
- **L3 Pro 订阅** (`StoreKit 2`, iPad, PDF 导出 - `PDFKit`/`Core Graphics`)

---
## 4. Kanban Checklist (Now)
```markdown
# Feature: F1 手动添加订阅
- [x] 设计 `Subscription` 数据结构 (用于 `UserDefaults` 存储)
- [x] 创建添加/编辑订阅的 `SwiftUI` 表单视图
- [x] 实现数据验证逻辑
- [x] 实现数据保存到 `UserDefaults`

# Feature: F2 订阅列表 + 汇总
- [x] 创建显示订阅列表的 `SwiftUI` `List` 视图
- [x] 实现从 `UserDefaults` 加载和排序数据
- [x] 实现月度/年度支出汇总计算逻辑
- [ ] 在 `SwiftUI` 视图中展示汇总信息

# Feature: F3 本地推送提醒
- [ ] 请求 `UserNotifications` 推送权限
- [ ] 实现基于订阅到期日和提前天数的通知调度逻辑 (`UNUserNotificationCenter`)
- [ ] 添加设置提醒提前天数的选项 (存储于 `UserDefaults`)

# Feature: F4 导出 CSV (可选)
- [ ] 实现将订阅数据格式化为 CSV 字符串的 Helper
- [ ] 使用 `ShareLink` 或 `UIActivityViewController` 实现分享功能
```

---
## 5. Non‑Functional
- 离线可用（数据本地持久化 `UserDefaults`)
- 冷启动 ≤ 800 ms (使用 Instruments 进行性能分析)
- iOS 16+ (若使用 `Swift Charts`, `ShareLink` 等较新 API)

---
## 6. Tech Stack Summary (推荐)
- **UI:** SwiftUI
- **Data Persistence:** UserDefaults
- **Notifications:** UserNotifications
- **App Store Interaction:** StoreKit 2
- **Cloud Sync:** CloudKit
- **Charts:** Swift Charts (iOS 16+)
- **Device-side AI:** Core ML

---
💡 维护规则：将完成的任务打勾即可；若需新增功能，直接在对应区块增行。

