import AppKit
import Foundation
import os.log

// MARK: - Protocol

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

// MARK: - Implementation

enum AppDiscoveryError: LocalizedError {
    case accessDenied
    case invalidBundleURL(String)
    case iconLoadFailed(String)
    case bundleNotFound(String)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "无法访问应用目录，请检查权限设置。"
        case .invalidBundleURL(let url):
            return "无效的应用程序Bundle路径：\(url)"
        case .iconLoadFailed(let bundleId):
            return "无法加载应用图标：\(bundleId)"
        case .bundleNotFound(let bundleId):
            return "未找到应用程序：\(bundleId)"
        }
    }
}

final class AppDiscoveryService: AppDiscoveryServicing {

    // MARK: - Properties

    private let fileManager: FileManager
    private let workspace: NSWorkspace
    private let allowedSearchPaths: [URL]
    private var discoveredApps: [AppItem] = []
    private var lastRefreshDate: Date?

    // MARK: - Initializer

    init(fileManager: FileManager = .default,
         workspace: NSWorkspace = .shared,
         allowedSearchPaths: [URL] = AppDiscoveryService.defaultSearchPaths()) {
        self.fileManager = fileManager
        self.workspace = workspace
        self.allowedSearchPaths = allowedSearchPaths
    }

    // MARK: - AppDiscoveryServicing

    func discoverApplications() async throws -> [AppItem] {
        // 如果已缓存且时间较新，直接返回缓存结果
        if let lastRefresh = lastRefreshDate,
           Date().timeIntervalSince(lastRefresh) < 300 { // 5分钟内的缓存有效
            return discoveredApps
        }

        let resources = try await withThrowingTaskGroup(of: [AppItem].self, returning: [AppItem].self) { group -> [AppItem] in
            for path in allowedSearchPaths {
                group.addTask { [weak fileManager = fileManager, weak workspace = workspace] in
                    guard let fileManager, let workspace else { return [] }
                    return await Self.enumerateApplications(at: path, fileManager: fileManager, workspace: workspace)
                }
            }

            var aggregate: [AppItem] = []
            for try await apps in group {
                aggregate.append(contentsOf: apps)
            }
            return aggregate
        }

        let uniqueItems = Dictionary(grouping: resources, by: { $0.bundleIdentifier }).compactMap { _, values in
            values.first
        }

        let sortedApps = uniqueItems.sorted { app1, app2 in
            // 系统应用排在后面
            if app1.isSystemApp != app2.isSystemApp {
                return !app1.isSystemApp
            }
            // 按名称排序
            return app1.displayName.localizedCompare(app2.displayName) == .orderedAscending
        }

        // 缓存结果
        discoveredApps = sortedApps
        lastRefreshDate = Date()

        return sortedApps
    }

    func refreshApplications() async throws -> [AppItem] {
        // 清除缓存
        discoveredApps.removeAll()
        lastRefreshDate = nil

        // 重新发现应用
        return try await discoverApplications()
    }

    func icon(for bundleIdentifier: String) async throws -> NSImage {
        // 首先尝试从已发现的应用中获取
        if let app = discoveredApps.first(where: { $0.bundleIdentifier == bundleIdentifier }),
           let icon = app.icon {
            return icon
        }

        // 通过NSWorkspace查找应用
        guard let appURL = workspace.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            throw AppDiscoveryError.bundleNotFound(bundleIdentifier)
        }

        return try await loadIcon(for: appURL, bundleIdentifier: bundleIdentifier)
    }

    // MARK: - Public Methods

    /// 根据Bundle ID查找应用
    /// - Parameter bundleIdentifier: 应用程序Bundle ID
    /// - Returns: 应用程序，如果不存在则返回nil
    func app(for bundleIdentifier: String) -> AppItem? {
        return discoveredApps.first { $0.bundleIdentifier == bundleIdentifier }
    }

    /// 获取最后刷新时间
    /// - Returns: 最后刷新时间
    func getLastRefreshDate() -> Date? {
        return lastRefreshDate
    }

    // MARK: - Private Methods

    private static func defaultSearchPaths() -> [URL] {
        var urls = [URL(fileURLWithPath: "/Applications", isDirectory: true)]

        // 用户应用目录
        if let userApplications = FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask).first {
            urls.append(userApplications)
        }

        // 系统应用目录
        urls.append(URL(fileURLWithPath: "/System/Applications", isDirectory: true))

        return urls
    }

    private static func enumerateApplications(at directory: URL,
                                            fileManager: FileManager,
                                            workspace: NSWorkspace) async -> [AppItem] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                guard let enumerator = fileManager.enumerator(at: directory,
                                                             includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                                                             options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
                    continuation.resume(returning: [])
                    return
                }

                var results: [AppItem] = []

                for case let fileURL as URL in enumerator {
                    guard fileURL.pathExtension.lowercased() == "app" else { continue }

                    if let appItem = self.createAppItem(from: fileURL, fileManager: fileManager, workspace: workspace) {
                        results.append(appItem)
                    }
                }

                continuation.resume(returning: results)
            }
        }
    }

    private static func createAppItem(from fileURL: URL,
                                     fileManager: FileManager,
                                     workspace: NSWorkspace) -> AppItem? {
        guard let bundle = Bundle(url: fileURL),
              let bundleIdentifier = bundle.bundleIdentifier else {
            return nil
        }

        let displayName = bundle.displayName ?? fileURL.deletingPathExtension().lastPathComponent

        // 获取应用信息
        let categories = bundle.localizedCategories
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
        let developer = bundle.infoDictionary?["CFBundleIdentifier"] as? String

        // 获取文件属性
        var lastModified: Date?
        var size: Int64?

        do {
            let resourceValues = try fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            lastModified = resourceValues.contentModificationDate
            size = Int64(resourceValues.fileSize ?? 0)
        } catch {
            // 忽略错误，使用默认值
        }

        let isSystemApp = fileURL.path.contains("/System/")
        let isHidden = fileURL.lastPathComponent.hasPrefix(".")

        // 加载图标
        let icon = workspace.icon(forFile: fileURL.path)
        icon.size = NSSize(width: 128, height: 128)

        return AppItem(
            bundleIdentifier: bundleIdentifier,
            displayName: displayName,
            bundleURL: fileURL,
            category: categories.first,
            version: version,
            developer: developer,
            lastModified: lastModified,
            isSystemApp: isSystemApp,
            isHidden: isHidden,
            size: size,
            icon: icon
        )
    }

    private func loadIcon(for appURL: URL, bundleIdentifier: String) async throws -> NSImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                let icon = self.workspace.icon(forFile: appURL.path)
                icon.size = NSSize(width: 128, height: 128)

                if icon.isImageValid {
                    continuation.resume(returning: icon)
                } else {
                    continuation.resume(throwing: AppDiscoveryError.iconLoadFailed(bundleIdentifier))
                }
            }
        }
    }
}

// MARK: - Extensions

private extension Bundle {
    var displayName: String? {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? object(forInfoDictionaryKey: "CFBundleName") as? String
    }

    var localizedCategories: [String] {
        guard let categories = object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String else { return [] }
        return categories.split(separator: ".").map { String($0) }
    }
}

private extension NSImage {
    var isImageValid: Bool {
        return !size.equalTo(.zero) && representations.count > 0
    }
}

