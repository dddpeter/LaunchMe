import Foundation

/// 表示一组应用的文件夹配置。
struct FolderItem: Identifiable, Codable, Hashable {

  // MARK: - Properties

  let id: UUID
  var name: String
  var appBundleIdentifiers: [String]
  var isExpanded: Bool

  // MARK: - Initializer

  init(id: UUID = UUID(),
       name: String,
       appBundleIdentifiers: [String],
       isExpanded: Bool = false) {
    self.id = id
    self.name = name
    self.appBundleIdentifiers = appBundleIdentifiers
    self.isExpanded = isExpanded
  }

  // MARK: - Helpers

  static func emptyFolder(named name: String) -> FolderItem {
    FolderItem(name: name, appBundleIdentifiers: [])
  }

  static let sampleFolders: [FolderItem] = [
    FolderItem(name: "效率工具", appBundleIdentifiers: []),
    FolderItem(name: "设计工具", appBundleIdentifiers: [])
  ]

}

