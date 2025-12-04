import AppKit
import SwiftUI

/// LaunchMe 应用的主管理器
@MainActor
final class LaunchMeAppManager: ObservableObject {

  // MARK: - Properties

  @Published private(set) var isLaunchpadVisible = false

  private let viewModel: LaunchpadViewModel
  private let windowManager: LaunchpadWindowManager
  private let hotkeyManager: GlobalHotkeyManager

  // MARK: - Initializer

  init() {
    let appDiscoveryService = AppDiscoveryService()
    let folderService = FolderPersistenceService()
    let searchViewModel = SearchViewModel()

    self.viewModel = LaunchpadViewModel(
      appDiscoveryService: appDiscoveryService,
      folderService: folderService,
      searchViewModel: searchViewModel
    )

    self.windowManager = LaunchpadWindowManager(viewModel: viewModel)

    // 创建热键管理器，使用静态方法创建回调
    self.hotkeyManager = GlobalHotkeyManager(onHotkeyPressed: {
      // 将在实例完全初始化后被调用
    })

    // 现在可以安全地设置回调，因为所有属性都已初始化
    self.hotkeyManager.setCallback { [weak self] in
      self?.toggleLaunchpad()
    }

    setupHotkey()
    preloadData()
  }

  // MARK: - Public Methods

  /// 切换 Launchpad 显示状态
  func toggleLaunchpad() {
    if isLaunchpadVisible {
      hideLaunchpad()
    } else {
      showLaunchpad()
    }
  }

  /// 显示 Launchpad
  func showLaunchpad() {
    guard !isLaunchpadVisible else { return }

    windowManager.showWindow()
    isLaunchpadVisible = true
  }

  /// 隐藏 Launchpad
  func hideLaunchpad() {
    guard isLaunchpadVisible else { return }

    windowManager.hideWindow()
    isLaunchpadVisible = false
  }

  /// 设置全局热键
  func setGlobalHotkey(keyCode: UInt16, modifiers: UInt32) {
    hotkeyManager.registerGlobalHotkey(keyCode: keyCode, modifiers: modifiers)
  }

  // MARK: - Private Methods

  private func setupHotkey() {
    // 注册默认热键 Option + Space
    hotkeyManager.registerGlobalHotkey(keyCode: 49, modifiers: 0x0200) // optionKey
  }

  private func preloadData() {
    // 预加载数据以提升用户体验
    viewModel.loadInitialData()
  }

  // MARK: - Cleanup

  deinit {
    // 在 deinit 中异步执行主线程清理操作
    // 注意：由于 deinit 的特殊性，这里使用 Task 异步执行
    // 实际清理会在主线程上异步完成
    Task { @MainActor [windowManager] in
      windowManager.cleanup()
    }
  }
}