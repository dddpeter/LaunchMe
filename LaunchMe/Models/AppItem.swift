import AppKit
import Foundation

/// 应用程序数据模型
struct AppItem: Identifiable, Codable, Hashable {

    // MARK: - Properties

    /// 应用程序唯一标识符
    let id: UUID

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

    // MARK: - Initializer

    init(bundleIdentifier: String,
         displayName: String,
         bundleURL: URL,
         category: String? = nil,
         version: String? = nil,
         developer: String? = nil,
         lastModified: Date? = nil,
         isSystemApp: Bool = false,
         isHidden: Bool = false,
         size: Int64? = nil,
         icon: NSImage? = nil) {
        self.id = UUID()
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.bundleURL = bundleURL
        self.category = category
        self.version = version
        self.developer = developer
        self.lastModified = lastModified
        self.isSystemApp = isSystemApp
        self.isHidden = isHidden
        self.size = size
        self.icon = icon
    }

    // MARK: - Computed Properties

    var resolvedIcon: NSImage {
        if let icon { return icon }
        if let fallback = NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil) {
            fallback.isTemplate = false
            return fallback
        }
        return NSImage(size: NSSize(width: 128, height: 128))
    }

    var searchKeywords: [String] {
        var keywords: [String] = [displayName, bundleIdentifier]
        if let lastComponent = bundleIdentifier.split(separator: ".").last {
            keywords.append(String(lastComponent))
        }
        if let category = category {
            keywords.append(category)
        }
        if let developer = developer {
            keywords.append(developer)
        }
        return keywords
    }

    /// 获取应用程序本地化名称
    var localizedName: String {
        return displayName
    }

    /// 获取应用程序描述
    var description: String {
        var parts: [String] = []
        if let version = version {
            parts.append("版本: \(version)")
        }
        if let developer = developer {
            parts.append("开发者: \(developer)")
        }
        if let category = category {
            parts.append("类别: \(category)")
        }
        return parts.joined(separator: " | ")
    }

    // MARK: - Helpers

    func matches(query: String) -> Bool {
        let normalizedQuery = query.lowercased()
        if displayName.normalizedForSearch().contains(normalizedQuery) { return true }
        if bundleIdentifier.normalizedForSearch().contains(normalizedQuery) { return true }
        if let category = category, category.normalizedForSearch().contains(normalizedQuery) { return true }
        if let developer = developer, developer.normalizedForSearch().contains(normalizedQuery) { return true }
        return searchKeywords.contains { $0.normalizedForSearch().contains(normalizedQuery) }
    }

    // MARK: - Static Methods

    static func placeholders(limit: Int = 12) -> [AppItem] {
        (0..<limit).map { index in
            AppItem(
                bundleIdentifier: "placeholder.bundle.\(index)",
                displayName: "示例应用 \(index + 1)",
                bundleURL: URL(fileURLWithPath: "/Applications"),
                category: "示例",
                version: "1.0.0",
                developer: "示例开发者",
                isSystemApp: false,
                icon: NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)
            )
        }
    }

    /// 从Bundle URL创建应用项
    /// - Parameter url: Bundle URL
    /// - Returns: 应用项，如果创建失败则返回nil
    static func from(bundleURL: URL) -> AppItem? {
        guard let bundle = Bundle(url: bundleURL),
              let bundleIdentifier = bundle.bundleIdentifier else {
            return nil
        }

        let displayName = bundle.displayName ?? bundleURL.deletingPathExtension().lastPathComponent
        let categories = bundle.localizedCategories
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
        let developer = bundle.infoDictionary?["CFBundleIdentifier"] as? String

        return AppItem(
            bundleIdentifier: bundleIdentifier,
            displayName: displayName,
            bundleURL: bundleURL,
            category: categories.first,
            version: version,
            developer: developer,
            isSystemApp: bundleURL.path.contains("/System/")
        )
    }

    // MARK: - Hashable

    static func == (lhs: AppItem, rhs: AppItem) -> Bool {
        lhs.bundleIdentifier == rhs.bundleIdentifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleIdentifier)
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, bundleIdentifier, displayName, bundleURL, category, version
        case developer, lastModified, isSystemApp, isHidden, size
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        displayName = try container.decode(String.self, forKey: .displayName)
        bundleURL = try container.decode(URL.self, forKey: .bundleURL)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        developer = try container.decodeIfPresent(String.self, forKey: .developer)
        lastModified = try container.decodeIfPresent(Date.self, forKey: .lastModified)
        isSystemApp = try container.decodeIfPresent(Bool.self, forKey: .isSystemApp) ?? false
        isHidden = try container.decodeIfPresent(Bool.self, forKey: .isHidden) ?? false
        size = try container.decodeIfPresent(Int64.self, forKey: .size)
        icon = nil // Icon is not Codable, needs to be loaded separately
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
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

// MARK: - Extensions

private extension String {
    func normalizedForSearch() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

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

