# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Documentation

For comprehensive repository guidelines, development commands, coding standards, and project architecture, please refer to the **[AGENTS.md](./AGENTS.md)** file.

The AGENTS.md file contains detailed information about:
- Project structure and module organization
- Architecture principles and key services
- Development commands and scripts
- Coding standards and testing guidelines
- Commit and PR workflows
- Security and configuration best practices
- Agent integration guidelines

## Quick Reference

**Essential Commands:**
- `open SubZen.xcworkspace` - Launch development workspace
- `xcodebuild -workspace SubZen.xcworkspace -scheme SubZen -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` - Build verification
- `xcodebuild -workspace SubZen.xcworkspace -scheme SubZen -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test` - Run tests
- `make all` - Archive pipeline

**Key Services:**
- `SubscriptionManager` - Subscription CRUD and persistence
- `CurrencyTotalService` + `ExchangeRateService` - Financial calculations
- `NotificationPermissionService` + `SubscriptionNotificationService` - Reminders
- `SettingsResetService` - Local state management

## MCP

Always use context when I need code generation, setup or configuration steps, or library/API documentation. This means you should automatically use the Context7 MCP tools to resolve library id and get library docs without me having to explicitly ask.

Use these known libraries in the following scopes:

- Swift: `/websites/developer_apple`
- Tuist: `/tuist/tuist`
- TCA: `/pointfreeco/swift-composable-architecture`
- Swift-Navigation: `/pointfreeco/swift-navigation`
- Fastlane: `/fastlane/docs`

For complete documentation, see [AGENTS.md](./AGENTS.md).
