# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SubZen is an iOS subscription management app written in Swift that helps users track their recurring subscriptions with multi-currency support and real-time exchange rate calculations. The app is built with modern UIKit architecture targeting iOS 16.0+.

## Architecture

- **Entry Point**: UIKit-based AppDelegate and SceneDelegate with programmatic UI setup
- **UI Framework**: Pure UIKit implementation with programmatic layout (Auto Layout)
- **Navigation**: UINavigationController-based navigation hierarchy
- **Data Management**: MVC pattern with traditional UIKit patterns
- **Data Persistence**: UserDefaults with JSON encoding/decoding for subscription data
- **Backend Services**: Currency conversion and exchange rate fetching
- **Dependencies**: Pure Apple frameworks (no third-party dependencies)
- **Compatibility**: iOS 16.0+ support, avoiding iOS 17+ exclusive APIs

## Claude Code Instructions

- If not explicitly asked to write code, avoid writing core business logic code
- Can assist with architectural planning, documentation, and high-level project guidance
- Focus on providing strategic insights and best practices when not directly coding

## Project Structure

```
SubZen/
├── Application/        # App lifecycle, AppDelegate, SceneDelegate
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
├── Backend/           # Business logic, models, and services
│   ├── Currency/
│   │   ├── CurrencyData.swift
│   │   ├── CurrencyTotalService.swift
│   │   ├── ExchangeRateModels.swift
│   │   └── ExchangeRateService.swift
│   ├── Notification/
│   │   └── NotificationPermissionService.swift
│   └── Subscription/
│       ├── Subscription.swift
│       ├── SubscriptionManager.swift
│       └── SubscriptionManager+CRUD.swift
├── Interface/
│   ├── ViewController/           # Controller hierarchy
│   │   ├── MainController/
│   │   │   └── MainController.swift
│   │   └── SubscriptionController/
│   │       ├── AddSubView.swift
│   │       ├── SubscriptionController+Actions.swift
│   │       ├── SubscriptionController.swift
│   │       └── SubscriptionEditorController.swift
│   └── Components/               # Reusable UI components
│       ├── Currency/
│       │   └── CurrencySelectionView.swift
│       ├── Subscription/
│       │   ├── EditSubscriptionView.swift
│       │   ├── SubscriptionCardView.swift
│       │   └── SubscriptionRowView.swift
│       └── SummaryView/
│           └── SubscriptionListView.swift
├── Extension/                   # UI utilities and extensions  
│   ├── UIView.swift
│   └── Withable.swift
├── Resources/                   # Assets, Info.plist
│   ├── Assets.xcassets/
│   ├── Base.lproj/
│   └── InfoPlist/
│       └── Info.plist
└── main.swift
```

## Key Components

### Subscription Management
- Billing cycles: Daily, Weekly, Monthly, Yearly
- Cost tracking with currency conversion
- Notification scheduling for renewal reminders

### Currency Support
- Multi-currency subscription tracking
- Real-time exchange rate fetching
- Automatic currency conversion between different subscription currencies

### UI Architecture
- Pure UIKit implementation with programmatic layout
- MVC pattern with Model, View, and Controller separation
- Auto Layout for responsive design across different screen sizes
- UITableView for list interfaces with custom cells

## Development Commands

### Building and Running
- Open `SubZen.xcworkspace` in Xcode
- Build and run using Xcode's standard build system (⌘+R)
- No external build tools or package managers required

### Version Management
- Use `Resources/DevKit/version_bump.sh` for version increments
- Archive script available at `Resources/DevKit/archive.sh`

## Code Conventions

### Swift Modern Patterns
- **Lazy Initialization**: Use `lazy` properties for expensive or one-time setup (like SceneDelegate.mainController)
- **Explicit Availability**: Use `@available(*, unavailable)` to disable unwanted initializers
- **Computed Properties**: Prefer computed properties with side effects for reactive updates
- **Strong Typing**: Explicit type declarations for UI components and data models

### Architecture Patterns

### Core MVC with FlowDown-Inspired Layering
- **MVC Pattern**: Classic Model-View-Controller architecture with clear separation of concerns
- **Layered Controller Architecture**: MainController → Feature Controllers → Editor Controllers
- **Manager Extensions**: Separate business logic using `Manager+Feature.swift` pattern
- **Weak Delegate Pattern**: Always use weak references in delegate protocols
- **Component Modularization**: One major UI component per directory (not just per file)
- **Protocol-Based Design**: Define clear protocols for component communication

### Controller Responsibility Separation (FlowDown Pattern)
- **List Controllers**: Handle collection display, search, filtering (e.g., `SubscriptionController`)
- **Editor Controllers**: Handle single item creation/editing (e.g., `SubscriptionEditorController`)
- **Manager Layer**: Pure business logic without UI dependencies (e.g., `SubscriptionManager+CRUD`)
- **Extension Files**: Organize by functionality, not convenience (e.g., `+Actions.swift`, `+Delegates.swift`)

### Data Flow Architecture
```
UI Action → Controller → Manager → Storage
         ← Delegate  ← Manager ← Storage
```
- Controllers never directly manipulate data storage
- Managers handle all business logic and data operations
- UI updates through delegate pattern or reactive bindings

### UI Implementation
- **Programmatic Layout**: Pure UIKit with Auto Layout constraints (consider SnapKit for complex layouts)
- **Declarative UI Setup**: Initialize UI components with inline configuration
- **Lifecycle Separation**: Clear separation between setup, constraints, and bindings
- **Memory Management**: Proper delegate and target-action cleanup

### Coding Style
- **English Comments**: Professional documentation following international standards
- **Descriptive Naming**: Clear, intention-revealing names for methods and properties
- **Async/Await Integration**: Modern concurrency patterns where appropriate
- **iOS 16.0+ Compatibility**: Avoid iOS 17+ exclusive APIs, use traditional UIKit patterns

## Data Models

- `Subscription`: Core model with name, cost, currency, billing cycle
- `Currency`: Enum for supported currencies with exchange rate support
- JSON encoding/decoding for UserDefaults persistence

## Key Features

- Subscription tracking with automatic renewal calculations
- Multi-currency support with live exchange rates
- Push notification permissions and scheduling
- Clean, modern UIKit interface with programmatic layout
- Persistent data storage without external databases

## UIKit Implementation Details

### FlowDown-Inspired Controller Architecture

#### Main Controllers
- `MainController`: Root navigation controller, coordinates high-level app flow
- `SubscriptionController`: List management, search, filtering of subscriptions
- `SubscriptionEditorController`: Single subscription creation and editing

#### Manager Layer (Business Logic)
- `SubscriptionManager`: Core subscription data management
- `SubscriptionManager+CRUD`: Create, read, update, delete operations  
- `SubscriptionManager+Analytics`: Statistics and reporting (future)
- `CurrencyManager+Conversion`: Exchange rate calculations

#### Extension Organization
- `SubscriptionController+Actions`: User interaction handling
- `SubscriptionController+Delegates`: Protocol conformance and callbacks
- `MainController+Layout`: View hierarchy and constraints

### Data Flow Patterns
- **Manager Layer**: Pure business logic, no UI dependencies
- **Controller Layer**: UI coordination, never direct data manipulation
- **Delegate Communication**: Clean inter-controller communication
- **Protocol-Based Updates**: UI updates through delegate pattern
- **Single Responsibility**: Each file has one clear purpose

### Modern Swift Implementation Examples

#### FlowDown-Style Manager Extension Pattern
```swift
// Backend/Subscription/SubscriptionManager+CRUD.swift
extension SubscriptionManager {
    func createSubscription(name: String, price: Decimal, cycle: BillingCycle) throws -> Subscription {
        let subscription = try Subscription(name: name, price: price, cycle: cycle)
        addSubscription(subscription)
        return subscription
    }
    
    func updateSubscription(_ subscription: Subscription, name: String? = nil) throws {
        // Pure business logic, no UI dependencies
    }
}
```

#### Controller Responsibility Separation
```swift
// Interface/ViewController/SubscriptionController/SubscriptionController.swift
class SubscriptionController: UIViewController {
    private let subscriptionManager = SubscriptionManager.shared // Manager reference
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI() // UI setup only
        loadSubscriptions() // Data loading
    }
}

// Interface/ViewController/SubscriptionController/SubscriptionController+Actions.swift
extension SubscriptionController {
    @objc func addButtonTapped() {
        presentSubscriptionEditor() // UI action handling
    }
    
    func presentSubscriptionEditor(for subscription: Subscription? = nil) {
        let editor = SubscriptionEditorController(subscription: subscription)
        editor.delegate = self
        present(UINavigationController(rootViewController: editor), animated: true)
    }
}
```

#### Delegate Communication Pattern
```swift
// Protocol-based communication (FlowDown style)
protocol SubscriptionEditorDelegate: AnyObject {
    func subscriptionEditor(_ editor: SubscriptionEditorController, didSave subscription: Subscription)
    func subscriptionEditor(_ editor: SubscriptionEditorController, didUpdate subscription: Subscription)
}

// Implementation with single responsibility
extension SubscriptionController: SubscriptionEditorDelegate {
    func subscriptionEditor(_ editor: SubscriptionEditorController, didSave subscription: Subscription) {
        refreshSubscriptionsList() // Only UI refresh, no business logic
    }
}
```

#### Initialization and Memory Management
```swift
// Lazy initialization for expensive operations
lazy var mainController = MainController()

// Explicit unavailable initializer
@available(*, unavailable)
required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
}

// Manager instance (FlowDown pattern)
private let subscriptionManager = SubscriptionManager.shared
```

### Compatibility Considerations
- **iOS 16.0+ Target**: Broad device compatibility with modern features
- **Traditional UIKit APIs**: Avoid iOS 17+ exclusive features like ContentUnavailableView
- **Custom Components**: Implement custom empty states, loading views, and transitions
- **Standard Patterns**: Reliable UITableView data source patterns over diffable data sources
- **Layout Flexibility**: Consider SnapKit for complex constraint scenarios while maintaining Auto Layout compatibility

### Component Architecture Guidelines

```swift
// MVC View Component (no business logic)
class SubscriptionCardView: UIView {
    weak var delegate: SubscriptionCardDelegate?

    lazy var titleLabel = UILabel().with {
        $0.font = .systemFont(ofSize: 16, weight: .medium)
    }

    // Clear lifecycle methods
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupActions()
    }

    // Update UI with data (called by Controller)
    func configure(with subscription: Subscription) {
        titleLabel.text = subscription.name
    }
}

// MVC Controller coordinates Model and View
class SubscriptionListController: UIViewController {
    private let subscriptionManager = SubscriptionManager() // Model
    private var subscriptionCards: [SubscriptionCardView] = [] // Views

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSubscriptions()
    }

    private func loadSubscriptions() {
        let subscriptions = subscriptionManager.getAllSubscriptions()
        updateUI(with: subscriptions)
    }
}
```

## FlowDown Architecture Best Practices

### Manager Layer Design
- **Single Responsibility**: Each Manager handles one domain (Subscription, Currency, Notification)
- **Extension Separation**: Use `Manager+Feature.swift` to separate concerns
- **No UI Dependencies**: Managers should never import UIKit or reference UI elements
- **Data Consistency**: All data mutations go through Manager layer

### Controller Organization
- **Feature Controllers**: One controller per major feature (list, editor, settings)
- **Extension Files**: Separate by functionality (`+Actions.swift`, `+Delegates.swift`, `+Layout.swift`)
- **Clear Hierarchy**: MainController → Feature Controllers → Modal Controllers
- **Delegate Communication**: Use protocols for inter-controller communication

### File Naming Conventions (FlowDown Style)
```
Manager Layer:
- SubscriptionManager.swift           # Core functionality
- SubscriptionManager+CRUD.swift      # Data operations  
- SubscriptionManager+Analytics.swift # Additional features

Controller Layer:
- SubscriptionController.swift        # Main controller
- SubscriptionController+Actions.swift # User interactions
- SubscriptionController+Delegates.swift # Protocol conformance

Editor Layer:  
- SubscriptionEditorController.swift  # Single responsibility editing
```

### Code Organization Principles
- **One Responsibility Per File**: Each file should have a single, clear purpose
- **Logical Grouping**: Related functionality in same directory
- **Extension Hierarchy**: Main class in base file, extensions in separate files
- **Import Minimization**: Only import what's needed in each file

## Development Best Practices

### Memory Management
- Use `weak` references in delegates and closures to prevent retain cycles
- Properly manage Combine cancellables with `Set<AnyCancellable>`
- Implement proper `deinit` methods for cleanup

### Error Handling
- Use Result types for asynchronous operations
- Implement user-friendly error messages
- Handle network and data parsing errors gracefully

### Performance Optimization
- Lazy load expensive UI components
- Use proper cell reuse patterns
- Minimize main thread blocking operations

### Architecture Validation
- Controllers should never directly access storage
- Managers should be UI-agnostic and testable
- Each extension file should have a clear purpose
- Delegate protocols should be specific and minimal

## Xcode Build Configurations

- Xcode build always use 16 pro

## Development Commands

- Run the command:"swiftformat . --swiftversion 6.0 --indent 4" When changed code

## Architecture Summary

SubZen follows a **FlowDown-inspired layered architecture** that prioritizes:

1. **Clear Separation**: Business logic (Managers) completely separated from UI (Controllers)
2. **Single Responsibility**: Each file and class has one clear purpose
3. **Scalable Organization**: Easy to add new features without affecting existing code
4. **Testable Design**: Pure business logic can be tested independently
5. **Team Collaboration**: Multiple developers can work on different layers simultaneously

This architecture ensures SubZen remains maintainable as it grows, following patterns proven in successful commercial iOS applications.