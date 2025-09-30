# Repository Guidelines

## Project Structure & Module Organization
Open `SubZen.xcworkspace` to load all targets. Runtime code lives in `SubZen/`, split into `Application/` (app lifecycle), `Interface/` (SwiftUI), `Backend/` (currency, subscription, notification, settings services), and `BundledResources/` (static payloads). Shared assets, localization, and DevKit scripts sit in `Resources/`. Tests live in `SubZenTests/` with fixtures in `SubZenTests/Support/`.

## Architecture & Key Services
Keep domain logic inside the existing services: `SubscriptionManager` drives CRUD and scheduling, `CurrencyTotalService` + `ExchangeRateService` handle financial summaries, `NotificationPermissionService` manages reminders, and `SettingsResetService` wipes local state. Inject dependencies from `SceneDelegate` or SwiftUI environment values instead of inventing new singletons. Fence Catalyst tweaks behind dedicated extensions so views remain platform-agnostic.

## Build, Test, and Development Commands
- `open SubZen.xcworkspace` — launch the shared schemes.
- `xcodebuild -workspace SubZen.xcworkspace -scheme SubZen -destination 'platform=iOS Simulator,name=iPhone 15' build` — headless smoke build.
- `xcodebuild -workspace SubZen.xcworkspace -scheme SubZen -destination 'platform=iOS Simulator,name=iPhone 15' test` — run XCTest.
- `make all` — run the archive pipeline (requires clean git tree, emits `.xcarchive` bundles in `.build/`).
- `make clean` — drop generated artifacts.
- `Resources/DevKit/scripts/scan.license.sh` — refresh the license report; pair with `xcbeautify -qq` for cleaner logs.

## Coding Style & Naming Conventions
Follow Swift API Design Guidelines: 4-space indentation, braces on the same line, `PascalCase` types, `camelCase` members. Use `// MARK:` dividers and extract helpers once files exceed ~150 lines. Prefer value types for models, mark classes `final` unless inheritance is required, and route async work through service types.

## Testing Guidelines
Tests use XCTest. Name files `<Feature>NameTests.swift`, mirror production namespaces, and reuse fixtures in `SubZenTests/Support/`. Run `xcodebuild … test` before opening a PR and capture coverage in Xcode (`Product ▸ Scheme ▸ Test with Coverage`). Note any expected coverage dips in the PR description.

## Commit & Pull Request Guidelines
Commit subjects follow `<type>: <imperative summary>` (e.g., `fix: segmented color`). Group related changes per commit, avoid mixing formatting-only edits with logic, and document migrations. PRs should include a summary, linked issues, simulator or Catalyst screenshots for UI tweaks, the test command run, and manual QA notes when automation is missing.

## Security & Configuration Tips
Never commit personal finance data. Keep secrets in the keychain or ignored `.xcconfig` files. When touching currency or notification assets, rerun the relevant DevKit helper to regenerate derived data. Confirm `.gitignore` coverage before adding resources and stick to the archive script so signing and version bumps stay consistent.
