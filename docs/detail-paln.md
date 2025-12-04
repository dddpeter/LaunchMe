# **LaunchMe 功能实现计划 (详细版)**
## **项目前置条件**
1.  **开发环境**: Xcode 15.0+, macOS Sonoma 14.0+ (以使用最新的 `@Observable` 宏)。
2.  **项目初始化**:
    *   创建一个新的 **macOS App** 项目，选择 **SwiftUI** 作为 Interface，**Swift** 作为 Language。
    *   项目命名为 `LaunchMe`。
3.  **项目目录结构**:
    ```
    LaunchMe/
    ├── LaunchMeApp.swift         // App 入口
    ├── Models/
    │   ├── AppItem.swift
    │   ├── FolderItem.swift
    │   └── LaunchpadState.swift
    ├── Views/
    │   ├── LaunchpadWindow.swift
    │   ├── LaunchpadContentView.swift
    │   ├── Components/
    │   │   ├── AppIconView.swift
    │   │   ├── SearchBarView.swift
    │   │   └── FolderView.swift
    │   └── Settings/
    │       └── SettingsView.swift
    ├── ViewModels/
    │   ├── LaunchpadViewModel.swift
    │   └── SearchViewModel.swift
    ├── Services/
    │   ├── AppDiscoveryService.swift
    │   ├── AppCacheManager.swift
    │   └── FolderPersistenceService.swift
    ├── Utils/
    │   ├── WindowAnimator.swift
    │   └── SearchIndexer.swift
    ├── Resources/
    │   └── Assets.xcassets
    └── Tests/
        ├── LaunchMeTests/
        └── LaunchMeUITests/
    ```
4.  **核心依赖**:
    *   **系统框架**: `SwiftUI`, `Combine`, `Swift Concurrency`, `AppKit`, `LaunchServices`, `SwiftData` (或 `Codable` for JSON)。
    *   **测试辅助**: `ViewInspector` (用于 SwiftUI 单元测试)，通过 Swift Package Manager 集成。
---
## **阶段一：基础框架与状态管理 (预估: 3-4 天)**
### **目标**
建立项目的数据层和业务逻辑核心，实现应用扫描和基础状态绑定，确保 View 和 ViewModel 之间的数据流清晰、可测试。
### **详细任务**
#### **1.1. 状态模型**
*   **`Models/AppItem.swift`**
    *   **实现**:
        ```swift
        import Foundation
        struct AppItem: Identifiable, Hashable {
            let id = UUID()
            let bundleIdentifier: String
            let displayName: String
            let icon: NSImage
            let category: String? // 可选，用于未来分类
            // 用于搜索的备用名称（如文件名）
            var searchKeywords: [String] {
                [displayName, bundleIdentifier.components(separatedBy: ".").last ?? ""]
            }
        }
        ```
    *   **理由**: `Identifiable` 是 SwiftUI 列表渲染的关键。`Hashable` 支持拖拽和集合操作。`searchKeywords` 为后续搜索提供便利。
*   **`Models/FolderItem.swift`**
    *   **实现**:
        ```swift
        import Foundation
        struct FolderItem: Identifiable, Codable, Hashable {
            let id = UUID()
            var name: String
            var appBundleIDs: [String] // 存储应用的 Bundle ID，而非 AppItem 对象，便于持久化
            var isExpanded: Bool = false
            // 计算属性，从 ViewModel 获取完整的 AppItem 对象
            // func getApps(from allApps: [AppItem]) -> [AppItem] { ... }
        }
        ```
    *   **理由**: `Codable` 支持直接序列化到 JSON。存储 `bundleIdentifier` 而非 `AppItem` 对象，解耦了数据模型和持久化格式，避免了 `NSImage` 等不可序列化对象的问题。
*   **`Models/LaunchpadState.swift`**
    *   **实现**:
        ```swift
        import Observation // macOS 14+ 的新框架
        import Foundation
        @Observable
        class LaunchpadState {
            var allApps: [AppItem] = []
            var folders: [FolderItem] = []
            var pinnedApps: [AppItem] = [] // 未来可扩展的固定应用
            var searchText: String = "" {
                didSet { /* 触发搜索逻辑 */ }
            }
            var isVisible: Bool = false
            var isAnimating: Bool = false
        }
        ```
    *   **理由**: 使用 `@Observable` 宏（来自 `Observation` 框架）是 iOS 17/macOS 14 的新推荐方式，相比 `ObservableObject`，它性能更好，无需 `@StateObject`/`@ObservedObject`，能更精细地追踪依赖变化。
#### **1.2. 服务层**
*   **`Services/AppDiscoveryService.swift`**
    *   **核心逻辑**:
        1.  定义 `scanApplications()` -> `async throws -> [AppItem]` 方法。
        2.  使用 `NSWorkspace.shared.shared.urlForApplication(withBundleIdentifier:)` 和 `FileManager.default` 遍历 `/Applications` 和 `~/Applications` 目录。
        3.  对每个 `.app` 包，使用 `Bundle` 获取 `bundleIdentifier` 和 `displayName`。
        4.  使用 `NSWorkspace.shared.icon(forFile:)` 获取 `NSImage`。
    *   **缓存**: 调用 `AppCacheManager`。如果缓存有效（例如，检查 `/Applications` 目录的修改日期），则直接从缓存加载。否则，执行扫描并更新缓存。
*   **`Services/AppCacheManager.swift`**
    *   **实现**: 使用 `FileManager` 将 `[AppItem]` 数组编码为 JSON（需 `AppItem` 实现 `Codable`，或创建一个可编码的中间体）并保存到 `~/Library/Application Support/LaunchMe/apps.cache`。
    *   **理由**: 应用扫描是耗时操作，缓存能极大提升启动速度。
*   **`Services/FolderPersistenceService.swift`**
    *   **实现**:
        1.  `saveFolders(_ folders: [FolderItem]) -> async throws`
        2.  `loadFolders() -> async throws -> [FolderItem]`
    *   **技术选型**:
        *   **初期 (推荐)**: 使用 `JSONEncoder`/`JSONDecoder`，文件路径与缓存类似。简单、可靠、易于调试。
        *   **后期**: 迁移到 **SwiftData**。需要定义 `@Model` 类，处理数据迁移。SwiftData 提供更强大的关系查询和数据持久化能力，但引入了额外复杂性。**建议先用 JSON，MVP 后再考虑迁移。**
#### **1.3. 视图模型**
*   **`ViewModels/LaunchpadViewModel.swift`**
    *   **实现**:
        ```swift
        import Observation
        @Observable
        class LaunchpadViewModel {
            private let appDiscoveryService: AppDiscoveryService
            private let folderPersistenceService: FolderPersistenceService
            let state = LaunchpadState()
            init(...) { ... }
            func loadInitialData() async {
                // 并行加载应用和文件夹
                async let appsTask = appDiscoveryService.scanApplications()
                async let foldersTask = folderPersistenceService.loadFolders()
                
                self.state.allApps = await appsTask
                self.state.folders = await foldersTask
            }
            func show() { /* 调用 WindowAnimator，更新 state.isVisible */ }
            func hide() { /* ... */ }
            func toggle() { /* ... */ }
            
            // 文件夹操作
            func addAppToFolder(app: AppItem, folderID: UUID) { ... }
            func createFolder(name: String) { ... }
        }
        ```
    *   **理由**: ViewModel 作为协调者，不包含任何 UI 逻辑，只负责状态管理和业务流程编排。所有方法都应该是 `async` 的，以避免阻塞主线程。
*   **`ViewModels/SearchViewModel.swift`**
    *   **实现**:
        ```swift
        import Observation
        import Combine
        @Observable
        class SearchViewModel {
            var query: String = "" {
                didSet { performSearch() }
            }
            private(set) var results: [AppItem] = []
            private(set) var isSearching: Bool = false
            private var allApps: [AppItem] = []
            private var searchIndexer: SearchIndexer
            private var cancellables = Set<AnyCancellable>()
            func setAllApps(_ apps: [AppItem]) {
                self.allApps = apps
                self.searchIndexer.buildIndex(from: apps)
            }
            private func performSearch() {
                // 使用 debounce 防抖
                $query
                    .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
                    .sink { [weak self] newQuery in
                        Task(priority: .userInitiated) {
                            await self?.updateResults(for: newQuery)
                        }
                    }
                    .store(in: &cancellables)
            }
            
            private func updateResults(for query: String) async { ... }
        }
        ```
    *   **理由**: 将搜索逻辑隔离，使 `LaunchpadViewModel` 更轻量。使用 Combine 的 `debounce` 是处理实时搜索的标准模式。
### **阶段一交付物**
- [ ] 一个可以编译运行的 macOS 应用。
- [ ] 启动时，应用能在后台异步扫描并加载本地所有应用。
- [ ] 主界面（一个简单的 `List` 或 `ScrollView`）能显示加载到的应用名称和图标。
- [ ] 项目结构清晰，MVVM 各层职责分明。
- [ ] 核心服务（`AppDiscoveryService`, `FolderPersistenceService`）有基础的单元测试。
---
## **阶段二：打开 / 关闭动画 (预估: 2-3 天)**
### **目标**
实现 LaunchMe 的核心交互：一个可以全局快捷键唤起、带有流畅动画的无边框浮层窗口。
### **详细任务**
#### **2.1. 窗口控制**
*   **`Views/LaunchpadWindow.swift`**
    *   **实现**:
        ```swift
        import AppKit
        import SwiftUI
        class LaunchpadWindow: NSWindow {
            init() {
                super.init(
                    contentRect: .zero,
                    styleMask: [.borderless, .fullSizeContentView],
                    backing: .buffered,
                    defer: false
                )
                self.level = .floating
                self.backgroundColor = .clear
                self.hasShadow = false
                self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                
                // 使用 NSHostingView 包装 SwiftUI View
                let contentView = LaunchpadContentView()
                self.contentView = NSHostingView(rootView: contentView)
            }
            
            // 重写 keyDown 来处理 ESC 键关闭
            override func keyDown(with event: NSEvent) {
                if event.keyCode == 53 { // ESC key
                    // 通知 ViewModel 隐藏
                }
            }
        }
        ```
    *   **理由**: `level = .floating` 确保窗口在最前。`borderless` 和 `backgroundColor = .clear` 是实现浮层效果的基础。
*   **`LaunchMeApp.swift` (入口文件)**
    *   **实现**:
        ```swift
        @main
        struct LaunchMeApp: App {
            @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        }
        class AppDelegate: NSObject, NSApplicationDelegate {
            var launchpadWindow: LaunchpadWindow?
            
            func applicationDidFinishLaunching(_ notification: Notification) {
                self.launchpadWindow = LaunchpadWindow()
                // 设置全局快捷键
                self.setupGlobalHotkey()
            }
            
            private func setupGlobalHotkey() {
                // 使用 Carbon 或第三方库 (e.g., HotKey) 注册快捷键
                // 快捷键触发时调用 launchpadWindow?.viewModel?.toggle()
            }
        }
        ```
#### **2.2. 动画封装**
*   **`Utils/WindowAnimator.swift`**
    *   **实现**:
        ```swift
        import AppKit
        struct WindowAnimator {
            static func show(window: NSWindow, completion: @escaping () -> Void) {
                window.alphaValue = 0
                window.makeKeyAndOrderFront(nil)
                
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.25
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    window.animator().alphaValue = 1.0
                }, completionHandler: completion)
            }
            
            static func hide(window: NSWindow, completion: @escaping () -> Void) {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.2
                    context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                    window.animator().alphaValue = 0.0
                }, completionHandler: {
                    window.orderOut(nil)
                    completion()
                })
            }
        }
        ```
    *   **理由**: 将动画逻辑封装在独立的工具类中，使 ViewModel 代码更干净。`NSAnimationContext` 是 AppKit 的标准动画方式。
#### **2.3. 交互细节**
*   **全局快捷键**: 使用 `HotKey` (第三方 SPM 库) 或 `Carbon` 事件监听器。推荐 `HotKey`，API 更现代。
*   **失焦隐藏**: 在 `LaunchpadWindow` 中监听通知。
    ```swift
    NotificationCenter.default.addObserver(
        forName: NSWindow.didResignKeyNotification,
        object: self,
        queue: .main
    ) { _ in
        // 通知 ViewModel 隐藏
    }
    ```
### **阶段二交付物**
- [ ] 一个全屏、半透明背景的无边框窗口。
- [ ] 可以通过预设的全局快捷键（如 `Option + Space`）呼出和隐藏窗口。
- [ ] 呼出和隐藏过程有平滑的淡入淡出动画。
- [ ] 点击窗口外部或按 `ESC` 键可以隐藏窗口。
---
## **阶段三：搜索能力 (预估: 3-4 天)**
### **目标**
构建一个高性能、体验良好的实时搜索系统，支持应用名、拼音首字母快速检索。
### **详细任务**
#### **3.1. 数据索引**
*   **`Utils/SearchIndexer.swift`**
    *   **实现**:
        ```swift
        // 简单的内存索引，对于应用数量（通常 < 500）足够高效
        class SearchIndexer {
            private var indexedApps: [AppItem] = []
            
            func buildIndex(from apps: [AppItem]) {
                self.indexedApps = apps
                // 未来可扩展：构建 Trie 树或拼音索引
            }
            
            func search(query: String) -> [AppItem] {
                guard !query.isEmpty else { return indexedApps }
                
                let lowercaseQuery = query.lowercased()
                return indexedApps.filter { app in
                    app.displayName.lowercased().contains(lowercaseQuery) ||
                    app.searchKeywords.contains { $0.lowercased().contains(lowercaseQuery) }
                }
            }
        }
        ```
    *   **理由**: 初期使用简单的 `filter` 即可。如果未来应用数量增多或需要更复杂的模糊匹配，可以无缝替换为 Trie 树或其他高级算法，而不影响上层调用。
#### **3.2. UI 呈现**
*   **`Views/Components/SearchBarView.swift`**
    *   **实现**:
        ```swift
        struct SearchBarView: View {
            @Binding var searchText: String
            @FocusState private var isFocused: Bool
            
            var body: some View {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("搜索应用...", text: $searchText)
                        .focused($isFocused)
                        .onAppear { isFocused = true } // 窗口出现时自动聚焦
                }
                .padding(...)
                .background(...)
            }
        }
        ```
    *   **理由**: `@FocusState` 是 SwiftUI 控制焦点的新方式，确保窗口一打开就能输入。
*   **`Views/LaunchpadContentView.swift`**
    *   **实现**:
        ```swift
        struct LaunchpadContentView: View {
            @Environment(\.dismiss) private var dismiss
            @State private var viewModel = LaunchpadViewModel(...)
            
            var body: some View {
                VStack(spacing: 0) {
                    SearchBarView(searchText: $viewModel.state.searchText)
                    
                    // 使用 LazyVGrid 优化性能
                    ScrollView {
                        LazyVGrid(columns: ..., spacing: ...) {
                            // 根据 viewModel.searchViewModel.results 渲染
                            ForEach(displayedApps) { app in
                                AppIconView(app: app)
                            }
                        }
                    }
                }
                .background(...) // 半透明模糊背景
                .onReceive(viewModel.$state.isVisible) { isVisible in
                    if isVisible { viewModel.searchViewModel.query = "" } // 打开时清空搜索
                }
            }
        }
        ```
    *   **理由**: `LazyVGrid` 只渲染可见区域的视图，对于大量数据至关重要。
#### **3.3. 性能优化**
*   **后台搜索**: `SearchViewModel` 中的 `updateResults` 方法已在 `Task(priority: .userInitiated)` 中执行，确保不阻塞 UI。
*   **节流**: `SearchViewModel` 中已使用 Combine 的 `debounce`，避免用户每个输入都触发搜索。
### **阶段三交付物**
- [ ] 搜索框在窗口顶部，打开时自动激活。
- [ ] 输入关键词时，下方的应用网格能实时过滤，响应迅速无卡顿。
- [ ] 搜索支持应用名和 Bundle ID 的部分匹配。
- [ ] （可选）支持拼音首字母搜索，例如输入 "XJ" 能找到 "迅雷"。
---
## **阶段四：应用文件夹 (预估: 4-5 天)**
### **目标**
实现应用的文件夹管理功能，包括创建、拖拽、重命名和删除。
### **详细任务**
#### **4.1. 数据与逻辑更新**
*   **`LaunchpadViewModel`**:
    *   添加 `createFolder`, `deleteFolder`, `renameFolder`, `moveAppToFolder`, `moveAppOutOfFolder` 等方法。
    *   每个修改操作后，立即调用 `folderPersistenceService.saveFolders()` 进行持久化。
    *   更新 `displayedApps` 计算属性，逻辑为：`pinnedApps + folders + (未在文件夹中的 apps)`。
#### **4.2. UI 组件与交互**
*   **`Views/Components/FolderView.swift`**
    *   **实现**:
        ```swift
        struct FolderView: View {
            @Bindable var folder: FolderItem // 使用 @Bindable 处理 isExpanded
            let appsInFolder: [AppItem]
            
            var body: some View {
                VStack {
                    // 文件夹图标和名称
                    Image(systemName: folder.isExpanded ? "folder.fill" : "folder")
                        .onTapGesture { folder.isExpanded.toggle() }
                    
                    if folder.isExpanded {
                        // 展开的文件夹内容，可以是浮层或嵌入式
                        FolderContentView(apps: appsInFolder)
                    }
                }
                .onDrag { NSItemProvider(object: folder.id.uuidString as NSString) }
                .onDrop(of: [.text], isTargeted: nil) { providers in
                    // 处理拖入的应用
                    return true
                }
            }
        }
        ```
    *   **拖拽实现**:
        *   **`AppIconView`**: 添加 `.onDrag`，提供 `AppItem.bundleIdentifier` 作为数据。
        *   **`FolderView` 和 主网格的空白区域**: 添加 `.onDrop`，接收拖拽数据。
        *   使用 `DropDelegate` 可以实现更复杂的拖拽预览和反馈逻辑。
*   **`FolderContentView.swift` (文件夹展开视图)**
    *   可以是一个小的 `LazyVGrid`，当 `folder.isExpanded` 为 `true` 时显示在文件夹下方，并带有一个半透明遮罩背景。
*   **交互逻辑**:
    *   **新建**: 在空白区域长按或右键，弹出菜单 "新建文件夹"。或者提供一个 "+" 按钮。
    *   **重命名/删除**: 右键点击文件夹，弹出上下文菜单。重命名使用 `.alert` 修饰符。
### **阶段四交付物**
- [ ] 用户可以通过拖拽将一个应用拖到另一个上创建文件夹。
- [ ] 可以将应用拖入或拖出文件夹。
- [ ] 可以右键重命名和删除文件夹。
- [ ] 文件夹可以点击展开/收起，显示内部的应用。
- [ ] 所有文件夹操作都会被自动保存，重启应用后状态不变。
---
## **阶段五：测试与工具 (预估: 3-4 天)**
### **目标**
确保应用的稳定性、性能和用户体验符合预期，建立持续的质量保障体系。
### **详细任务**
#### **5.1. 单元测试**
*   **`LaunchpadViewModelTests.swift`**:
    *   测试 `toggle()` 方法是否能正确切换 `state.isVisible`。
    *   测试 `addAppToFolder` 后，`state.folders` 的数据是否正确更新。
*   **`AppDiscoveryServiceTests.swift`**:
    *   Mock `FileManager`，用虚拟的目录结构测试扫描逻辑。
    *   测试缓存机制：首次扫描后，第二次加载是否从缓存读取。
*   **`SearchViewModelTests.swift`**:
    *   测试给定 `allApps` 和 `query`，`results` 是否符合预期。
    *   使用 `measure` 测试不同数量级应用下的搜索性能。
#### **5.2. UI 测试**
*   **`LaunchMeUITests.swift`**:
    *   测试启动应用。
    *   测试通过快捷键打开/关闭窗口。
    *   测试在搜索框输入文本，并断言某个应用按钮存在/不存在。
    *   测试拖拽一个应用到另一个应用上，并断言新文件夹出现。
    *   （使用 `ViewInspector`）在非 UI 线程测试 `SearchBarView` 的 `binding` 是否正确。
#### **5.3. 性能监控**
*   **添加 Signpost**:
    ```swift
    import os.signpost
    let log = OSLog(subsystem: "com.yourapp.LaunchMe", category: "Performance")
    // 在搜索开始时
    os_signpost(.begin, log: log, name: "Search", "Query: %@", query)
    // 在搜索结束时
    os_signpost(.end, log: log, name: "Search", "Found %d results", results.count)
    ```
*   **使用 Instruments**:
    *   **Time Profiler**: 分析 CPU 热点，优化搜索算法或 UI 渲染。
    *   **Allocations**: 检查内存泄漏，特别是 `NSImage` 的创建和释放。
    *   **Core Animation**: 检查动画帧率，确保 60fps 流畅体验。
### **阶段五交付物**
- [ ] 核心业务逻辑（ViewModel, Service）的单元测试覆盖率达到 80% 以上。
- [ ] 主要用户流程（打开、搜索、文件夹操作）的 UI 测试用例。
- [ ] 一份性能基准报告，包含冷启动时间、搜索延迟、动画帧率等关键指标。
- [ ] 关键代码路径已埋入 `os_signpost`，方便未来调试。
---
## **阶段六：后续优化 (持续迭代)**
### **目标**
在 MVP 基础上，增加提升用户体验和扩展性的功能。
### **详细任务**
1.  **应用增量同步**:
    *   监听 `NSWorkspace.didLaunchApplicationNotification` 和 `NSWorkspace.didTerminateApplicationNotification`。
    *   监听 `NSWorkspace.didActivateApplicationNotification` 来感知应用安装/更新。
    *   当变化发生时，触发 `AppDiscoveryService` 的增量扫描和缓存更新。
2.  **设置界面**:
    *   创建 `SettingsView`，使用 `Settings` Link 和 `Settings Window`。
    *   **功能**:
        *   自定义全局快捷键。
        *   主题切换（亮/暗）和背景透明度调节。
        *   网格布局大小调整（行数/列数）。
3.  **数据导入/导出**:
    *   在设置界面提供 "导出配置" 和 "导入配置" 按钮。
    *   将 `folders` 数据导出为 JSON 文件，并支持从 JSON 文件导入。
    *   （高级）支持 iCloud 同步，将配置文件存储在 iCloud Documents 目录。
---
## **时间与资源建议**
| 阶段 | 预估时间 | 主要角色 | 关键风险 |
|---|---|---|---|
| **阶段零: 设置** | 0.5 天 | 开发者 | - |
| **阶段一: 框架** | 3-4 天 | 开发者 | AppKit API 繁琐，应用扫描性能 |
| **阶段二: 动画** | 2-3 天 | 开发者 | 全局快捷键注册，窗口层级管理 |
| **阶段三: 搜索** | 3-4 天 | 开发者 | 拼音搜索库的集成，搜索性能优化 |
| **阶段四: 文件夹** | 4-5 天 | 开发者 | SwiftUI 拖拽 API 的复杂性和状态同步 |
| **阶段五: 测试** | 3-4 天 | 开发者, QA | UI 测试的稳定性，性能瓶颈定位 |
| **阶段六: 优化** | 持续 | 开发者 | - |
| **总计 (MVP)** | **16 - 24.5 天** (约 3-5 周) | | |
**建议流程**:
1.  **每日站会**: 同步进度，解决阻塞问题。
2.  **阶段末 Demo**: 每个阶段结束后，进行一次功能演示和代码评审，确保质量和方向。
3.  **并行开发**: 当开发者在实现阶段二（动画）时，可以开始设计阶段三（搜索）的索引结构。测试工作应尽早介入。
这份详细计划将帮助您或您的团队有条不紊地构建 LaunchMe，确保在追求功能的同时，兼顾代码质量、性能和可维护性。祝您开发顺利！

