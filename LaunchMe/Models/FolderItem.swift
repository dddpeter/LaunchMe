import Foundation
import SwiftUI

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

/// 文件夹数据模型
@MainActor
class FolderItem: ObservableObject, Identifiable, Codable, Hashable {

    // MARK: - Properties

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

    /// 是否展开状态（用于UI）
    @Published var isExpanded: Bool = false

    // MARK: - Initializer

    init(name: String,
         appBundleIdentifiers: [String] = [],
         color: String? = nil,
         sortOrder: FolderSortOrder = .manual) {
        self.id = UUID()
        self.name = name
        self.appBundleIdentifiers = appBundleIdentifiers
        self.color = color
        self.customIcon = nil
        self.createdDate = Date()
        self.lastModifiedDate = Date()
        self.sortOrder = sortOrder
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, name, appBundleIdentifiers, color, createdDate
        case lastModifiedDate, sortOrder, isExpanded
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        appBundleIdentifiers = try container.decode([String].self, forKey: .appBundleIdentifiers)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        lastModifiedDate = try container.decode(Date.self, forKey: .lastModifiedDate)
        sortOrder = try container.decodeIfPresent(FolderSortOrder.self, forKey: .sortOrder) ?? .manual
        isExpanded = try container.decodeIfPresent(Bool.self, forKey: .isExpanded) ?? false
        customIcon = nil // Icon is not Codable
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(appBundleIdentifiers, forKey: .appBundleIdentifiers)
        try container.encodeIfPresent(color, forKey: .color)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(lastModifiedDate, forKey: .lastModifiedDate)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encode(isExpanded, forKey: .isExpanded)
    }

    // MARK: - Public Methods

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

    /// 设置文件夹颜色
    /// - Parameter newColor: 新颜色（HEX字符串）
    func setColor(_ newColor: String?) {
        color = newColor
        lastModifiedDate = Date()
    }

    /// 设置自定义图标
    /// - Parameter icon: 新图标
    func setCustomIcon(_ icon: NSImage?) {
        customIcon = icon
        lastModifiedDate = Date()
    }

    /// 设置排序方式
    /// - Parameter newSortOrder: 新的排序方式
    func setSortOrder(_ newSortOrder: FolderSortOrder) {
        sortOrder = newSortOrder
        lastModifiedDate = Date()
    }

    /// 切换展开状态
    func toggleExpanded() {
        isExpanded.toggle()
    }

    // MARK: - Computed Properties

    /// 获取文件夹中的应用数量
    var appCount: Int {
        appBundleIdentifiers.count
    }

    /// 检查文件夹是否为空
    var isEmpty: Bool {
        appBundleIdentifiers.isEmpty
    }

    /// 获取文件夹的显示颜色
    var displayColor: Color {
        if let colorString = color,
           let uiColor = NSColor(hex: colorString) {
            return Color(uiColor)
        }
        return Color.accentColor
    }

    /// 获取文件夹的显示图标
    var displayIcon: NSImage {
        if let customIcon = customIcon {
            return customIcon
        }

        // 默认文件夹图标
        if let folderIcon = NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil) {
            folderIcon.isTemplate = false
            return folderIcon
        }

        return NSImage(size: NSSize(width: 128, height: 128))
    }

    /// 检查是否包含指定应用
    /// - Parameter bundleIdentifier: 应用程序Bundle ID
    /// - Returns: 是否包含
    func contains(app bundleIdentifier: String) -> Bool {
        appBundleIdentifiers.contains(bundleIdentifier)
    }

    // MARK: - Static Methods

    /// 创建空文件夹
    /// - Parameter name: 文件夹名称
    /// - Returns: 文件夹实例
    static func emptyFolder(named name: String) -> FolderItem {
        return FolderItem(name: name)
    }

    /// 示例文件夹
    static let sampleFolders: [FolderItem] = [
        FolderItem(name: "效率工具", color: "#007AFF", sortOrder: .manual),
        FolderItem(name: "设计工具", color: "#FF3B30", sortOrder: .manual),
        FolderItem(name: "开发工具", color: "#34C759", sortOrder: .manual)
    ]

    // MARK: - Hashable

    static func == (lhs: FolderItem, rhs: FolderItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - NSColor Extension

private extension NSColor {
    convenience init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

