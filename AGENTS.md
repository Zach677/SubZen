---
trigger: always_on
---

# SubZen Agent Guide

This file provides guidance to AI coding agents working inside this repository.

## Overview

SubZen is a privacy-first subscription manager for iOS built entirely with UIKit. The app helps users track subscription renewals, analyze spending, and while keeping data on-device by default (no sign-up required).

- All code text (UI strings, comments, logs) must remain in English.

## Platform Requirements & Dependencies

- Target platforms reflect framework minimums: iOS 17.0+
- Toolchain: Swift 6.0 (`swift-tools-version: 6.0`) and the Xcode 26 SDK line are required.
- Core SwiftPM dependencies include SnapKit, GlyphixTextFx and additional UI/tooling libraries listed in `SubZen.xcodeproj`.

## Project Structure

- `SubZen.xcworkspace`: Entry point with app and frameworks.
- **Runtime Code** (`SubZen/`):
  - `Application/` – App lifecycle (`AppDelegate`, `SceneDelegate`).
  - `DerivedSources/` – Auto-generated build metadata (do not edit manually).
  - `Interface/` – UIKit presentation layer.
    - `Components/` – Reusable `UIView` subclasses, table cells, and helper views composed with SnapKit and the `with` convenience helpers.
    - `ViewController/` – Feature coordinators (`MainController`, `SubscriptionController`, `SettingController`, currency flows).
  - `Backend/` – Domain services and data models.
    - `Subscription/` – Subscription model plus CRUD/persistence (`SubscriptionManager`).
    - `Currency/` – Currency metadata, totals, and exchange rate services (`CurrencyRateService`).
    - `Notification/` – Notification permission + scheduling services.
    - `Settings/` – Reset and wipe flows.
  - `Extension/` – UIKit/Swift helpers shared across modules.
  - `Resources/` – App assets and localization (`Localizable.xcstrings`, `Assets.xcassets`, `LaunchScreen.storyboard`, Info.plist).
  - `BundledResources/` – In-app documents (privacy policy, open source licenses).
  - `Preview Content/` – Preview assets for Xcode.
- **Shared Resources** (`Resources/`) – DevKit scripts, i18n docs, and privacy-related documents.
- **Tests** (`SubZenTests/`) – XCTest targets with fixtures under `Support/`.

## Build & Run Commands

- Open the workspace: `open SubZen.xcworkspace`.
- Debug builds:
  - iOS: `xcodebuild -workspace SubZen.xcworkspace -scheme SubZen -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' | xcbeautify -qq`
- Release archive (iOS):
  - `make` to archive (runs `Resources/DevKit/scripts/archive.all.sh`)
  - `make clean` to reset build artifacts
- When running CI-style builds, prefer `xcodebuild -workspace SubZen.xcworkspace -scheme SubZen -configuration Debug build`
- Archive script automatically commits changes and bumps version before building; ensure the working tree is clean beforehand.
- Run unit tests (`SubZenTests`): `xcodebuild -workspace SubZen.xcworkspace -scheme SubZen -configuration Debug test | xcbeautify -qq`
- Localization validation helpers:
  - `python3 Resources/DevKit/scripts/check_translations.py SubZen/Resources/Localizable.xcstrings`
  - `python3 Resources/DevKit/scripts/check_untranslated.py SubZen/Resources/Localizable.xcstrings`
  - `python3 Resources/DevKit/scripts/update_missing_i18n.py SubZen/Resources/Localizable.xcstrings` to scaffold missing locales; extend `NEW_STRINGS` in that script when adding new keys.

## Engineering Principles

- **No Excessive Backward Compatibility**: This is a solo developer project with a small user base. Avoid writing complex migration shims or maintaining multiple data format versions. When data models change, prefer clean breaks over compatibility layers—old data can be discarded or users can re-enter it. Keep Codable implementations simple without legacy format fallbacks.
- **No Legacy Code/Data Retention**: Don’t keep commented-out code, unused code paths, or compatibility shims “just in case.” When a refactor needs a clean break, delete the old implementation and reset persisted on-device data rather than carrying legacy forward.
- **Avoid Defensive Programming**: Don’t add guards for impossible states or redundant nil/error checks “just in case.” Prefer asserting invariants (`assert`/`precondition`) for programmer errors; only validate truly external inputs (user input, disk, notifications, system APIs).

## Shell Script Style

### Core Principles

- **Simplicity**: Keep scripts minimal and focused
- **No unnecessary complexity**: Avoid features that aren't needed
- **Visual clarity**: Use line breaks for readability
- **Failure handling**: Use `set -euo pipefail`
- **Use shebang for scripts**: Use `#!/bin/zsh`

### Output Guidelines

- Use `[+]` for successful operations
- Use `[-]` for failed operations (when needed)
- Keep echo messages lowercase
- Simple status messages: "building...", "completed successfully"

### Code Style

- Minimal comments - focus on self-evident code
- No unnecessary color output or visual fluff
- Line breaks for long command chains
- Assume required tools are available (e.g., xcbeautify)
- Don't add if checks when pipefail handles failures

## Development Guidelines

### Swift Style

- 4-space indentation with opening braces on the same line
- Single spaces around operators and after commas
- PascalCase types; camelCase properties, methods, and file names
- Organize extensions into targeted files (`Type+Feature.swift`) and keep each file focused on one responsibility
- Lean on modern Swift patterns: `@Observable`, structured concurrency (`async`/`await`), result builders, and protocol-oriented design

### Architecture & Key Services

- Respect the established managers: `SubscriptionManager`, `SubscriptionNotificationManager`, `NotificationPermissionService`, and `SettingsResetService`. Consult them before adding new singletons.
- Compose features via dependency injection and protocols instead of inheritance.
- Backend services are organized by domain: `Subscription`, `Currency`, `Notification`, `Settings`.
- `SceneDelegate.swift` wires the root UI (`MainController`). Keep this order intact to avoid race conditions.
- `UserDefaults` powers persisted user settings—keep keys centralized and publish updates via `NotificationCenter` when UI needs to refresh.

## Testing Expectations

- Add or update unit/UI tests alongside behavioural changes. `SubZenTests` uses XCTest—author tests as `func testFeatureScenario_expectation() throws`.
- Run app-level tests with `xcodebuild -workspace SubZen.xcworkspace -scheme SubZen -configuration Debug test | xcbeautify -qq`.
- Document manual verification steps whenever UI or integration flows lack automation.

## Security & Privacy

- Never hardcode secrets; rely on user-supplied keys and platform keychains.
- Validate new managers or services against the sanctioned singleton list above.
- Use `assert`/`precondition` to capture invariants during development.
- Audit persistence changes for privacy impacts before shipping.
- Preserve privacy-first defaults: no telemetry/analytics, keep network usage minimal, and keep subscription data on-device.

## Documentation & Knowledge Sharing

- Capture key findings from external research in PR descriptions so future contributors can trace decisions.
- Reference official docs, WWDC sessions, or sample projects when introducing new APIs.
- Keep architectural rationale and trade-offs close to the code (doc comments or dedicated markdown) when complexity grows.
- Call out changes to generated assets or DevKit scripts (`SubZen/DerivedSources`, `Resources/DevKit/scripts/`) in PR summaries so reviewers can trace automation impacts.

## Collaboration Workflow

- Craft concise, capitalized commit subjects (e.g., `Adjust Compiler Settings`) and use bodies to explain decisions or link issues (`#123`).
- Group related work per commit and avoid bundling unrelated refactors.
- Pull requests must include a summary, testing checklist, and before/after visuals for UI changes. Mention localization or asset updates when relevant.
- Tag reviewers responsible for the affected modules and outline any follow-up tasks or risks.

## Localization Guidelines

- Prefer APIs that accept `String.LocalizationValue`; pass localization values directly for consistency
- Other UI entry points should continue using `String(localized: ...)` for user-facing strings
- Source all user-visible strings from localization files instead of hardcoded literals

### Dynamic values (avoid missed translations)

When a localized string includes runtime values (counts, sizes, etc.), do NOT build the key as a `String` via interpolation.

- Bad (produces a runtime `String` key like "3 chances" and will NOT match entries like "%lld chances"):
  - `String(localized: "\(value) chances")`
- Good (ensures a `String.LocalizationValue` is produced, so it matches the formatted key in `.xcstrings`):
  - `let key: String.LocalizationValue = "\(value) chances"`
  - `String(localized: key)`

Prefer `String.LocalizationValue`/`LocalizedStringResource` formatting over `String(format:)` in app code. Use `String(format:)` only when needed for compatibility.

- Main app localization files:
  - `SubZen/Resources/Localizable.xcstrings`: Main app UI strings
  - `SubZen/Resources/InfoPlist/Info.plist`: Info.plist localization strings
- We ship multiple locales (en base plus de, es, fr, ja, ko, zh-Hans); keep all locales populated when adding or updating strings—do not leave only English/Chinese
- **IMPORTANT**: When adding new strings, you MUST provide translations for ALL supported languages (de, es, fr, ja, ko, zh-Hans) in `NEW_STRINGS`. Never add strings with only partial translations.
- **IMPORTANT**: When adding new strings, you MUST provide translations for ALL supported languages (de, es, fr, ja, ko, zh-Hans) in `NEW_STRINGS`. Never add strings with only partial translations.
- Use the provided scripts to manage translations:
  - `python3 Resources/DevKit/scripts/update_missing_i18n.py SubZen/Resources/Localizable.xcstrings` to scaffold new keys (extend `NEW_STRINGS` dict in the script as required)
  - `python3 Resources/DevKit/scripts/translate_missing.py SubZen/Resources/Localizable.xcstrings` to apply curated zh-Hans translations
  - `python3 Resources/DevKit/scripts/check_untranslated.py SubZen/Resources/Localizable.xcstrings` to surface untranslated entries (missing or empty) across ALL languages
  - `python3 Resources/DevKit/scripts/check_translations.py SubZen/Resources/Localizable.xcstrings` to remove stale keys and verify completeness across all locales
- Script usage notes:
  - `update_missing_i18n.py`: Add translations for ALL languages to `NEW_STRINGS` dict before running; the script merges them into xcstrings. Format: `{"Key": {"de": "...", "es": "...", "fr": "...", "ja": "...", "ko": "...", "zh-Hans": "..."}}`
  - `check_untranslated.py`: Reports strings missing translations in ANY supported language (not just zh-Hans)
  - `check_translations.py`: Use this to find strings missing translations in any locale (missing, empty, or non-translated state)
- Localization files such as `Localizable.xcstrings` exceed 10k lines; update the supporting Python scripts to regenerate changes instead of editing the JSON directly.
- Follow existing localization patterns and maintain consistency with the codebase. Avoid manual edits to `.xcstrings`; let scripts manage JSON structure.
