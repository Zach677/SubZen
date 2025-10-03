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
- `xcodebuild -workspace SubZen.xcworkspace -scheme SubZen -destination 'platform=iOS Simulator,name=iPhone 15' build` - Build verification
- `xcodebuild -workspace SubZen.xcworkspace -scheme SubZen -destination 'platform=iOS Simulator,name=iPhone 15' test` - Run tests
- `make all` - Archive pipeline

**Key Services:**
- `SubscriptionManager` - Subscription CRUD and persistence
- `CurrencyTotalService` + `ExchangeRateService` - Financial calculations
- `NotificationPermissionService` + `SubscriptionNotificationService` - Reminders
- `SettingsResetService` - Local state management

For complete documentation, see [AGENTS.md](./AGENTS.md).