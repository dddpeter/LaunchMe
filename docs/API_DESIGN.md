# LaunchMe API 设计文档

## 📋 概述

本文档描述了 LaunchMe 应用内部各组件间的 API 设计，包括协议定义、服务接口和数据模型。

## 🔌 服务协议

### 应用发现服务

```swift
/// 应用发现服务协议
protocol AppDiscoveryServicing {
    /// 发现系统中所有应用程序
    /// - Returns: 应用程序数组
    /// - Throws: 应用发现错误
    func discoverApplications() async throws -> [AppItem]
    
    /// 刷新应用程序列表
    /// - Returns: 更新后的应用程序数组
    /// - Throws: 刷新错误
    func refreshApplications() async throws -> [AppItem]
    
    /// 获取应用程序图标
    /// - Parameter bundleIdentifier: 应用程序Bundle ID
    /// - Returns: 应用程序图标
    /// - Throws: 图标加载错误
    func icon(for bundleIdentifier: String) async throws -> NSImage
}
```

### 文件夹持久化服务

```swift
/// 文件夹持久化服务协议
protocol FolderPersistenceServicing {
    /// 加载所有文件夹
    /// - Returns: 文件夹数组
    /// - Throws: 加载错误
    func loadFolders() async throws -> [FolderItem]
    
    /// 保存文件夹配置
    /// - Parameter folders: 要保存的文件夹数组
    /// - Throws: 保存错误
    func saveFolders(_ folders: [FolderItem]) async throws
    
    /// 创建新文件夹
    /// - Parameter folder: 要创建的文件夹
    /// - Throws: 创建错误
    func createFolder(_ folder: FolderItem) async throws
    
    /// 更新文件夹
    /// - Parameter folder: 要更新的文件夹
    /// - Throws: 更新错误
    func updateFolder(_ folder: FolderItem) async throws
    
    /// 删除文件夹
    /// - Parameter folderId: 要删除的文件夹ID
    /// - Throws: 删除错误
    func deleteFolder(_ folderId: UUID) async throws
}
```

### 图标缓存管理器

```swift
/// 图标缓存管理器协议
protocol IconCacheManaging {
    /// 获取图标
    /// - Parameter bundleIdentifier: 应用程序Bundle ID
    /// - Returns: 图标图像，如果不存在则返回nil
    func icon(for bundleIdentifier: String) async -> NSImage?
    
    /// 缓存图标
    /// - Parameters:
    ///   - icon: 要缓存的图标
    ///   - bundleIdentifier: 应用程序Bundle ID
    func cacheIcon(_ icon: NSImage, for bundleIdentifier: String)
    
    /// 清除缓存
    /// - Parameter bundleIdentifier: 要清除的应用程序Bundle ID，为nil时清除所有缓存
    func clearCache(for bundleIdentifier: String? = nil)
    
    /// 预热缓存
    /// - Parameter bundleIdentifiers: 要预热的Bundle ID数组
    func warmupCache(for bundleIdentifiers: [String]) async
}
```

### 窗口管理器

```swift
/// 窗口管理器协议
protocol LaunchpadWindowManaging {
    /// 显示Launchpad窗口
    /// - Parameter animated: 是否显示动画
    func showWindow(animated: Bool)
    
    /// 隐藏Launchpad窗口
    /// - Parameter animated: 是否显示动画
    func hideWindow(animated: Bool)
    
    /// 切换窗口显示状态
    /// - Returns: 切换后窗口是否可见
    func toggleWindow() -> Bool
    
    /// 窗口是否可见
    var isWindowVisible: Bool { get }
    
    /// 设置全局快捷键
    /// - Parameters:
    ///   - keyCode: 键码
    ///   - modifiers: 修饰键
    /// - Throws: 快捷键设置错误
    func setGlobalHotkey(keyCode: Int, modifiers: NSEvent.ModifierFlags) throws
}
```

## 📊 数据模型

### 应用程序模型

```swift
/// 应用程序数据模型
struct AppItem: Identifiable, Codable, Hashable {
    /// 应用程序唯一标识符
    let id = UUID()
    
    /// Bundle标识符
    let bundleIdentifier: String
    
    /// 显示名称
    let displayName: String
    
    /// Bundle URL路径
    let bundleURL: URL
    
    /// 应用程序图标
    var icon: NSImage?
    
    /// 应用程序类别
    let category: String?
    
    /// 版本号
    let version: String?
    
    /// 开发者
    let developer: String?
    
    /// 最后修改日期
    let lastModified: Date?
    
    /// 是否为系统应用
    let isSystemApp: Bool
    
    /// 是否为隐藏应用
    let isHidden: Bool
    
    /// 应用程序大小（字节）
    let size: Int64?
    
    /// 创建占位符应用
    static func placeholders() -> [AppItem]
    
    /// 从Bundle URL创建应用项
    /// - Parameter url: Bundle URL
    /// - Returns: 应用项，如果创建失败则返回nil
    static func from(bundleURL: URL) -> AppItem?
    
    /// 获取应用程序本地化名称
    var localizedName: String { get }
    
    /// 获取应用程序描述
    var description: String { get }
}

// Codable实现
extension AppItem {
    enum CodingKeys: String, CodingKey {
        case bundleIdentifier, displayName, bundleURL, category, version
        case developer, lastModified, isSystemApp, isHidden, size
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        displayName = try container.decode(String.self, forKey: .displayName)
        bundleURL = try container.decode(URL.self, forKey: .bundleURL)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        developer = try container.decodeIfPresent(String.self, forKey: .developer)
        lastModified = try container.decodeIfPresent(Date.self, forKey: .lastModified)
        isSystemApp = try container.decode(Bool.self, forKey: .isSystemApp)
        isHidden = try container.decode(Bool.self, forKey: .isHidden)
        size = try container.decodeIfPresent(Int64.self, forKey: .size)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bundleIdentifier, forKey: .bundleIdentifier)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(bundleURL, forKey: .bundleURL)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encodeIfPresent(developer, forKey: .developer)
        try container.encodeIfPresent(lastModified, forKey: .lastModified)
        try container.encode(isSystemApp, forKey: .isSystemApp)
        try container.encode(isHidden, forKey: .isHidden)
        try container.encodeIfPresent(size, forKey: .size)
    }
}
```

### 文件夹模型

```swift
/// 文件夹数据模型
class FolderItem: ObservableObject, Identifiable, Codable, Hashable {
    /// 文件夹唯一标识符
    let id: UUID
    
    /// 文件夹名称
    @Published var name: String
    
    /// 包含的应用程序Bundle标识符数组
    @Published var appBundleIdentifiers: [String]
    
    /// 文件夹颜色
    @Published var color: String?
    
    /// 文件夹图标
    @Published var customIcon: NSImage?
    
    /// 创建时间
    let createdDate: Date
    
    /// 最后修改时间
    @Published var lastModifiedDate: Date
    
    /// 文件夹排序方式
    @Published var sortOrder: FolderSortOrder
    
    /// 初始化文件夹
    /// - Parameters:
    ///   - name: 文件夹名称
    ///   - appBundleIdentifiers: 包含的应用Bundle ID数组
    ///   - color: 文件夹颜色
    init(name: String, 
         appBundleIdentifiers: [String] = [], 
         color: String? = nil) {
        self.id = UUID()
        self.name = name
        self.appBundleIdentifiers = appBundleIdentifiers
        self.color = color
        self.createdDate = Date()
        self.lastModifiedDate = Date()
        self.sortOrder = .manual
    }
    
    /// 添加应用程序
    /// - Parameter bundleIdentifier: 应用程序Bundle ID
    func addApp(_ bundleIdentifier: String) {
        if !appBundleIdentifiers.contains(bundleIdentifier) {
            appBundleIdentifiers.append(bundleIdentifier)
            lastModifiedDate = Date()
        }
    }
    
    /// 移除应用程序
    /// - Parameter bundleIdentifier: 应用程序Bundle ID
    func removeApp(_ bundleIdentifier: String) {
        appBundleIdentifiers.removeAll { $0 == bundleIdentifier }
        lastModifiedDate = Date()
    }
    
    /// 重命名文件夹
    /// - Parameter newName: 新名称
    func rename(to newName: String) {
        name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        lastModifiedDate = Date()
    }
    
    /// 获取文件夹中的应用数量
    var appCount: Int {
        appBundleIdentifiers.count
    }
    
    /// 检查文件夹是否为空
    var isEmpty: Bool {
        appBundleIdentifiers.isEmpty
    }
}

/// 文件夹排序方式
enum FolderSortOrder: String, CaseIterable, Codable {
    case manual = "manual"
    case name = "name"
    case dateCreated = "dateCreated"
    case dateModified = "dateModified"
    case appCount = "appCount"
    
    var localizedName: String {
        switch self {
        case .manual: return "手动排序"
        case .name: return "按名称"
        case .dateCreated: return "按创建时间"
        case .dateModified: return "按修改时间"
        case .appCount: return "按应用数量"
        }
    }
}
```

## 🔍 搜索服务

```swift
/// 搜索服务协议
protocol SearchServicing {
    /// 搜索应用程序
    /// - Parameters:
    ///   - query: 搜索查询字符串
    ///   - apps: 要搜索的应用程序数组
    /// - Returns: 匹配的应用程序数组
    func search(query: String, in apps: [AppItem]) -> [AppItem]
    
    /// 获取搜索建议
    /// - Parameters:
    ///   - partialQuery: 部分查询字符串
    ///   - apps: 要搜索的应用程序数组
    /// - Returns: 搜索建议数组
    func suggestions(for partialQuery: String, in apps: [AppItem]) -> [String]
    
    /// 清除搜索历史
    func clearSearchHistory()
    
    /// 获取搜索历史
    /// - Returns: 搜索历史数组
    func getSearchHistory() -> [String]
}
```

### 搜索配置

```swift
/// 搜索配置
struct SearchConfiguration {
    /// 是否区分大小写
    let caseSensitive: Bool
    
    /// 是否模糊搜索
    let fuzzySearch: Bool
    
    /// 搜索字段
    let searchFields: [SearchField]
    
    /// 最大结果数量
    let maxResults: Int
    
    /// 搜索历史大小
    let historySize: Int
    
    static let `default` = SearchConfiguration(
        caseSensitive: false,
        fuzzySearch: true,
        searchFields: [.displayName, .bundleIdentifier, .category, .developer],
        maxResults: 50,
        historySize: 20
    )
}

/// 搜索字段
enum SearchField: String, CaseIterable {
    case displayName = "displayName"
    case bundleIdentifier = "bundleIdentifier"
    case category = "category"
    case developer = "developer"
    
    var localizedName: String {
        switch self {
        case .displayName: return "应用名称"
        case .bundleIdentifier: return "Bundle ID"
        case .category: return "类别"
        case .developer: return "开发者"
        }
    }
}
```

## 🎭 性能监控API

```swift
/// 性能监控协议
protocol PerformanceMonitoring {
    /// 开始性能测量
    /// - Parameter name: 测量名称
    func startMeasurement(_ name: String)
    
    /// 结束性能测量
    /// - Parameter name: 测量名称
    /// - Returns: 测量耗时（秒）
    func endMeasurement(_ name: String) -> TimeInterval
    
    /// 记录性能指标
    /// - Parameters:
    ///   - name: 指标名称
    ///   - value: 指标值
    ///   - unit: 指标单位
    func recordMetric(_ name: String, value: Double, unit: String)
    
    /// 获取性能报告
    /// - Returns: 性能报告
    func getPerformanceReport() -> PerformanceReport
    
    /// 清除性能数据
    func clearMetrics()
}

/// 性能报告
struct PerformanceReport {
    /// 测量结果
    let measurements: [String: [TimeInterval]]
    
    /// 指标数据
    let metrics: [String: [MetricValue]]
    
    /// 报告生成时间
    let generatedAt: Date
    
    /// 应用版本
    let appVersion: String
    
    /// 系统信息
    let systemInfo: SystemInfo
}

/// 指标值
struct MetricValue {
    /// 值
    let value: Double
    
    /// 单位
    let unit: String
    
    /// 记录时间
    let timestamp: Date
}

/// 系统信息
struct SystemInfo {
    /// 操作系统版本
    let osVersion: String
    
    /// 设备型号
    let deviceModel: String
    
    /// 内存大小
    let memorySize: Int64
    
    /// CPU核心数
    let cpuCores: Int
}
```

## 🔧 配置API

```swift
/// 配置管理协议
protocol ConfigurationManaging {
    /// 获取配置值
    /// - Parameters:
    ///   - key: 配置键
    ///   - defaultValue: 默认值
    /// - Returns: 配置值
    func getValue<T>(for key: String, defaultValue: T) -> T
    
    /// 设置配置值
    /// - Parameters:
    ///   - value: 配置值
    ///   - key: 配置键
    func setValue<T>(_ value: T, for key: String)
    
    /// 移除配置
    /// - Parameter key: 配置键
    func removeValue(for key: String)
    
    /// 清除所有配置
    func clearAllValues()
    
    /// 重置为默认配置
    func resetToDefaults()
}

/// 配置键
enum ConfigurationKey: String, CaseIterable {
    case globalHotkeyKeyCode = "globalHotkey.keyCode"
    case globalHotkeyModifiers = "globalHotkey.modifiers"
    case windowAnimationDuration = "window.animationDuration"
    case gridSize = "grid.size"
    case iconSize = "icon.size"
    case showHiddenApps = "showHiddenApps"
    case searchFuzzyEnabled = "search.fuzzyEnabled"
    case cacheMaxSize = "cache.maxSize"
    case performanceMonitoringEnabled = "performance.monitoringEnabled"
    
    var defaultValue: Any {
        switch self {
        case .globalHotkeyKeyCode: return 49 // Space key
        case .globalHotkeyModifiers: return 2048 // Option key
        case .windowAnimationDuration: return 0.3
        case .gridSize: return CGSize(width: 8, height: 6)
        case .iconSize: return 64.0
        case .showHiddenApps: return false
        case .searchFuzzyEnabled: return true
        case .cacheMaxSize: return 100
        case .performanceMonitoringEnabled: return false
        }
    }
}
```

## 🚨 错误处理

```swift
/// LaunchMe错误类型
enum LaunchMeError: LocalizedError {
    /// 应用发现失败
    case applicationDiscoveryFailed(underlying: Error)
    
    /// 文件夹持久化失败
    case folderPersistenceFailed(underlying: Error)
    
    /// 图标加载失败
    case iconLoadingFailed(bundleIdentifier: String)
    
    /// 窗口管理失败
    case windowManagementFailed(underlying: Error)
    
    /// 搜索失败
    case searchFailed(underlying: Error)
    
    /// 配置错误
    case configurationError(key: String, underlying: Error)
    
    /// 权限不足
    case insufficientPermissions(operation: String)
    
    /// 系统不支持
    case unsupportedSystem
    
    var errorDescription: String? {
        switch self {
        case .applicationDiscoveryFailed(let error):
            return "应用发现失败：\(error.localizedDescription)"
        case .folderPersistenceFailed(let error):
            return "文件夹保存失败：\(error.localizedDescription)"
        case .iconLoadingFailed(let bundleId):
            return "无法加载应用图标：\(bundleId)"
        case .windowManagementFailed(let error):
            return "窗口管理失败：\(error.localizedDescription)"
        case .searchFailed(let error):
            return "搜索失败：\(error.localizedDescription)"
        case .configurationError(let key, let error):
            return "配置错误(\(key))：\(error.localizedDescription)"
        case .insufficientPermissions(let operation):
            return "权限不足，无法执行操作：\(operation)"
        case .unsupportedSystem:
            return "当前系统版本不支持此功能"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .applicationDiscoveryFailed:
            return "请检查系统权限设置，确保应用有权访问应用程序目录"
        case .folderPersistenceFailed:
            return "请检查磁盘空间和文件权限"
        case .iconLoadingFailed:
            return "请尝试重新启动应用"
        case .windowManagementFailed:
            return "请检查系统辅助功能权限"
        case .searchFailed:
            return "请检查搜索查询是否正确"
        case .configurationError:
            return "请重置应用配置"
        case .insufficientPermissions:
            return "请在系统偏好设置中授予相应权限"
        case .unsupportedSystem:
            return "请升级到支持的系统版本"
        }
    }
}
```

## 📝 通知API

```swift
/// 通知管理协议
protocol NotificationManaging {
    /// 显示信息通知
    /// - Parameters:
    ///   - title: 通知标题
    ///   - message: 通知消息
    ///   - duration: 显示时长
    func showInfo(title: String, message: String, duration: TimeInterval?)
    
    /// 显示成功通知
    /// - Parameters:
    ///   - title: 通知标题
    ///   - message: 通知消息
    ///   - duration: 显示时长
    func showSuccess(title: String, message: String, duration: TimeInterval?)
    
    /// 显示警告通知
    /// - Parameters:
    ///   - title: 通知标题
    ///   - message: 通知消息
    ///   - duration: 显示时长
    func showWarning(title: String, message: String, duration: TimeInterval?)
    
    /// 显示错误通知
    /// - Parameters:
    ///   - title: 通知标题
    ///   - message: 通知消息
    ///   - duration: 显示时长
    func showError(title: String, message: String, duration: TimeInterval?)
    
    /// 清除所有通知
    func clearAllNotifications()
}
```

这个API设计为LaunchMe提供了清晰的接口定义，确保各组件间的松耦合和高内聚，便于测试、维护和扩展。