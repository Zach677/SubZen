//
//  Refactor.md
//  
//
//  Created by Star on 2025/7/20.
//

# UIKit Subscription Management Refactor Guide

## Overview

This guide provides a complete UIKit refactor following FlowDown's proven architecture patterns. Instead of merging everything into MainController, we maintain clear separation of concerns with dedicated controllers for different responsibilities.

## Architecture Philosophy (Inspired by FlowDown)

### 1. **Layered Controller Architecture**
```
MainController (Root Navigation)
├── SubscriptionController (List Management)
├── SubscriptionEditorController (Single Item Edit/Create)
└── Other Feature Controllers
```

### 2. **Clear Responsibility Separation**
- **Manager Layer**: Pure data operations (`SubscriptionManager+CRUD.swift`)
- **List Controller**: Collection display and management (`SubscriptionController.swift`)
- **Editor Controller**: Individual item creation/editing (`SubscriptionEditorController.swift`)
- **Extension Files**: UI responsibility separation (`SubscriptionController+Actions.swift`)

## Implementation Strategy

### Phase 1: Backend Data Layer (Manager+CRUD Pattern)

### SubscriptionManager+CRUD.swift
```swift
//
//  SubscriptionManager+CRUD.swift
//  SubZen
//
//  Created by Star on 2025/7/20.
//

import Foundation

extension SubscriptionManager {
    
    // MARK: - Create
    func createSubscription(
        name: String,
        price: Decimal,
        cycle: BillingCycle,
        lastBillingDate: Date,
        currencyCode: String
    ) throws -> Subscription {
        let subscription = try Subscription(
            name: name,
            price: price,
            cycle: cycle,
            lastBillingDate: lastBillingDate,
            currencyCode: currencyCode
        )
        
        addSubscription(subscription)
        return subscription
    }
    
    // MARK: - Update
    func updateSubscription(
        _ subscription: Subscription,
        name: String? = nil,
        price: Decimal? = nil,
        cycle: BillingCycle? = nil,
        lastBillingDate: Date? = nil,
        currencyCode: String? = nil
    ) throws {
        var updatedSubscription = subscription
        
        if let name = name { updatedSubscription.name = name }
        if let price = price { updatedSubscription.price = price }
        if let cycle = cycle { updatedSubscription.cycle = cycle }
        if let lastBillingDate = lastBillingDate { updatedSubscription.lastBillingDate = lastBillingDate }
        if let currencyCode = currencyCode { updatedSubscription.currencyCode = currencyCode }
        
        // Update in storage
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index] = updatedSubscription
            saveSubscriptions()
        }
    }
    
    // MARK: - Delete
    func removeSubscription(withId id: UUID) {
        subscriptions.removeAll { $0.id == id }
        saveSubscriptions()
    }
    
    func removeSubscription(_ subscription: Subscription) {
        removeSubscription(withId: subscription.id)
    }
    
    // MARK: - Read Operations
    func subscription(withId id: UUID) -> Subscription? {
        return subscriptions.first { $0.id == id }
    }
    
    func subscriptions(for currency: String) -> [Subscription] {
        return subscriptions.filter { $0.currencyCode == currency }
    }
    
    func subscriptions(for cycle: BillingCycle) -> [Subscription] {
        return subscriptions.filter { $0.cycle == cycle }
    }
}
```

### Phase 2: Dedicated Editor Controller

### SubscriptionEditorController.swift

```swift
//
//  SubscriptionEditorController.swift
//  SubZen
//
//  Created by Star on 2025/7/20.
//

import UIKit

protocol SubscriptionEditorDelegate: AnyObject {
    func subscriptionEditor(_ editor: SubscriptionEditorController, didSave subscription: Subscription)
    func subscriptionEditor(_ editor: SubscriptionEditorController, didUpdate subscription: Subscription)
}

class SubscriptionEditorController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: SubscriptionEditorDelegate?
    private let subscriptionManager = SubscriptionManager.shared
    
    // Editor mode: create new or edit existing
    private let editingSubscription: Subscription?
    private var isEditMode: Bool { editingSubscription != nil }
    
    private var subscriptionName: String = ""
    private var price: Decimal? = nil
    private var cycle: BillingCycle = .monthly
    private var selectedCurrency: String = CurrencyList.allCurrencies.first?.code ?? "USD"
    private var lastBillingDate: Date = Date()
    
    // MARK: - UI Components
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // Name Section
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Subscription Name"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter subscription name"
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 16)
        textField.addTarget(self, action: #selector(nameTextFieldChanged), for: .editingChanged)
        return textField
    }()
    
    // Price Section
    private lazy var priceLabel: UILabel = {
        let label = UILabel()
        label.text = "Price"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private lazy var priceStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    
    private lazy var currencyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(CurrencyList.getSymbol(for: selectedCurrency), for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(currencyButtonTapped), for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 60).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()
    
    private lazy var priceTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "0.00"
        textField.keyboardType = .decimalPad
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 16)
        textField.addTarget(self, action: #selector(priceTextFieldChanged), for: .editingChanged)
        return textField
    }()
    
    // Billing Cycle Section
    private lazy var cycleLabel: UILabel = {
        let label = UILabel()
        label.text = "Billing Cycle"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private lazy var cycleSegmentedControl: UISegmentedControl = {
        let items = BillingCycle.allCases.map { $0.rawValue.capitalized }
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.selectedSegmentIndex = BillingCycle.allCases.firstIndex(of: cycle) ?? 0
        segmentedControl.addTarget(self, action: #selector(cycleChanged), for: .valueChanged)
        return segmentedControl
    }()
    
    // Date Section
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.text = "Last Billing Date"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.date = lastBillingDate
        datePicker.maximumDate = Date()
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        return datePicker
    }()
    
    // Save Button
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save Subscription", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.systemGray3, for: .disabled)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initializers
    
    init(subscription: Subscription? = nil) {
        self.editingSubscription = subscription
        super.init(nibName: nil, bundle: nil)
        
        // Pre-populate fields if editing
        if let subscription = subscription {
            subscriptionName = subscription.name
            price = subscription.price
            cycle = subscription.cycle
            selectedCurrency = subscription.currencyCode
            lastBillingDate = subscription.lastBillingDate
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupKeyboardHandling()
        updateSaveButtonState()
        updateUIForEditMode()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        title = isEditMode ? "Edit Subscription" : "Add Subscription"
        view.backgroundColor = .systemBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(containerStackView)
        
        // Setup price stack view
        priceStackView.addArrangedSubview(currencyButton)
        priceStackView.addArrangedSubview(priceTextField)
        
        // Add sections to main stack view
        let sections = [
            createSection(label: nameLabel, control: nameTextField),
            createSection(label: priceLabel, control: priceStackView),
            createSection(label: cycleLabel, control: cycleSegmentedControl),
            createSection(label: dateLabel, control: datePicker),
            saveButton
        ]
        
        sections.forEach { containerStackView.addArrangedSubview($0) }
    }
    
    private func createSection(label: UILabel, control: UIView) -> UIStackView {
        let sectionStack = UIStackView()
        sectionStack.axis = .vertical
        sectionStack.spacing = 8
        sectionStack.addArrangedSubview(label)
        sectionStack.addArrangedSubview(control)
        return sectionStack
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Container Stack View
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Keyboard Handling
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Actions
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func nameTextFieldChanged() {
        subscriptionName = nameTextField.text ?? ""
        updateSaveButtonState()
    }
    
    @objc private func priceTextFieldChanged() {
        guard let text = priceTextField.text, !text.isEmpty else {
            price = nil
            updateSaveButtonState()
            return
        }
        
        if let decimal = Decimal(string: text) {
            price = decimal
        } else {
            price = nil
        }
        updateSaveButtonState()
    }
    
    @objc private func currencyButtonTapped() {
        presentCurrencySelection()
    }
    
    @objc private func cycleChanged() {
        let selectedIndex = cycleSegmentedControl.selectedSegmentIndex
        if selectedIndex >= 0 && selectedIndex < BillingCycle.allCases.count {
            cycle = BillingCycle.allCases[selectedIndex]
        }
    }
    
    @objc private func dateChanged() {
        lastBillingDate = datePicker.date
    }
    
    @objc private func saveButtonTapped() {
        saveSubscription()
    }
    
    // MARK: - Private Methods
    
    private func updateSaveButtonState() {
        let isValid = !subscriptionName.trimmingCharacters(in: .whitespaces).isEmpty &&
                      price != nil &&
                      (price ?? 0) > 0
        
        saveButton.isEnabled = isValid
        saveButton.backgroundColor = isValid ? .systemBlue : .systemGray4
        
        UIView.animate(withDuration: 0.2) {
            self.saveButton.alpha = isValid ? 1.0 : 0.6
        }
    }
    
    private func presentCurrencySelection() {
        // Create a simple action sheet for currency selection
        let alertController = UIAlertController(
            title: "Select Currency",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        for currency in CurrencyList.allCurrencies {
            let action = UIAlertAction(
                title: "\(currency.code) (\(CurrencyList.getSymbol(for: currency.code)))",
                style: .default
            ) { [weak self] _ in
                self?.updateSelectedCurrency(currency.code)
            }
            
            if currency.code == selectedCurrency {
                action.setValue(true, forKey: "checked")
            }
            
            alertController.addAction(action)
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad support
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = currencyButton
            popover.sourceRect = currencyButton.bounds
        }
        
        present(alertController, animated: true)
    }
    
    private func updateSelectedCurrency(_ currencyCode: String) {
        selectedCurrency = currencyCode
        currencyButton.setTitle(CurrencyList.getSymbol(for: currencyCode), for: .normal)
    }
    
    private func updateUIForEditMode() {
        guard isEditMode else { return }
        
        // Pre-populate UI fields
        nameTextField.text = subscriptionName
        if let price = price {
            priceTextField.text = String(describing: price)
        }
        currencyButton.setTitle(CurrencyList.getSymbol(for: selectedCurrency), for: .normal)
        if let cycleIndex = BillingCycle.allCases.firstIndex(of: cycle) {
            cycleSegmentedControl.selectedSegmentIndex = cycleIndex
        }
        datePicker.date = lastBillingDate
        
        // Update save button text
        saveButton.setTitle(isEditMode ? "Update Subscription" : "Save Subscription", for: .normal)
    }
    
    private func saveSubscription() {
        let trimmedName = subscriptionName.trimmingCharacters(in: .whitespaces)
        
        do {
            if let existingSubscription = editingSubscription {
                // Update existing subscription
                try subscriptionManager.updateSubscription(
                    existingSubscription,
                    name: trimmedName,
                    price: price ?? 0.0,
                    cycle: cycle,
                    lastBillingDate: lastBillingDate,
                    currencyCode: selectedCurrency
                )
                
                // Get updated subscription for delegate
                if let updatedSubscription = subscriptionManager.subscription(withId: existingSubscription.id) {
                    delegate?.subscriptionEditor(self, didUpdate: updatedSubscription)
                }
            } else {
                // Create new subscription
                let newSubscription = try subscriptionManager.createSubscription(
                    name: trimmedName,
                    price: price ?? 0.0,
                    cycle: cycle,
                    lastBillingDate: lastBillingDate,
                    currencyCode: selectedCurrency
                )
                
                delegate?.subscriptionEditor(self, didSave: newSubscription)
            }
            
            dismiss(animated: true)
        } catch {
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
```

### Phase 3: UI Layer Integration

### SubscriptionController+Actions.swift

```swift
//
//  SubscriptionController+Actions.swift
//  SubZen
//
//  Updated by Star on 2025/7/20.
//

import UIKit

extension SubscriptionController {
    
    // MARK: - Action Methods (UI Layer)
    
    @objc func addButtonTapped() {
        presentSubscriptionEditor()
    }
    
    func presentSubscriptionEditor(for subscription: Subscription? = nil) {
        let editorController = SubscriptionEditorController(subscription: subscription)
        editorController.delegate = self
        
        let navigationController = UINavigationController(rootViewController: editorController)
        navigationController.modalPresentationStyle = .formSheet
        
        present(navigationController, animated: true)
    }
    
    // MARK: - Table View Actions
    
    func handleSubscriptionEdit(_ subscription: Subscription) {
        presentSubscriptionEditor(for: subscription)
    }
    
    func handleSubscriptionDelete(_ subscription: Subscription) {
        let alert = UIAlertController(
            title: "Delete Subscription",
            message: "Are you sure you want to delete \(subscription.name)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteSubscription(subscription)
        })
        
        present(alert, animated: true)
    }
    
    private func deleteSubscription(_ subscription: Subscription) {
        SubscriptionManager.shared.removeSubscription(subscription)
        refreshSubscriptionsList()
    }
    
    private func refreshSubscriptionsList() {
        // Reload table view or update UI
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

// MARK: - SubscriptionEditorDelegate

extension SubscriptionController: SubscriptionEditorDelegate {
    func subscriptionEditor(_ editor: SubscriptionEditorController, didSave subscription: Subscription) {
        refreshSubscriptionsList()
        print("Created subscription: \(subscription.name)")
    }
    
    func subscriptionEditor(_ editor: SubscriptionEditorController, didUpdate subscription: Subscription) {
        refreshSubscriptionsList()
        print("Updated subscription: \(subscription.name)")
    }
}
```

## Architecture Benefits (FlowDown-Inspired)

### 1. **Clear Separation of Concerns**
- **Manager Layer**: Pure business logic without UI dependencies
- **Controller Layer**: UI coordination and user interaction handling  
- **Editor Layer**: Dedicated controllers for specific tasks
- **Extension Files**: Organized by functionality, not just convenience

### 2. **Scalable Controller Architecture**
- Independent controllers for different responsibilities
- Easy to add new features without affecting existing code
- Clear data flow: UI → Controller → Manager → Storage

### 3. **Maintainable Code Organization**
```
Backend/Subscription/
├── SubscriptionManager.swift           # Core data management
├── SubscriptionManager+CRUD.swift      # Data operations
└── SubscriptionManager+Analytics.swift # Future: Statistics

Interface/ViewController/
├── SubscriptionController/
│   ├── SubscriptionController.swift        # List management
│   └── SubscriptionController+Actions.swift # UI actions
└── SubscriptionEditorController/
    └── SubscriptionEditorController.swift  # Single item editing
```

### 4. **FlowDown Architecture Patterns Applied**
- **Single Responsibility**: Each controller has one clear purpose
- **Delegate Communication**: Clean inter-controller communication
- **Manager Pattern**: Centralized data operations
- **Extension Organization**: Logical code separation

### 5. **Future-Proof Design**
- Easy to add new subscription operations
- Simple to implement additional UI screens
- Clear path for feature expansion
- Consistent with larger iOS app architectures

## Implementation Phases

### Phase 1: Backend Refactor
1. Create `SubscriptionManager+CRUD.swift`
2. Move all data operations from UI to Manager layer
3. Test data operations independently

### Phase 2: Editor Controller
1. Create `SubscriptionEditorController.swift`
2. Implement both create and edit functionality
3. Test editor in isolation

### Phase 3: Integration
1. Update `SubscriptionController+Actions.swift`
2. Wire up delegate communication
3. Remove old SwiftUI dependencies

### Phase 4: Future Enhancements
- Add `SubscriptionController+Search.swift` for search functionality
- Create `SubscriptionAnalyticsController.swift` for statistics
- Implement `SubscriptionController+Export.swift` for data export

## Key Advantages Over Monolithic Approach

✅ **Easier Testing**: Each component can be tested independently  
✅ **Better Collaboration**: Teams can work on different controllers simultaneously  
✅ **Simpler Debugging**: Issues are isolated to specific responsibility layers  
✅ **Faster Development**: New features don't require understanding entire codebase  
✅ **Cleaner Git History**: Changes are focused and easier to review

This architecture follows proven patterns from successful apps like FlowDown, ensuring long-term maintainability and team productivity.