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

- Swift coding standards with clear naming conventions
- Mixed Chinese/English comments (consider localization context)
- Async/await patterns for asynchronous operations
- MVVM architecture with clear separation between ViewModels, ViewControllers, and Services
- Programmatic UI with Auto Layout constraints
- Delegate pattern for data flow and user interactions
- iOS 16.0+ compatibility - avoid using iOS 17+ exclusive APIs

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
- ViewModel classes handle business logic and data management
- Delegate protocols for communication between view controllers
- Combine framework for reactive data updates
- Traditional UITableViewDataSource and UITableViewDelegate patterns

### Compatibility Considerations
- Target iOS 16.0+ for broad device compatibility
- Use traditional UIKit APIs instead of iOS 17+ exclusive features
- Implement custom empty state views instead of ContentUnavailableView
- Use standard UITableView data source patterns for reliability