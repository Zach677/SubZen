# Subscription Tracker iOS – Lean PRD & Kanban (Markdown)

---
## 1. Background & Goal
- **Problem**  iOS 自带订阅页零散，用户难以把握总体花费 & 到期时间。
- **Goal**  30 秒内一览订阅概况，并在到期前收到提醒。

---
## 2. North‑Star Metric
| Metric | Target |
| ------ | ------ |
| DAU | 5 K |
| 添加订阅转化率 | 70 % |
| 订阅留存率 (3 个月) | 40 % |

---
## 3. Scope & Timeline

### 3.1 Phase 1: SwiftUI MVP (已完成)
- **F1 手动添加订阅** – 名称 / 金额 / 周期 / 到期日 (`SwiftUI`, `UserDefaults`)
- **F2 订阅列表 + 月/年支出汇总** (`SwiftUI`, `Swift`, `UserDefaults`)
- **F3 本地推送提醒** – 到期前 X 天 (`UserNotifications`)
- **F4 多货币支持 + 汇率转换** (外部 API)

### 3.2 Phase 2: UIKit 重构 (当前阶段 - 0-3 个月)
**目标**: 通过 UIKit 重构提升性能和用户体验

#### 3.2.1 基础架构重构 (0-1 个月)
- **R1 UIKit 基础设施** – AppDelegate, SceneDelegate, 导航架构
- **R2 数据层迁移** – 保持现有服务层，适配 UIKit
- **R3 Coordinator 模式** – 统一导航管理和依赖注入

#### 3.2.2 核心视图迁移 (1-2 个月)
- **R4 高性能订阅列表** – UITableView 替代 SwiftUI List
- **R5 自定义订阅单元格** – 优化内存使用和渲染性能
- **R6 表单视图重构** – 添加/编辑订阅的 UIKit 实现
- **R7 货币选择优化** – 支持搜索和筛选的高性能列表

#### 3.2.3 高级功能和优化 (2-3 个月)
- **R8 响应式绑定** – Combine 替代 SwiftUI 状态管理
- **R9 内存管理优化** – 懒加载、视图复用、内存警告处理
- **R10 自定义动画** – 流畅的 UIKit 动画替代 SwiftUI 隐式动画
- **R11 性能监控** – Instruments 分析和优化

### 3.3 Phase 3: 高级功能 (3-6 个月)
- **N1 自动识别 App Store 订阅** (`StoreKit 2`)
- **N2 iCloud 同步** (`CloudKit` + `UserDefaults`)
- **N3 支出图表** (`Swift Charts` 或 `Core Graphics`)
- **N4 导出功能** – CSV/PDF 导出 (`UIActivityViewController`)

### 3.4 Phase 4: 商业化 (6+ 个月)
- **L1 AI 取消建议** (`Core ML`, `Create ML` / Heuristics)
- **L2 Pro 订阅** (`StoreKit 2`, iPad, 高级功能)
- **L3 Widget 支持** (`WidgetKit`)

---
## 4. UIKit 重构详细计划

### 4.1 技术决策
| 方面 | SwiftUI (当前) | UIKit (目标) | 优势 |
|------|----------------|--------------|------|
| 性能 | 声明式渲染 | 命令式更新 | 精确控制，更高效 |
| 内存 | 自动管理 | 手动优化 | 更好的大列表性能 |
| 动画 | 隐式动画 | 自定义动画 | 更流畅的体验 |
| 兼容性 | iOS 14+ | iOS 13+ | 更广泛的设备支持 |

### 4.2 架构设计
```
UIKit App Architecture
├── Application Layer
│   ├── AppDelegate
│   ├── SceneDelegate
│   └── AppCoordinator
├── Presentation Layer
│   ├── ViewControllers
│   ├── Views (Custom UIView)
│   └── Coordinators
├── Domain Layer
│   ├── Models (保持不变)
│   └── Services (保持不变)
└── Data Layer
    ├── UserDefaults (保持不变)
    └── Network (保持不变)
```

### 4.3 迁移策略
1. **渐进式迁移** – 逐个视图替换，确保应用稳定
2. **数据层复用** – 现有的 `Subscription`、`CurrencyTotalService`、`ExchangeRateService` 直接使用
3. **向后兼容** – 保持现有功能完整性
4. **性能优先** – 每个迁移步骤都要有性能提升

---
## 5. Kanban Checklist

### Phase 1: SwiftUI MVP ✅
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
- [x] 在 `SwiftUI` 视图中展示汇总信息

# Feature: F3 本地推送提醒
- [x] 请求 `UserNotifications` 推送权限
- [x] 实现基于订阅到期日和提前天数的通知调度逻辑 (`UNUserNotificationCenter`)
- [x] 添加设置提醒提前天数的选项 (存储于 `UserDefaults`)

# Feature: F4 多货币支持
- [x] 实现货币数据模型和汇率服务
- [x] 集成外部汇率 API
- [x] 实现货币转换和缓存机制
- [x] 添加货币选择界面
```

### Phase 2: UIKit 重构 🚧
```markdown
# R1: UIKit 基础设施
- [ ] 创建 AppDelegate 和 SceneDelegate
- [ ] 设置 UIKit 导航架构
- [ ] 配置项目设置移除 SwiftUI 依赖

# R2: 数据层迁移
- [ ] 验证现有服务层在 UIKit 中的兼容性
- [ ] 创建 UIKit 适配的数据绑定机制
- [ ] 实现错误处理和状态管理

# R3: Coordinator 模式
- [ ] 实现 AppCoordinator 主协调器
- [ ] 创建各功能模块的 Coordinator
- [ ] 设置依赖注入容器

# R4: 高性能订阅列表
- [ ] 创建 UITableViewController 替代 SwiftUI List
- [ ] 实现数据源和委托模式
- [ ] 优化滚动性能和内存使用

# R5: 自定义订阅单元格
- [ ] 设计 UITableViewCell 布局
- [ ] 实现单元格复用机制
- [ ] 添加交互手势和动画

# R6: 表单视图重构
- [ ] 创建添加订阅的 UIKit 表单
- [ ] 实现编辑订阅功能
- [ ] 优化键盘处理和用户体验

# R7: 货币选择优化
- [ ] 实现支持搜索的货币列表
- [ ] 添加筛选和排序功能
- [ ] 优化大列表性能

# R8: 响应式绑定
- [ ] 使用 Combine 替代 SwiftUI 状态管理
- [ ] 实现数据流和事件处理
- [ ] 确保 UI 和数据同步

# R9: 内存管理优化
- [ ] 实现视图控制器懒加载
- [ ] 优化图片和资源管理
- [ ] 处理内存警告和后台状态

# R10: 自定义动画
- [ ] 实现列表项动画
- [ ] 添加页面转场动画
- [ ] 优化动画性能

# R11: 性能监控
- [ ] 使用 Instruments 分析性能
- [ ] 优化启动时间和内存使用
- [ ] 建立性能基准测试
```

---
## 6. Non‑Functional Requirements

### 6.1 性能目标
- **冷启动时间**: ≤ 500ms (从 SwiftUI 的 800ms 优化)
- **列表滚动**: 60 FPS 稳定帧率
- **内存使用**: 相比 SwiftUI 版本减少 30%
- **电池消耗**: 优化后台刷新和网络请求

### 6.2 兼容性
- **iOS 版本**: iOS 13.0+ (扩展兼容性)
- **设备支持**: iPhone 6s+ 和所有 iPad
- **语言**: 支持中文和英文

### 6.3 质量保证
- **单元测试覆盖率**: ≥ 80%
- **UI 测试**: 核心用户流程自动化测试
- **性能测试**: 定期 Instruments 分析
- **无障碍支持**: VoiceOver 和动态字体

---
## 7. Tech Stack Summary

### 7.1 当前技术栈 (SwiftUI)
- **UI**: SwiftUI
- **状态管理**: @State, @Published, ObservableObject
- **导航**: NavigationStack, NavigationLink
- **数据持久化**: UserDefaults
- **网络**: URLSession + Combine
- **通知**: UserNotifications

### 7.2 目标技术栈 (UIKit)
- **UI**: UIKit (UITableView, UICollectionView, Auto Layout)
- **状态管理**: Combine + Custom Binding
- **导航**: Coordinator Pattern + UINavigationController
- **数据持久化**: UserDefaults (保持不变)
- **网络**: URLSession + Combine (保持不变)
- **通知**: UserNotifications (保持不变)
- **架构**: MVVM-C (Model-View-ViewModel-Coordinator)

### 7.3 开发工具
- **性能分析**: Instruments (Time Profiler, Allocations)
- **调试**: Xcode Debugger, View Hierarchy
- **测试**: XCTest, XCUITest
- **版本控制**: Git with feature branches

---
## 8. 成功指标

### 8.1 技术指标
- [ ] 应用启动时间减少 ≥ 30%
- [ ] 内存使用减少 ≥ 25%
- [ ] 列表滚动性能提升 ≥ 40%
- [ ] 用户界面响应时间减少 ≥ 20%

### 8.2 用户体验指标
- [ ] 应用崩溃率 < 0.1%
- [ ] 用户满意度评分 ≥ 4.5/5
- [ ] 功能完整性 100% (无功能丢失)
- [ ] 向后兼容性 100%

---
💡 **维护规则**: 
- 将完成的任务打勾 ✅
- 正在进行的任务标记 🚧
- 需要新增功能时，在对应区块增行
- 每完成一个阶段，更新成功指标的进度

