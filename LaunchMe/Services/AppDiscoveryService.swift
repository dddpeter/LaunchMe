import AppKit
import Foundation

// MARK: - Protocol

protocol AppDiscoveryServicing {

  func discoverApplications() async throws -> [AppItem]

}

// MARK: - Implementation

enum AppDiscoveryError: LocalizedError {

  case accessDenied

  var errorDescription: String? {
    switch self {
    case .accessDenied:
      return "无法访问应用目录，请检查权限设置。"
    }
  }

}

final class AppDiscoveryService: AppDiscoveryServicing {

  // MARK: - Properties

  private let fileManager: FileManager
  private let workspace: NSWorkspace
  private let allowedSearchPaths: [URL]

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
    let resources = try await withTaskGroup(of: [AppItem].self) { group -> [AppItem] in
      for path in allowedSearchPaths {
        group.addTask { [weak fileManager = fileManager, weak workspace = workspace] in
          guard let fileManager, let workspace else { return [] }
          return Self.enumerateApplications(at: path, fileManager: fileManager, workspace: workspace)
        }
      }

      var aggregate: [AppItem] = []
      for await apps in group {
        aggregate.append(contentsOf: apps)
      }
      return aggregate
    }

    let uniqueItems = Dictionary(grouping: resources, by: { $0.bundleIdentifier }).compactMap { _, values in
      values.first
    }

    return uniqueItems.sorted(by: { $0.displayName.localizedCompare($1.displayName) == .orderedAscending })
  }

  // MARK: - Helpers

  private static func defaultSearchPaths() -> [URL] {
    var urls = [URL(fileURLWithPath: "/Applications", isDirectory: true)]
    if let userApplications = FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask).first {
      urls.append(userApplications)
    }
    return urls
  }

  private static func enumerateApplications(at directory: URL,
                                            fileManager: FileManager,
                                            workspace: NSWorkspace) -> [AppItem] {
    guard let enumerator = fileManager.enumerator(at: directory,
                                                 includingPropertiesForKeys: [.isDirectoryKey],
                                                 options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
      return []
    }

    var results: [AppItem] = []

    for case let fileURL as URL in enumerator {
      guard fileURL.pathExtension.lowercased() == "app" else { continue }

      if let bundle = Bundle(url: fileURL),
         let bundleIdentifier = bundle.bundleIdentifier {
        let displayName = bundle.displayName ?? fileURL.deletingPathExtension().lastPathComponent
        let categories = bundle.localizedCategories
        let icon = workspace.icon(forFile: fileURL.path)
        icon.size = NSSize(width: 128, height: 128)

        let item = AppItem(bundleIdentifier: bundleIdentifier,
                           displayName: displayName,
                           bundleURL: fileURL,
                           categories: categories,
                           icon: icon)
        results.append(item)
      }
    }

    return results
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

