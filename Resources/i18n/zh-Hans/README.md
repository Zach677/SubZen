# 素臻 (SubZen)

<p align="center">
  <a href="../../../README.md">English</a> |
  <a href="/Resources/i18n/zh-Hans/README.md">简体中文</a>
</p>

素臻 (SubZen) 是一款面向 iOS 的隐私优先订阅管理器，完全使用 UIKit 构建。它可以帮助你跟踪续订、看清钱花到哪里，并在隐形/隐蔽费用造成损失前及时发现。

<p align="center">
  <img src="../../../SubZen/Resources/Assets.xcassets/AppIcon.appiconset/subzen.png" width="160" alt="SubZen app icon" />
</p>

## 特色功能

- **隐私优先**：
  - **不收集数据**：不做遥测/分析，也不上传崩溃报告。
  - **本地存储**：订阅数据默认仅保存在你的设备上。
  - **最小网络请求**：仅从 Frankfurter（ECB）获取汇率并缓存；请求不包含任何个人信息。
- **续订提醒**：
  - 到期前的本地通知提醒。
- **消费洞察**：
  - 按类别汇总、趋势分析与按服务拆解。
  - 多货币总额（使用缓存汇率换算）。
- **隐性收费**：
  - 识别循环或可疑收费并标记异常。

## 特别说明

- 货币换算需要汇率数据（缓存 24 小时）。离线时会自动使用缓存汇率。
- 续订提醒为本地通知，需要在系统设置中授予通知权限。

## 参与贡献

请阅读 [CONTRIBUTING.md](../../../CONTRIBUTING.md)。

## 许可证

素臻以 AGPL-3.0 协议发布。完整许可文本见 [LICENSE](../../../LICENSE) 文件。

请注意，项目代码遵循开源许可，但 “SubZen/素臻” 的名称、图标及相关视觉资源为专有资产。如需商业授权，请与我联系。

---

© 2025 @Zach677 保留所有权利。
