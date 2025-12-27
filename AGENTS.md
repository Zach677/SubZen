---
trigger: always_on
---

# SubZen Repository Guidelines

## Project Overview
SubZen is a privacy-first subscription manager for iOS and macOS Catalyst built entirely with UIKit. The app helps users track subscription renewals, analyze spending, and detect hidden charges while keeping data on-device by default (no sign-up required).

## Project Structure & Module Organization
- **Workspace**: `SubZen.xcworkspace` hosts all app and test targets.
- **Runtime Code** (`SubZen/`):
  - `Application/` – App lifecycle (`AppDelegate`, `SceneDelegate`).
  - `Interface/` – UIKit presentation layer.
    - `Components/` – Reusable `UIView` subclasses, table cells, and helper views composed with SnapKit and the `with` convenience helpers.
    - `ViewController/` – Feature coordinators (`MainController`, `SubscriptionController`, `SettingController`, currency flows).
  - `Backend/` – Domain services and data models.
    - `Subscription/` – Subscription model plus CRUD/persistence (`SubscriptionManager`).
    - `Currency/` – Currency metadata, totals, and exchange rate services.
    - `Notification/` – Notification permission + scheduling services.
    - `Settings/` – Reset and wipe flows.
  - `Extension/` – UIKit/Swift helpers shared across modules.
  - `BundledResources/` – Static payloads and assets bundled inside the app.
- **Shared Resources** (`Resources/`) – Localized strings, assets, and DevKit scripts.
- **Tests** (`SubZenTests/`) – XCTest targets with fixtures under `Support/`.

## Architecture & Key Services
- **MainController** (Interface/ViewController) – Container that hosts the subscription list and settings drawer.
- **SubscriptionController** – Coordinates subscription CRUD, table presentation, and detail editing.
- **SettingController** – Manages settings UI and integrates reset + notification preferences.
- **SubscriptionManager** – Singleton persistence layer that stores subscription data in `UserDefaults` and emits notifications (`.newSubCreated`, `.subscriptionUpdated`).
- **NotificationPermissionService** + **SubscriptionNotificationService/Manager** – Request permissions, schedule reminders, and manage lifecycle.
- **SettingsResetService** – Clears local state and posts `.settingsDidReset`.

**Architecture Principles**
- Keep UIKit-first composition: favor `UIViewController` containment and `UIView` composition instead of SwiftUI.
- Inject dependencies through controller initializers or dedicated service initializers; avoid introducing new static singletons.
- Keep domain logic inside service types; keep view controllers focused on presentation and coordination.
- Use NotificationCenter with existing names for cross-feature communication. Document new notifications before broadcasting them.
- Prefer value types for models; mark classes `final` unless subclassing is required.
- Route async work (`Task`, `async/await`) through services instead of running it in view layers.
- Fence Catalyst-only tweaks behind platform checks or dedicated extensions.

## Development Commands

### Essential Commands
- `open SubZen.xcworkspace` – Launch the Xcode workspace.
- `xcodebuild -workspace SubZen.xcworkspace -scheme SubZen -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` – Headless build verification.
- `xcodebuild -workspace SubZen.xcworkspace -scheme SubZen -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test` – Run the XCTest suite.
- `make all` – Archive pipeline (requires a clean git tree).
- `make clean` – Remove generated artifacts.

### Code Formatting
- `swiftformat . --swiftversion 6.0 --indent 4` – Format all Swift files with consistent style.
- **IMPORTANT**: Run this command after completing any code changes to maintain consistent code style across the codebase.

### Development Scripts
- `Resources/DevKit/scripts/scan.license.sh` – Refresh license compliance report.
- `Resources/DevKit/scripts/bump.version.sh` – Version management.
- `Resources/DevKit/scripts/archive.all.sh` – Complete build and archive workflow.

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

### Strategy
- Unit tests for service logic and data validation.
- Integration tests for service collaboration (e.g., notification scheduling).
- UI tests for critical flows (subscription CRUD, settings reset) when feasible.

### Execution
- Use XCTest with the existing schemes.
- Reset shared state (`UserDefaults`, caches, notification center) between tests.
- Document expected coverage gaps in PR descriptions.

## Commit & Pull Request Workflow
- Commit format: `<type>: <imperative summary>` (e.g., `fix: adjust notification scheduling`).
- Keep formatting-only changes separate from logic changes.
- Reference related issues or tickets in PR descriptions.
- Provide simulator or Catalyst screenshots for UI changes.
- Include `xcodebuild … test` output and brief manual QA notes when automation is insufficient.

## Security & Configuration
- Never commit user subscription data or secrets.
- Store secrets in the keychain or ignored `.xcconfig` files.
- Regenerate derived data when modifying bundled currency/notification assets.
- Maintain license compliance via the DevKit scripts.

## Platform Considerations
- Minimum deployment target: iOS 17.0+ across all new code paths (match Catalyst baselines accordingly).
- Support both iOS and macOS Catalyst from the same UIKit codebase.
- Keep components platform-neutral; isolate Catalyst-specific deltas in extensions.
- Test critical flows on both platforms before release.

## Agent Integration Guidelines
- Follow existing controller/service boundaries; avoid creating new singleton entry points.
- Reference the established notification names when broadcasting changes.
- Preserve privacy-first design by keeping all data local and avoiding network calls outside existing services.
- Coordinate with the `Withable` helpers and SnapKit patterns when generating new components.
- Prefer incremental refactors with test coverage instead of sweeping rewrites.
- **CRITICAL**: After completing any code changes, ALWAYS run `swiftformat . --swiftversion 6.0 --indent 4` to format the code before finishing the task.

## MCP
Always fetch context via Context7 when you need code generation, setup instructions, or framework documentation.

Use these library IDs with Context7:
- Swift / UIKit / Combine: `/websites/developer_apple`
- Tuist: `/tuist/tuist`
- TCA: `/pointfreeco/swift-composable-architecture`
- Swift Navigation: `/pointfreeco/swift-navigation`
- Fastlane: `/fastlane/docs`
