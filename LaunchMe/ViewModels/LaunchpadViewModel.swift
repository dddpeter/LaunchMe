import AppKit
import Foundation
import Observation

/// 管理 Launchpad 状态和业务逻辑的视图模型。
@MainActor
final class LaunchpadViewModel: ObservableObject {

  // MARK: - Types

  enum ContentItem: Identifiable {

    case folder(FolderItem)
    case app(AppItem)

    var id: String {
      switch self {
      case let .folder(folder):
        return "folder-\(folder.id.uuidString)"
      case let .app(app):
        return "app-\(app.bundleIdentifier)"
      }
    }

  }

  // MARK: - Properties

  @Published private(set) var apps: [AppItem] = []
  @Published private(set) var folders: [FolderItem] = []
  @Published private(set) var isLoading = false
  @Published var loadingError: String?
  @Published private(set) var isVisible = false
  @Published private(set) var isAnimating = false
  @Published private(set) var activeFolderID: UUID?

  let searchViewModel: SearchViewModel

  private let appDiscoveryService: AppDiscoveryServicing
  private let folderService: FolderPersistenceServicing
  private var loadTask: Task<Void, Never>?

  // MARK: - Initializer

  init(appDiscoveryService: AppDiscoveryServicing,
       folderService: FolderPersistenceServicing,
       searchViewModel: SearchViewModel? = nil) {
    self.appDiscoveryService = appDiscoveryService
    self.folderService = folderService
    self.searchViewModel = searchViewModel ?? SearchViewModel()
  }

  // MARK: - Data Loading

  func loadInitialData() {
    guard loadTask == nil else { return }

    isLoading = true
    loadingError = nil

    loadTask = Task { [weak self] in
      guard let self else { return }
      
      // 开始加载数据
      
      do {
        async let appsTask = self.appDiscoveryService.discoverApplications()
        async let foldersTask = self.folderService.loadFolders()

        let (apps, folders) = try await (appsTask, foldersTask)
        
        self.apps = apps.isEmpty ? AppItem.placeholders() : apps
        self.folders = folders
        self.searchViewModel.updateSource(self.apps)
        self.isLoading = false
        
        // 数据加载完成
      } catch {
        self.loadingError = error.localizedDescription
        self.apps = AppItem.placeholders()
        self.searchViewModel.updateSource(self.apps)
        self.isLoading = false
        print("加载应用失败：\(error.localizedDescription)")
      }
      
      // 加载完成
      self.loadTask = nil
    }
  }

  // MARK: - Visibility Management

  func willShowWindow() {
    isAnimating = true
  }

  func didShowWindow() {
    isAnimating = false
    isVisible = true
  }

  func willHideWindow() {
    isAnimating = true
  }

  func didHideWindow() {
    isAnimating = false
    isVisible = false
    closeActiveFolder()
    searchViewModel.reset()
  }

  func toggleVisibility() -> Bool {
    let shouldShow = !isVisible
    if shouldShow {
      willShowWindow()
    } else {
      willHideWindow()
    }
    return shouldShow
  }

  // MARK: - Grid Content

  var gridItems: [ContentItem] {
    if isSearchActive {
      return searchViewModel.results.map { ContentItem.app($0) }
    }

    let folderItems = folders.compactMap { folder -> ContentItem? in
      let appsInFolder = self.apps(in: folder)
      return appsInFolder.isEmpty ? nil : .folder(folder)
    }

    let ungroupedItems = ungroupedApps.map { ContentItem.app($0) }
    return folderItems + ungroupedItems
  }

  var displayedApps: [AppItem] {
    searchViewModel.displayedApps(fallback: apps)
  }

  var activeFolder: FolderItem? {
    guard let activeFolderID else { return nil }
    return folders.first(where: { $0.id == activeFolderID })
  }

  var activeFolderApps: [AppItem] {
    guard let activeFolder else { return [] }
    return apps(in: activeFolder)
  }

  var isSearchActive: Bool {
    !searchViewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  // MARK: - App & Folder Helpers

  func apps(in folder: FolderItem) -> [AppItem] {
    let dictionary = appDictionary
    return folder.appBundleIdentifiers.compactMap { dictionary[$0] }
  }

  func apps(in folderID: UUID) -> [AppItem] {
    guard let folder = folders.first(where: { $0.id == folderID }) else { return [] }
    return apps(in: folder)
  }

  var ungroupedApps: [AppItem] {
    let groupedIdentifiers = Set(folders.flatMap { $0.appBundleIdentifiers })
    return apps.filter { !groupedIdentifiers.contains($0.bundleIdentifier) }
  }

  func app(for bundleIdentifier: String) -> AppItem? {
    appDictionary[bundleIdentifier]
  }

  func foldersContaining(app: AppItem) -> [FolderItem] {
    folders.filter { $0.appBundleIdentifiers.contains(app.bundleIdentifier) }
  }

  func isAppGrouped(_ app: AppItem) -> Bool {
    foldersContaining(app: app).isEmpty == false
  }

  // MARK: - Folder Lifecycle

  func openFolder(_ folder: FolderItem) {
    activeFolderID = folder.id
  }

  func closeActiveFolder() {
    activeFolderID = nil
  }

  func createFolder(named name: String) {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    
    // 开始创建文件夹
    
    let folder = FolderItem(name: trimmed, appBundleIdentifiers: [])
    folders.append(folder)
    persistFolders()
    
    // 文件夹创建完成
    print("已创建文件夹：\(trimmed)")
  }

  func renameFolder(id: UUID, to newName: String) {
    guard let index = folders.firstIndex(where: { $0.id == id }) else { return }
    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    
    // 开始重命名文件夹
    
    let oldName = folders[index].name
    folders[index].name = trimmed
    persistFolders()
    
    // 文件夹重命名完成
    print("已重命名文件夹：\(oldName) → \(trimmed)")
  }

  func deleteFolder(id: UUID) {
    folders.removeAll { $0.id == id }
    if activeFolderID == id {
      activeFolderID = nil
    }
    persistFolders()
  }

  func addApp(_ app: AppItem, to folderID: UUID) {
    guard let index = folders.firstIndex(where: { $0.id == folderID }) else { return }
    
    // 开始添加应用到文件夹
    
    removeApp(app)
    folders[index].appBundleIdentifiers.append(app.bundleIdentifier)
    persistFolders()
    
    // 应用添加完成
    if let folder = folders[safe: index] {
      print("已将 \(app.displayName) 添加到 \(folder.name)")
    }
  }

  func removeApp(_ app: AppItem, from folderID: UUID) {
    guard let index = folders.firstIndex(where: { $0.id == folderID }) else { return }
    folders[index].appBundleIdentifiers.removeAll { $0 == app.bundleIdentifier }
    persistFolders()
  }

  func removeApp(_ app: AppItem) {
    var didModify = false
    for index in folders.indices {
      let originalCount = folders[index].appBundleIdentifiers.count
      folders[index].appBundleIdentifiers.removeAll { $0 == app.bundleIdentifier }
      if folders[index].appBundleIdentifiers.count != originalCount {
        didModify = true
      }
    }
    if didModify { persistFolders() }
  }

  // MARK: - App Actions

  func openApp(_ app: AppItem) {
    print("正在启动 \(app.displayName)...")
    
    let url = app.bundleURL
    let pathExtension = url.pathExtension.lowercased()

    switch pathExtension {
    case "app":
      launchBundleApplication(at: url, bundleIdentifier: app.bundleIdentifier, appName: app.displayName)
    case "prefpane":
      // 系统偏好设置面板需要走 open 才能正确加载。
      if NSWorkspace.shared.open(url) {
        print("已打开 \(app.displayName)")
      } else {
        print("无法打开 \(app.displayName)")
      }
    default:
      if NSWorkspace.shared.open(url) {
        print("已打开 \(app.displayName)")
      } else {
        launchBundleApplication(at: url, bundleIdentifier: app.bundleIdentifier, appName: app.displayName)
      }
    }
  }

  func revealInFinder(_ app: AppItem) {
    NSWorkspace.shared.activateFileViewerSelecting([app.bundleURL])
    print("已在访达中显示 \(app.displayName)")
  }

  // MARK: - Private Helpers

  private var appDictionary: [String: AppItem] {
    Dictionary(uniqueKeysWithValues: apps.map { ($0.bundleIdentifier, $0) })
  }

  private func persistFolders() {
    let foldersToSave = folders
    let service = folderService
    Task { [weak self] in
      do {
        try await service.saveFolders(foldersToSave)
      } catch {
        self?.loadingError = error.localizedDescription
        print("保存文件夹失败：\(error.localizedDescription)")
      }
    }
  }

  private func launchBundleApplication(at url: URL, bundleIdentifier: String, appName: String) {
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = true
    configuration.promptsUserIfNeeded = true
    configuration.addsToRecentItems = true

    NSWorkspace.shared.openApplication(at: url, configuration: configuration) { [weak self] runningApp, error in
      if let error {
        Task { @MainActor [weak self] in
          self?.loadingError = error.localizedDescription
          print("启动 \(appName) 失败：\(error.localizedDescription)")
        }
        return
      }
      guard runningApp == nil else { return }

      // 如果没有返回运行实例，尝试通过 bundle identifier 查找实际路径后再次启动。
      guard let fallbackURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier),
            fallbackURL != url else {
        Task { @MainActor [weak self] in
          let message = "无法启动应用：\(bundleIdentifier)"
          self?.loadingError = message
          print(message)
        }
        return
      }

      NSWorkspace.shared.openApplication(at: fallbackURL, configuration: configuration) { [weak self] _, fallbackError in
        if let fallbackError {
          Task { @MainActor [weak self] in
            let message = "启动 \(appName) 失败：\(fallbackError.localizedDescription)"
            self?.loadingError = message
            print(message)
          }
        }
      }
    }
  }

}

// MARK: - Array Extension

private extension Array {
  subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

