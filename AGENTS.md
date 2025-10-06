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

### Swift Code Style Guidelines

#### Core Style
- Indent with 4 spaces; keep opening braces on the same line as declarations
- Insert single spaces around operators and commas for readability
- Use PascalCase for types and camelCase for properties, methods, and variables
- Follow Swift API Design Guidelines for naming clarity

#### File Organization
- Keep files grouped logically within the existing directory structure
- Name files in PascalCase for types; append `+Feature` when adding extensions
- Introduce modular extensions rather than growing monolithic types
- Name test files as `<Feature>NameTests.swift` and mirror production namespaces
- Reuse fixtures from `SubZenTests/Support/` to avoid duplication

#### Modern Swift Features
- Prefer the `@Observable` macro over `ObservableObject`/`@Published`
- Embrace Swift concurrency (`async/await`, `Task`, `actor`, `@MainActor`) where appropriate
- Use result builders to express declarative APIs when they improve clarity
- Break long property wrapper declarations across multiple lines for readability
- Return `some Protocol` for opaque types when exposing constrained abstractions
- Route async work through service types to keep view models thin

#### Code Structure
- Favor early returns and `guard` statements to minimize nesting
- Keep each type or extension focused on a single responsibility
- Prefer value types; use `final` classes when references are required
- Organize larger files with `// MARK:` dividers and extract helpers once files exceed ~150 lines

#### Error Handling
- Model recoverable failures with typed `Result` values
- Propagate errors with `throws`/`try` and unwrap optionals with `guard let`/`if let`
- Define explicit error types for each domain and document invariants with comments when non-obvious

#### Architecture
- Avoid protocol-oriented patterns unless the additional abstraction delivers value
- Inject dependencies instead of introducing new singletons
- Prefer composition over inheritance; use factory or repository patterns for construction and persistence concerns

#### Third-Party Libraries
- Use SnapKit for Auto Layout constraints instead of bare `NSLayoutConstraint`
- Chain view configuration with `then` to improve readability in setup blocks
- Localize all user-facing strings with `String(localized:)`
- Run `make` at the project root to verify builds before sharing changes

#### Debug Assertions
- Guard developer-only invariants with `assert()` and mark unreachable paths with `assertionFailure()`
- Use `precondition()` when violating conditions should abort execution even in release builds

#### Memory Management
- Capture references as `weak` to break cycles; upgrade to `unowned` only when lifetime is guaranteed
- Provide explicit capture lists in closures and release resources in `deinit`

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
