# LaunchMe 架构设计文档

## 📋 概述

LaunchMe 是一个现代化的 macOS Launchpad 替代应用，采用 SwiftUI 和 AppKit 混合架构，实现了高性能的应用启动和管理功能。

## 🏗️ 整体架构

### 架构模式
- **MVVM (Model-View-ViewModel)** - 主要架构模式
- **组件化设计** - 模块化的组件结构
- **服务层分离** - 业务逻辑与UI分离

### 技术栈
- **SwiftUI** - 用户界面构建
- **AppKit** - 系统级功能（窗口管理、全局快捷键）
- **Combine** - 响应式编程
- **Core Graphics** - 图形和动画处理

## 📁 目录结构

```
LaunchMe/
├── Application/              # 应用入口点
│   └── LaunchpadApp.swift    # 主应用类
├── Managers/                # 管理器层
│   ├── IconCacheManager.swift      # 图标缓存管理
│   └── LaunchpadWindowManager.swift # 窗口管理
├── Models/                   # 数据模型
│   ├── AppItem.swift         # 应用数据模型
│   └── FolderItem.swift     # 文件夹数据模型
├── Services/                 # 服务层
│   ├── AppDiscoveryService.swift    # 应用发现服务
│   └── FolderPersistenceService.swift # 文件夹持久化服务
├── Utils/                    # 工具类
│   └── PerformanceMonitor.swift     # 性能监控
├── ViewModels/               # 视图模型层
│   ├── LaunchpadViewModel.swift      # 主界面视图模型
│   └── SearchViewModel.swift         # 搜索视图模型
├── Views/                    # 视图层
│   ├── LaunchpadContentView.swift   # 主内容视图
│   ├── LaunchpadRootView.swift       # 根视图
│   └── Components/                   # 可复用组件
│       ├── AppGridItemView.swift     # 应用网格项
│       ├── DraggableAppGrid.swift    # 可拖拽网格
│       ├── FolderEditDialog.swift    # 文件夹编辑对话框
│       ├── FolderGridItemView.swift  # 文件夹网格项
│       ├── FolderOverlayView.swift   # 文件夹浮层视图
│       ├── SearchBarView.swift       # 搜索栏视图
│       └── ToastNotification.swift   # 通知组件
└── Tests/                     # 测试
    └── LaunchpadViewModelTests.swift # 视图模型测试
```

## 🔄 数据流架构

### MVVM 数据流
```
User Input → View → ViewModel → Model → Service → Data Source
     ↑                                              ↓
UI Update ← Published Properties ← Business Logic ← Response
```

### 组件通信
- **@Published 属性** - 自动UI更新
- **Delegate 模式** - 服务间通信
- **Closure 回调** - 异步操作处理
- **Notification** - 跨组件通信

## 🎨 UI 架构

### SwiftUI 视图层次
```
LaunchpadApp (App)
└── LaunchpadRootView (Window)
    └── LaunchpadContentView (Main View)
        ├── SearchBarView (Search)
        ├── DraggableAppGrid (Grid)
        │   ├── AppGridItemView (App Item)
        │   └── FolderGridItemView (Folder Item)
        └── FolderOverlayView (Folder Detail)
            └── DraggableAppGrid (Folder Content)
```

### AppKit 集成
- **NSWindow** - 主窗口容器
- **NSView** - SwiftUI 宿主视图
- **CGEvent** - 全局快捷键处理
- **NSWorkspace** - 系统应用管理

## 🗄️ 数据架构

### 数据模型
```swift
// 应用模型
struct AppItem {
    let bundleIdentifier: String
    let displayName: String
    let bundleURL: URL
    let icon: NSImage
    let category: String?
}

// 文件夹模型
class FolderItem: ObservableObject {
    let id: UUID
    @Published var name: String
    @Published var appBundleIdentifiers: [String]
}
```

### 数据持久化
- **UserDefaults** - 文件夹配置存储
- **文件系统缓存** - 图标缓存
- **内存缓存** - 运行时数据缓存

## 🔧 服务架构

### 应用发现服务
```swift
protocol AppDiscoveryServicing {
    func discoverApplications() async throws -> [AppItem]
    func refreshApplications() async throws -> [AppItem]
}
```

### 文件夹持久化服务
```swift
protocol FolderPersistenceServicing {
    func loadFolders() async throws -> [FolderItem]
    func saveFolders(_ folders: [FolderItem]) async throws
}
```

### 图标缓存管理
```swift
class IconCacheManager {
    private let memoryCache: NSCache<NSString, NSImage>
    private let diskCacheURL: URL
    
    func icon(for bundleIdentifier: String) async -> NSImage?
    func cacheIcon(_ icon: NSImage, for bundleIdentifier: String)
}
```

## 🎭 状态管理

### 状态管理策略
- **@StateObject** - 视图模型生命周期管理
- **@ObservedObject** - 响应式数据观察
- **@EnvironmentObject** - 全局状态共享
- **@Published** - 属性变化通知

### 主要状态
```swift
class LaunchpadViewModel: ObservableObject {
    @Published private(set) var apps: [AppItem] = []
    @Published private(set) var folders: [FolderItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isVisible = false
    @Published private(set) var activeFolderID: UUID?
}
```

## 🚀 性能优化架构

### 缓存策略
1. **多级缓存**
   - 内存缓存：快速访问常用数据
   - 磁盘缓存：持久化存储
   - 系统缓存：利用系统级缓存

2. **懒加载**
   - 按需加载应用图标
   - 分页加载大量数据
   - 后台预加载

3. **异步处理**
   - 非阻塞UI操作
   - 并行数据处理
   - 后台任务队列

### 性能监控
```swift
class PerformanceMonitor {
    func measure<T>(_ operation: () throws -> T) rethrows -> T
    func startTimelineEvent(_ name: String)
    func endTimelineEvent(_ name: String)
}
```

## 🔒 错误处理架构

### 错误类型定义
```swift
enum LaunchMeError: LocalizedError {
    case applicationDiscoveryFailed(underlying: Error)
    case folderPersistenceFailed(underlying: Error)
    case iconLoadingFailed(bundleIdentifier: String)
    case windowManagementFailed(underlying: Error)
}
```

### 错误处理策略
- **优雅降级** - 部分功能失败不影响整体使用
- **用户友好提示** - 清晰的错误信息展示
- **自动重试** - 网络或临时错误的自动恢复
- **错误上报** - 开发环境下的详细错误记录

## 🧪 测试架构

### 测试策略
1. **单元测试** - 业务逻辑验证
2. **集成测试** - 组件间交互测试
3. **UI测试** - 用户界面交互测试
4. **性能测试** - 关键路径性能验证

### 测试工具
- **XCTest** - 主要测试框架
- **Quick/Nimble** - BDD风格测试（可选）
- **OCMock** - 模拟对象（如需要）

## 🔮 扩展性设计

### 插件架构
- **协议定义** - 清晰的插件接口
- **动态加载** - 运行时插件发现
- **依赖注入** - 插件依赖管理

### 配置管理
- **环境配置** - 开发/测试/生产环境
- **用户偏好** - 个性化设置
- **功能开关** - 动态功能控制

## 📊 监控和分析

### 性能指标
- **启动时间** - 应用冷启动时间
- **响应时间** - 用户操作响应延迟
- **内存使用** - 运行时内存占用
- **CPU使用** - 处理器资源消耗

### 用户行为分析
- **功能使用统计** - 各功能使用频率
- **用户路径分析** - 典型使用流程
- **错误率统计** - 功能稳定性指标

## 🔄 未来架构演进

### 可能的改进方向
1. **微服务化** - 将大型服务拆分为小型服务
2. **事件驱动** - 采用事件驱动架构
3. **云同步** - 添加云端数据同步功能
4. **AI集成** - 智能应用推荐和搜索

### 技术债务管理
- **定期重构** - 保持代码质量
- **依赖更新** - 及时更新第三方库
- **性能优化** - 持续性能改进
- **安全加固** - 定期安全审计

这个架构设计为 LaunchMe 提供了坚实的技术基础，确保应用的可维护性、可扩展性和高性能。