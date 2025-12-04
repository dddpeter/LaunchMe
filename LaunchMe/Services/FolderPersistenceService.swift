import Foundation

// MARK: - Protocol

protocol FolderPersistenceServicing {

  func loadFolders() async throws -> [FolderItem]
  func saveFolders(_ folders: [FolderItem]) async throws

}

// MARK: - Implementation

enum FolderPersistenceError: LocalizedError {

  case invalidData

  var errorDescription: String? {
    switch self {
    case .invalidData:
      return "文件夹数据已损坏，无法读取。"
    }
  }

}

final class FolderPersistenceService: FolderPersistenceServicing {

  // MARK: - Properties

  private let fileManager: FileManager
  private let storageURL: URL

  // MARK: - Initializer

  init(fileManager: FileManager = .default,
       storageURL: URL? = nil) {
    self.fileManager = fileManager
    self.storageURL = storageURL ?? FolderPersistenceService.defaultStorageURL(fileManager: fileManager)
  }

  // MARK: - FolderPersistenceServicing

  func loadFolders() async throws -> [FolderItem] {
    guard fileManager.fileExists(atPath: storageURL.path) else {
      return []
    }

    let data = try Data(contentsOf: storageURL)
    guard !data.isEmpty else { return [] }

    let folders = try JSONDecoder().decode([FolderItem].self, from: data)
    return folders
  }

  func saveFolders(_ folders: [FolderItem]) async throws {
    let data = try JSONEncoder().encode(folders)
    let directory = storageURL.deletingLastPathComponent()
    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    try data.write(to: storageURL, options: .atomic)
  }

  // MARK: - Helpers

  private static func defaultStorageURL(fileManager: FileManager) -> URL {
    let supportDirectory = try? fileManager.url(for: .applicationSupportDirectory,
                                                in: .userDomainMask,
                                                appropriateFor: nil,
                                                create: true)
    let appDirectory = supportDirectory?.appendingPathComponent("LaunchMe", isDirectory: true)
    return appDirectory?.appendingPathComponent("folders.json", isDirectory: false)
      ?? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("LaunchMe/folders.json")
  }

}

