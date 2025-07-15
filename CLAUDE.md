# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SubZen is an iOS subscription management app written in Swift that helps users track their recurring subscriptions with multi-currency support and real-time exchange rate calculations. The app is built with modern UIKit architecture targeting iOS 16.0+.

## Architecture

- **Entry Point**: UIKit-based AppDelegate and SceneDelegate with programmatic UI setup
- **UI Framework**: Pure UIKit implementation with programmatic layout (Auto Layout)
- **Navigation**: UINavigationController-based navigation hierarchy
- **Data Management**: ViewModel pattern with Combine for reactive updates
- **Data Persistence**: UserDefaults with JSON encoding/decoding for subscription data
- **Backend Services**: Currency conversion and exchange rate fetching
- **Dependencies**: Pure Apple frameworks (no third-party dependencies)
- **Compatibility**: iOS 16.0+ support, avoiding iOS 17+ exclusive APIs

## Project Structure

```
SubZen/
├── Application/        # App lifecycle, AppDelegate, SceneDelegate
├── Backend/           # Business logic, models, and services
│   ├── Models/        # Data models (Subscription, Currency, etc.)
│   └── Services/      # Currency conversion, exchange rates
├── Interface/         # UIKit view controllers and UI components
│   ├── ViewControllers/ # Main view controllers
│   │   ├── Base/      # BaseViewController and common components
│   │   ├── SubscriptionList/  # Main list functionality
│   │   ├── AddSubscription/   # Add subscription flow
│   │   └── EditSubscription/  # Edit subscription flow
│   ├── Components/    # Reusable UI components (one component per directory)
│   │   ├── SubscriptionCard/
│   │   ├── CurrencySelector/
│   │   └── FormFields/
│   ├── Views/         # Custom UIView components
│   └── Cells/         # UITableViewCell and UICollectionViewCell
└── Resources/         # Assets, Info.plist, launch resources

Resources/DevKit/      # Development scripts (outside main app bundle)
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
- MVVM pattern with ViewModel and View Controller separation
- Auto Layout for responsive design across different screen sizes
- UITableView for list interfaces with custom cells

## Development Commands

### Building and Running
- Open `SubZen.xcodeproj` in Xcode
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
- **MVVM + Combine**: ViewModels with reactive updates using Combine framework
- **Weak Delegate Pattern**: Always use weak references in delegate protocols
- **Component Modularization**: One major UI component per directory (not just per file)
- **Protocol-Based Design**: Define clear protocols for component communication

### UI Implementation
- **Programmatic Layout**: Pure UIKit with Auto Layout constraints (consider SnapKit for complex layouts)
- **Declarative UI Setup**: Initialize UI components with inline configuration
- **Lifecycle Separation**: Clear separation between setup, constraints, and bindings
- **Memory Management**: Proper cancellable management for Combine subscriptions

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

### View Controllers
- `SubscriptionListViewController`: Main list interface using UITableView
- `AddSubscriptionViewController`: Form-based subscription creation
- `EditSubscriptionViewController`: Subscription editing interface
- `CurrencySelectionViewController`: Currency picker interface

### Data Flow
- **Reactive ViewModels**: Use Combine publishers for state management and data updates
- **Weak Delegate Protocols**: Communication between view controllers with proper memory management
- **Computed Properties**: React to state changes with side effects (like UI updates)
- **Publisher Chaining**: Connect multiple data sources using Combine operators
- **Traditional UIKit Patterns**: UITableViewDataSource/Delegate for reliable table management

### Modern Swift Implementation Examples

```swift
// Lazy initialization pattern (like SceneDelegate)
lazy var mainController = MainController()

// Explicit unavailable initializer
@available(*, unavailable)
required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
}

// Computed property with side effects
var selectedSubscription: Subscription? {
    didSet {
        updateUIForSelection()
    }
}

// Weak delegate pattern
weak var delegate: SubscriptionListDelegate?

// Combine subscription management
private var cancellables = Set<AnyCancellable>()
```

### Compatibility Considerations
- **iOS 16.0+ Target**: Broad device compatibility with modern features
- **Traditional UIKit APIs**: Avoid iOS 17+ exclusive features like ContentUnavailableView
- **Custom Components**: Implement custom empty states, loading views, and transitions
- **Standard Patterns**: Reliable UITableView data source patterns over diffable data sources
- **Layout Flexibility**: Consider SnapKit for complex constraint scenarios while maintaining Auto Layout compatibility

### Component Architecture Guidelines

```swift
// Component-based organization
class SubscriptionCardComponent: UIView {
    weak var delegate: SubscriptionCardDelegate?
    
    lazy var titleLabel = UILabel().with {
        $0.font = .systemFont(ofSize: 16, weight: .medium)
    }
    
    // Clear lifecycle methods
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupBindings()
    }
}
```

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