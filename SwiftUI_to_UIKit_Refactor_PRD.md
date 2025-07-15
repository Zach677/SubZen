# SubZen SwiftUI到UIKit重构PRD
*产品需求文档 - 详细重构指导*

## 概述

本文档提供SubZen应用从SwiftUI到现代化UIKit的完整重构指南，目标是建立一个简洁高效、兼容iOS 16.0+的纯UIKit应用。

## 重构目标

### 主要目标
- **完全UIKit化**: 移除所有SwiftUI依赖，使用纯UIKit实现
- **向后兼容**: 支持iOS 16.0+，避免使用iOS 17独有API
- **代码简洁**: 避免过度设计，直接有效的实现
- **功能完整**: 保持现有所有功能不变

### 技术目标
- 使用现代UIKit最佳实践
- MVVM架构模式
- 纯代码布局（Auto Layout）
- Combine响应式编程
- 委托模式数据传递

## 分阶段实施计划

---

## 第一阶段：基础架构搭建

### 目标
建立UIKit导航基础，替换SwiftUI入口点

### 具体实施步骤

#### 1.1 完善SceneDelegate配置

**文件**: `SubZen/Application/SceneDelegate.swift`

**当前状态**: 已部分修改，需要完善window配置

**需要实现的功能**:
```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // 创建根导航控制器
        let rootViewController = SubscriptionListViewController()
        let navigationController = UINavigationController(rootViewController: rootViewController)
        
        // 配置导航栏外观
        setupNavigationBarAppearance()
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
    
    private func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
```

#### 1.2 创建基础ViewController架构

**新建文件**: `SubZen/Interface/ViewControllers/Base/BaseViewController.swift`

**用途**: 提供通用的ViewController基础功能

**实现要点**:
```swift
import UIKit
import Combine

class BaseViewController: UIViewController {
    
    // Combine订阅管理
    var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()
    }
    
    // 子类重写的方法
    func setupUI() {
        view.backgroundColor = .systemGroupedBackground
    }
    
    func setupConstraints() {
        // 子类实现约束设置
    }
    
    func setupBindings() {
        // 子类实现数据绑定
    }
    
    deinit {
        cancellables.removeAll()
    }
}
```

#### 1.3 验收标准
- [ ] App可以正常启动并显示UINavigationController
- [ ] 导航栏外观配置正确
- [ ] 基础样式配置生效
- [ ] 没有SwiftUI相关的错误

---

## 第二阶段：主列表界面重构

### 目标
实现完整的订阅列表功能，替换现有的SwiftUI SubscriptionListView

### 具体实施步骤

#### 2.1 创建SubscriptionListViewController

**新建文件**: `SubZen/Interface/ViewControllers/SubscriptionListViewController.swift`

**实现要点**:
```swift
import UIKit
import Combine

class SubscriptionListViewController: BaseViewController {
    
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(SubscriptionTableViewCell.self, forCellReuseIdentifier: SubscriptionTableViewCell.identifier)
        return table
    }()
    
    private lazy var totalLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return refresh
    }()
    
    // MARK: - Properties
    private let viewModel = SubscriptionListViewModel()
    
    // MARK: - Lifecycle
    override func setupUI() {
        super.setupUI()
        
        title = "订阅管理"
        
        // 添加导航栏按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        
        // 添加视图
        view.addSubview(totalLabel)
        view.addSubview(tableView)
        
        tableView.refreshControl = refreshControl
        
        // 设置背景渐变
        setupGradientBackground()
    }
    
    override func setupConstraints() {
        NSLayoutConstraint.activate([
            totalLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            totalLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            totalLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    override func setupBindings() {
        viewModel.delegate = self
        viewModel.loadSubscriptions()
    }
    
    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemBlue.withAlphaComponent(0.1).cgColor,
            UIColor.systemPurple.withAlphaComponent(0.1).cgColor
        ]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    // MARK: - Actions
    @objc private func addButtonTapped() {
        let addVC = AddSubscriptionViewController()
        addVC.delegate = self
        navigationController?.pushViewController(addVC, animated: true)
    }
    
    @objc private func handleRefresh() {
        viewModel.refreshData()
    }
}

// MARK: - UITableViewDataSource
extension SubscriptionListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.subscriptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SubscriptionTableViewCell.identifier, for: indexPath) as! SubscriptionTableViewCell
        cell.configure(with: viewModel.subscriptions[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate  
extension SubscriptionListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let subscription = viewModel.subscriptions[indexPath.row]
        presentEditViewController(for: subscription)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let subscription = viewModel.subscriptions[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let editAction = UIAction(title: "编辑", image: UIImage(systemName: "pencil")) { [weak self] _ in
                self?.presentEditViewController(for: subscription)
            }
            
            let deleteAction = UIAction(title: "删除", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.deleteSubscription(subscription)
            }
            
            return UIMenu(title: "", children: [editAction, deleteAction])
        }
    }
    
    private func presentEditViewController(for subscription: Subscription) {
        let editVC = EditSubscriptionViewController(subscription: subscription)
        editVC.delegate = self
        let navController = UINavigationController(rootViewController: editVC)
        present(navController, animated: true)
    }
    
    private func deleteSubscription(_ subscription: Subscription) {
        viewModel.deleteSubscription(subscription)
    }
}
```

#### 2.2 创建SubscriptionListViewModel

**新建文件**: `SubZen/Interface/ViewModels/SubscriptionListViewModel.swift`

**实现要点**:
```swift
import Foundation
import Combine

protocol SubscriptionListViewModelDelegate: AnyObject {
    func subscriptionsDidUpdate()
    func totalDidUpdate(_ total: String)
    func loadingStateDidChange(_ isLoading: Bool)
    func errorOccurred(_ error: Error)
}

class SubscriptionListViewModel: ObservableObject {
    
    // MARK: - Properties
    weak var delegate: SubscriptionListViewModelDelegate?
    
    private(set) var subscriptions: [Subscription] = []
    private let currencyService = CurrencyTotalService.shared
    private let exchangeRateService = ExchangeRateService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // 监听汇率服务的更新
        currencyService.$monthlyTotal
            .receive(on: DispatchQueue.main)
            .sink { [weak self] total in
                self?.handleTotalUpdate(total)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadSubscriptions() {
        delegate?.loadingStateDidChange(true)
        
        Task {
            do {
                let loadedSubscriptions = await loadSubscriptionsFromStorage()
                
                await MainActor.run {
                    self.subscriptions = loadedSubscriptions
                    self.delegate?.subscriptionsDidUpdate()
                    self.delegate?.loadingStateDidChange(false)
                }
                
                // 计算总额
                await calculateTotal()
                
            } catch {
                await MainActor.run {
                    self.delegate?.errorOccurred(error)
                    self.delegate?.loadingStateDidChange(false)
                }
            }
        }
    }
    
    func refreshData() {
        Task {
            // 刷新汇率
            await exchangeRateService.refreshExchangeRates()
            
            // 重新计算总额
            await calculateTotal()
            
            await MainActor.run {
                self.delegate?.loadingStateDidChange(false)
            }
        }
    }
    
    func deleteSubscription(_ subscription: Subscription) {
        subscriptions.removeAll { $0.id == subscription.id }
        saveSubscriptions()
        delegate?.subscriptionsDidUpdate()
        
        Task {
            await calculateTotal()
        }
    }
    
    func addSubscription(_ subscription: Subscription) {
        subscriptions.append(subscription)
        saveSubscriptions()
        delegate?.subscriptionsDidUpdate()
        
        Task {
            await calculateTotal()
        }
    }
    
    func updateSubscription(_ subscription: Subscription) {
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index] = subscription
            saveSubscriptions()
            delegate?.subscriptionsDidUpdate()
            
            Task {
                await calculateTotal()
            }
        }
    }
    
    // MARK: - Private Methods
    private func loadSubscriptionsFromStorage() async -> [Subscription] {
        // 复用现有的UserDefaults加载逻辑
        guard let data = UserDefaults.standard.data(forKey: "subscriptions") else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([Subscription].self, from: data)
        } catch {
            print("Failed to load subscriptions: \(error)")
            return []
        }
    }
    
    private func saveSubscriptions() {
        do {
            let data = try JSONEncoder().encode(subscriptions)
            UserDefaults.standard.set(data, forKey: "subscriptions")
        } catch {
            print("Failed to save subscriptions: \(error)")
        }
    }
    
    private func calculateTotal() async {
        await currencyService.calculateMonthlyTotal(for: subscriptions)
    }
    
    private func handleTotalUpdate(_ total: Decimal) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyService.baseCurrency
        
        let totalString = formatter.string(from: NSDecimalNumber(decimal: total)) ?? "¥0.00"
        delegate?.totalDidUpdate("月总支出: \(totalString)")
    }
}
```

#### 2.3 创建自定义TableViewCell

**新建文件**: `SubZen/Interface/Cells/SubscriptionTableViewCell.swift`

**实现要点**:
```swift
import UIKit

class SubscriptionTableViewCell: UITableViewCell {
    
    static let identifier = "SubscriptionTableViewCell"
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .tertiarySystemGroupedBackground
        view.layer.cornerRadius = 15
        view.layer.shadowColor = UIColor.label.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .systemBlue
        return label
    }()
    
    private let cycleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let nextBillingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(priceLabel)
        containerView.addSubview(cycleLabel)
        containerView.addSubview(nextBillingLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: priceLabel.leadingAnchor, constant: -8),
            
            priceLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            priceLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            cycleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            cycleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            nextBillingLabel.topAnchor.constraint(equalTo: cycleLabel.bottomAnchor, constant: 4),
            nextBillingLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            nextBillingLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            nextBillingLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Configuration
    func configure(with subscription: Subscription) {
        nameLabel.text = subscription.name
        
        // 格式化价格
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = subscription.currency
        priceLabel.text = formatter.string(from: NSDecimalNumber(decimal: subscription.price))
        
        // 显示计费周期
        cycleLabel.text = subscription.billingCycle.rawValue
        
        // 计算下次扣费日期
        let nextBilling = calculateNextBillingDate(from: subscription.startDate, cycle: subscription.billingCycle)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        nextBillingLabel.text = "下次扣费: \(dateFormatter.string(from: nextBilling))"
    }
    
    private func calculateNextBillingDate(from startDate: Date, cycle: BillingCycle) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch cycle {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: now) ?? now
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? now
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: startDate) ?? now
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: startDate) ?? now
        }
    }
}
```

#### 2.4 实现Delegate协议

在SubscriptionListViewController中添加delegate实现：

```swift
// MARK: - SubscriptionListViewModelDelegate
extension SubscriptionListViewController: SubscriptionListViewModelDelegate {
    func subscriptionsDidUpdate() {
        tableView.reloadData()
        
        // 处理空状态
        if viewModel.subscriptions.isEmpty {
            showEmptyState()
        } else {
            hideEmptyState()
        }
    }
    
    func totalDidUpdate(_ total: String) {
        totalLabel.text = total
    }
    
    func loadingStateDidChange(_ isLoading: Bool) {
        if !isLoading {
            refreshControl.endRefreshing()
        }
    }
    
    func errorOccurred(_ error: Error) {
        let alert = UIAlertController(title: "错误", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func showEmptyState() {
        // 创建空状态视图（替代SwiftUI的ContentUnavailableView）
        let emptyView = UIView()
        let emptyLabel = UILabel()
        emptyLabel.text = "暂无订阅\n点击右上角 + 添加订阅"
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.textColor = .secondaryLabel
        
        emptyView.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor)
        ])
        
        tableView.backgroundView = emptyView
    }
    
    private func hideEmptyState() {
        tableView.backgroundView = nil
    }
}
```

#### 2.5 验收标准
- [ ] 订阅列表正确显示所有订阅
- [ ] 每个订阅的卡片样式与原SwiftUI版本一致
- [ ] 下拉刷新功能正常工作
- [ ] 总额计算和显示正确
- [ ] 空状态处理正确显示
- [ ] 长按菜单功能正常
- [ ] 导航到添加页面正常

---

## 第三阶段：添加订阅功能

### 目标
实现添加订阅的表单界面，替换现有的SwiftUI AddSubView

### 具体实施步骤

#### 3.1 创建AddSubscriptionViewController

**新建文件**: `SubZen/Interface/ViewControllers/AddSubscriptionViewController.swift`

**实现框架**:
```swift
import UIKit

protocol AddSubscriptionViewControllerDelegate: AnyObject {
    func didAddSubscription(_ subscription: Subscription)
}

class AddSubscriptionViewController: BaseViewController {
    
    // MARK: - Properties
    weak var delegate: AddSubscriptionViewControllerDelegate?
    private let viewModel = AddSubscriptionViewModel()
    
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        // 注册各种Cell类型
        table.register(TextFieldTableViewCell.self, forCellReuseIdentifier: "TextFieldCell")
        table.register(CurrencySelectionTableViewCell.self, forCellReuseIdentifier: "CurrencyCell")
        table.register(SegmentedControlTableViewCell.self, forCellReuseIdentifier: "SegmentedCell")
        table.register(DatePickerTableViewCell.self, forCellReuseIdentifier: "DatePickerCell")
        return table
    }()
    
    // MARK: - Lifecycle
    override func setupUI() {
        super.setupUI()
        
        title = "添加订阅"
        
        // 导航栏按钮
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
        
        view.addSubview(tableView)
        
        // 初始状态下保存按钮禁用
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    override func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    override func setupBindings() {
        viewModel.delegate = self
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func saveTapped() {
        viewModel.saveSubscription()
    }
}

// MARK: - UITableViewDataSource
extension AddSubscriptionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return AddSubscriptionSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = AddSubscriptionSection.allCases[section]
        return sectionType.numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionType = AddSubscriptionSection.allCases[indexPath.section]
        
        switch sectionType {
        case .basicInfo:
            return configureBasicInfoCell(for: indexPath)
        case .pricing:
            return configurePricingCell(for: indexPath)
        case .schedule:
            return configureScheduleCell(for: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return AddSubscriptionSection.allCases[section].title
    }
}
```

#### 3.2 创建表单数据管理

**新建文件**: `SubZen/Interface/ViewModels/AddSubscriptionViewModel.swift`

**实现要点**:
```swift
import Foundation

protocol AddSubscriptionViewModelDelegate: AnyObject {
    func formValidationChanged(_ isValid: Bool)
    func subscriptionSaved(_ subscription: Subscription)
    func errorOccurred(_ error: Error)
}

class AddSubscriptionViewModel {
    
    // MARK: - Properties
    weak var delegate: AddSubscriptionViewModelDelegate?
    
    // 表单数据
    var subscriptionName: String = "" {
        didSet { validateForm() }
    }
    
    var price: String = "" {
        didSet { validateForm() }
    }
    
    var selectedCurrency: String = "CNY" {
        didSet { validateForm() }
    }
    
    var billingCycle: BillingCycle = .monthly {
        didSet { validateForm() }
    }
    
    var startDate: Date = Date() {
        didSet { validateForm() }
    }
    
    // MARK: - Validation
    private func validateForm() {
        let isNameValid = !subscriptionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isPriceValid = Decimal(string: price) != nil && !price.isEmpty
        
        let isValid = isNameValid && isPriceValid
        delegate?.formValidationChanged(isValid)
    }
    
    // MARK: - Save
    func saveSubscription() {
        guard let priceDecimal = Decimal(string: price) else {
            delegate?.errorOccurred(AddSubscriptionError.invalidPrice)
            return
        }
        
        let subscription = Subscription(
            id: UUID(),
            name: subscriptionName.trimmingCharacters(in: .whitespacesAndNewlines),
            price: priceDecimal,
            currency: selectedCurrency,
            billingCycle: billingCycle,
            startDate: startDate,
            isActive: true
        )
        
        delegate?.subscriptionSaved(subscription)
    }
}

enum AddSubscriptionError: Error, LocalizedError {
    case invalidPrice
    
    var errorDescription: String? {
        switch self {
        case .invalidPrice:
            return "请输入有效的价格"
        }
    }
}

enum AddSubscriptionSection: CaseIterable {
    case basicInfo
    case pricing
    case schedule
    
    var title: String {
        switch self {
        case .basicInfo:
            return "基本信息"
        case .pricing:
            return "价格设置"
        case .schedule:
            return "计费周期"
        }
    }
    
    var numberOfRows: Int {
        switch self {
        case .basicInfo:
            return 1 // 订阅名称
        case .pricing:
            return 2 // 价格输入 + 货币选择
        case .schedule:
            return 2 // 计费周期 + 开始日期
        }
    }
}
```

#### 3.3 创建表单Cell组件

**新建文件**: `SubZen/Interface/Cells/Form/TextFieldTableViewCell.swift`

```swift
import UIKit

class TextFieldTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    var textChangedHandler: ((String) -> Void)?
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let textField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.textAlignment = .right
        field.font = .systemFont(ofSize: 16)
        return field
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(textField)
        
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 100),
            
            textField.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Configuration
    func configure(title: String, placeholder: String, text: String = "", keyboardType: UIKeyboardType = .default) {
        titleLabel.text = title
        textField.placeholder = placeholder
        textField.text = text
        textField.keyboardType = keyboardType
    }
    
    // MARK: - Actions
    @objc private func textFieldDidChange() {
        textChangedHandler?(textField.text ?? "")
    }
}
```

类似地，还需要创建其他表单Cell：
- `CurrencySelectionTableViewCell.swift`
- `SegmentedControlTableViewCell.swift`  
- `DatePickerTableViewCell.swift`

#### 3.4 验收标准
- [ ] 表单界面布局正确，与原SwiftUI版本一致
- [ ] 所有输入控件正常工作
- [ ] 表单验证逻辑正确
- [ ] 保存按钮状态正确更新
- [ ] 数据保存功能正常
- [ ] 导航和返回逻辑正常

---

## 第四阶段：编辑和货币选择功能

### 目标
实现编辑订阅和货币选择功能

### 具体实施步骤

#### 4.1 创建EditSubscriptionViewController

**新建文件**: `SubZen/Interface/ViewControllers/EditSubscriptionViewController.swift`

**实现策略**: 继承或复用AddSubscriptionViewController的逻辑，预填充数据

#### 4.2 创建CurrencySelectionViewController

**新建文件**: `SubZen/Interface/ViewControllers/CurrencySelectionViewController.swift`

**功能要求**:
- 显示支持的货币列表
- 实现搜索功能
- 支持选择状态指示
- 模态展示和数据回传

#### 4.3 实现模态导航

**导航流程**:
```
SubscriptionListViewController
├── 长按 → 上下文菜单 → "编辑"
│   └── Present → EditSubscriptionViewController (Modal)
│       └── 货币选择 → CurrencySelectionViewController (Modal)
└── 点击行 → EditSubscriptionViewController (Modal)
```

#### 4.4 验收标准
- [ ] 编辑功能完全正常，数据预填充正确
- [ ] 货币选择界面正确，搜索功能正常
- [ ] 模态导航流畅，数据传递无误
- [ ] 保存和取消操作正确

---

## 第五阶段：清理和优化

### 目标
移除所有SwiftUI代码，优化性能

### 具体实施步骤

#### 5.1 代码清理
- [ ] 删除`SubZen/Interface/`下的所有SwiftUI视图文件
- [ ] 移除SwiftUI相关的import语句
- [ ] 清理不再使用的UIHostingController相关代码
- [ ] 更新项目文件引用

#### 5.2 性能优化
- [ ] 检查TableView滚动性能
- [ ] 优化内存使用
- [ ] 确保数据更新的效率
- [ ] 测试大量订阅数据的性能

#### 5.3 最终测试
- [ ] 完整功能回归测试
- [ ] iOS 16.0设备兼容性测试
- [ ] 内存泄漏检测
- [ ] 性能基准测试

---

## 技术约束和最佳实践

### iOS 16.0+兼容性要求

#### 避免使用的API
```swift
// ❌ 避免使用 iOS 17+ 独有API
if #available(iOS 17.0, *) {
    // ContentUnavailableView - 使用自定义空状态视图
    // UINavigationSplitView - 使用传统导航
}

// ❌ 避免使用 iOS 14+ 新特性如果有更兼容的替代方案
// UITableViewDiffableDataSource - 使用传统DataSource
```

#### 推荐使用的模式
```swift
// ✅ 使用传统的UITableView模式
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell

// ✅ 使用Auto Layout约束
NSLayoutConstraint.activate([
    view.topAnchor.constraint(equalTo: superview.topAnchor)
])

// ✅ 使用Combine进行响应式编程
publisher
    .receive(on: DispatchQueue.main)
    .sink { value in 
        // 处理更新
    }
    .store(in: &cancellables)
```

### 代码质量标准

#### 命名规范
```swift
// ViewController命名
class SubscriptionListViewController: BaseViewController

// ViewModel命名  
class SubscriptionListViewModel

// Cell命名
class SubscriptionTableViewCell: UITableViewCell

// 协议命名
protocol SubscriptionListViewModelDelegate: AnyObject
```

#### 文件组织
```
Interface/
├── ViewControllers/
│   ├── Base/
│   │   └── BaseViewController.swift
│   ├── SubscriptionListViewController.swift
│   ├── AddSubscriptionViewController.swift
│   ├── EditSubscriptionViewController.swift
│   └── CurrencySelectionViewController.swift
├── ViewModels/
│   ├── SubscriptionListViewModel.swift
│   └── AddSubscriptionViewModel.swift
├── Views/
│   └── CustomViews/
├── Cells/
│   ├── SubscriptionTableViewCell.swift
│   └── Form/
│       ├── TextFieldTableViewCell.swift
│       ├── CurrencySelectionTableViewCell.swift
│       ├── SegmentedControlTableViewCell.swift
│       └── DatePickerTableViewCell.swift
```

### 性能优化建议

#### UITableView优化
```swift
// 使用Cell重用
tableView.register(SubscriptionTableViewCell.self, forCellReuseIdentifier: "identifier")

// 避免在cellForRowAt中进行复杂计算
func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "identifier") as! SubscriptionTableViewCell
    cell.configure(with: viewModel.subscriptions[indexPath.row]) // 预处理的数据
    return cell
}
```

#### 内存管理
```swift
// 正确使用weak引用避免循环引用
viewModel.onUpdate = { [weak self] in
    self?.updateUI()
}

// Combine订阅管理
private var cancellables = Set<AnyCancellable>()

deinit {
    cancellables.removeAll()
}
```

---

## 常见问题和解决方案

### Q1: 如何保持与现有Backend服务的兼容性？
**A**: Backend服务层完全不变，只需要在ViewModel中正确调用现有的CurrencyTotalService和ExchangeRateService。

### Q2: 如何处理异步数据更新？
**A**: 使用Combine框架和委托模式，在主线程更新UI。

### Q3: 如何实现与SwiftUI相同的视觉效果？
**A**: 使用CAGradientLayer、layer.cornerRadius、layer.shadow等UIKit特性复制SwiftUI的样式。

### Q4: 如何确保iOS 16.0+兼容性？
**A**: 避免使用@available(iOS 17.0, *)标记的API，使用传统的UIKit模式。

---

## 总结

这个PRD提供了完整的SwiftUI到UIKit重构指导，包含：

1. **详细的分阶段实施计划**
2. **具体的代码实现示例**
3. **完整的文件组织结构**
4. **兼容性要求和约束**
5. **质量保证和验收标准**

按照这个计划逐步实施，可以确保重构过程的可控性和成功率，最终得到一个简洁高效的纯UIKit应用。