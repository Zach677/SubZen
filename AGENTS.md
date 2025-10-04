# SubZen Repository Guidelines

## Project Overview
SubZen is a privacy-first subscription management app for iOS/macOS built with Swift and SwiftUI. The app helps users track subscription renewals, analyze spending, and detect hidden charges with privacy-first design (all data stays on device by default with no sign-up required).

## Project Structure & Module Organization
- **Workspace**: `SubZen.xcworkspace` contains all targets
- **Runtime Code** (`SubZen/`):
  - `Application/` - App lifecycle (SceneDelegate, MainController)
  - `Interface/` - SwiftUI views and UIKit controllers
    - `Components/` - Reusable SwiftUI components
    - `ViewController/` - UIKit view controllers
  - `Backend/` - Core services
    - `Subscription/` - Subscription CRUD and management
    - `Currency/` - Financial calculations and exchange rates
    - `Notification/` - Reminder and permission services
    - `Settings/` - App settings and reset functionality
  - `Extension/` - Platform-specific extensions
  - `BundledResources/` - Static payloads and assets
- **Shared Resources** (`Resources/`): Assets, localization, and DevKit scripts
- **Tests** (`SubZenTests/`): XCTest test suite with fixtures

## Architecture & Key Services
- **SubscriptionManager** (Backend/Subscription/) - Singleton managing subscription CRUD operations, persistence via UserDefaults
- **CurrencyTotalService** + **ExchangeRateService** - Handle financial summaries and currency conversion
- **NotificationPermissionService** + **SubscriptionNotificationService** - Manage reminder notifications
- **SettingsResetService** - Wipes local state
- **MainController** - Root view controller coordinating between SubscriptionController and Settings
- **Communication**: NotificationCenter for subscription updates (`.newSubCreated`, `.subscriptionUpdated`)

**Architecture Principles**:
- Inject dependencies from SceneDelegate or SwiftUI environment values
- Keep domain logic within existing services
- Fence Catalyst tweaks behind dedicated extensions
- Prefer value types for models, mark classes `final` unless inheritance required
- Route async work through service types

## Development Commands

### Essential Commands
- `open SubZen.xcworkspace` - Launch development workspace
- `xcodebuild -workspace SubZen.xcworkspace -scheme SubZen -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` - Headless build verification
- `xcodebuild -workspace SubZen.xcworkspace -scheme SubZen -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test` - Run test suite
- `make all` - Archive pipeline (requires clean git tree)
- `make clean` - Remove generated artifacts

### Development Scripts
- `Resources/DevKit/scripts/scan.license.sh` - Refresh license compliance report
- `Resources/DevKit/scripts/bump.version.sh` - Version management
- `Resources/DevKit/scripts/archive.all.sh` - Complete build and archive workflow

## Coding Standards

### Swift Style Guidelines
- Follow Swift API Design Guidelines
- 4-space indentation, braces on same line
- `PascalCase` for types, `camelCase` for members
- Use `// MARK:` dividers for code organization
- Extract helpers when files exceed ~150 lines
- Route async work through service types

### File Organization
- Name test files `<Feature>NameTests.swift`
- Mirror production namespaces in test structure
- Reuse fixtures from `SubZenTests/Support/`
- Group related functionality in extensions

## Testing & Quality Assurance

### Testing Strategy
- Use XCTest framework for all tests
- Run `xcodebuild … test` before opening PRs
- Capture coverage in Xcode (`Product ▸ Scheme ▸ Test with Coverage`)
- Document expected coverage dips in PR descriptions

### Test Organization
- Unit tests for service logic
- Integration tests for service interactions
- UI tests for critical user flows
- Reuse test fixtures to maintain consistency

## Commit & Pull Request Workflow

### Commit Guidelines
- Format: `<type>: <imperative summary>` (e.g., `fix: segmented color`, `feat: debug notificationcenter`)
- Group related changes per commit
- Avoid mixing formatting-only edits with logic changes
- Document migrations and breaking changes

### Pull Request Requirements
- **Summary**: Clear description of changes and motivation
- **Linked Issues**: Reference related issues or tickets
- **Visual Evidence**: Simulator or Catalyst screenshots for UI changes
- **Test Results**: Include `xcodebuild … test` command output
- **QA Notes**: Manual testing steps when automation is insufficient

## Security & Configuration

### Data Security
- Never commit personal finance data
- Store secrets in keychain or ignored `.xcconfig` files
- All user data remains on device by default
- Validate data sanitization in tests

### Build Configuration
- Regenerate derived data when modifying currency/notification assets
- Confirm `.gitignore` coverage before adding resources
- Use archive script for consistent signing and version management
- Maintain license compliance with regular scanning

### Platform Considerations
- Support both iOS and macOS via Catalyst
- Keep views platform-agnostic when possible
- Use dedicated extensions for platform-specific behavior
- Test on both platforms before release

## Agent Integration Guidelines

When working with AI agents in this repository:
- Reference existing service patterns rather than creating new singletons
- Follow established notification patterns for inter-component communication
- Maintain the privacy-first architecture by keeping data local
- Preserve the clean separation between UI, business logic, and data persistence
- Test changes on both iOS simulator and macOS Catalyst before committing

## MCP

Always use context when I need code generation, setup or configuration steps, or library/API documentation. This means you should automatically use the Context7 MCP tools to resolve library id and get library docs without me having to explicitly ask.

Use these known libraries in the following scopes:

- Swift: `/websites/developer_apple`
- Tuist: `/tuist/tuist`
- TCA: `/pointfreeco/swift-composable-architecture`
- Swift-Navigation: `/pointfreeco/swift-navigation`
- Fastlane: `/fastlane/docs`
