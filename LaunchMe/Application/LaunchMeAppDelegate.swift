import AppKit

/// LaunchMe 应用的 NSApplicationDelegate 实现
/// 负责处理应用生命周期事件和菜单栏设置
class LaunchMeAppDelegate: NSObject, NSApplicationDelegate {

  // MARK: - Properties

  private var appManager: LaunchMeAppManager!

  // MARK: - NSApplicationDelegate

  func applicationDidFinishLaunching(_ notification: Notification) {
    // 设置应用
    setupApplication()

    // 创建应用管理器
    appManager = LaunchMeAppManager()

    // 设置菜单栏
    setupMenuBar()

    // 不自动显示Launchpad，用户通过Dock图标或快捷键手动显示

    print("LaunchMe 启动完成，按 Option + Space 打开 Launchpad")
  }

  func applicationWillTerminate(_ notification: Notification) {
    // 清理资源
    appManager = nil
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    // 点击 Dock 图标时激活应用并显示 Launchpad
    if !flag {
      // 先激活应用，确保其成为前台应用
      NSApplication.shared.activate(ignoringOtherApps: true)

      // 然后显示 Launchpad
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.appManager?.showLaunchpad()
      }
    }
    return true
  }

  // MARK: - Private Methods

  private func setupApplication() {
    // 设置应用图标
    if let icon = NSImage(named: NSImage.applicationIconName) {
      NSApplication.shared.applicationIconImage = icon
    }

    // 设置应用行为 - 作为后台应用运行，通过Dock图标激活
    NSApplication.shared.setActivationPolicy(.regular)

    // 不自动激活应用，等待用户交互
    // NSApplication.shared.activate(ignoringOtherApps: true)
  }

  private func setupMenuBar() {
    let mainMenu = NSMenu()

    // 应用菜单
    let appMenuItem = NSMenuItem()
    mainMenu.addItem(appMenuItem)

    let appMenu = NSMenu()
    appMenuItem.submenu = appMenu

    // 添加 "关于 LaunchMe"
    appMenu.addItem(NSMenuItem(title: "关于 LaunchMe", action: #selector(showAbout), keyEquivalent: ""))

    // 添加分隔符
    appMenu.addItem(NSMenuItem.separator())

    // 添加 "偏好设置"
    appMenu.addItem(NSMenuItem(title: "偏好设置...", action: #selector(showPreferences), keyEquivalent: ","))

    // 添加分隔符
    appMenu.addItem(NSMenuItem.separator())

    // 添加 "退出"
    appMenu.addItem(NSMenuItem(title: "退出 LaunchMe", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

    // 窗口菜单
    let windowMenuItem = NSMenuItem()
    mainMenu.addItem(windowMenuItem)

    let windowMenu = NSMenu()
    windowMenuItem.submenu = windowMenu
    windowMenu.title = "窗口"

    // 添加 "显示 Launchpad"
    windowMenu.addItem(NSMenuItem(title: "显示 Launchpad", action: #selector(showLaunchpad), keyEquivalent: "l"))

    // 添加分隔符
    windowMenu.addItem(NSMenuItem.separator())

    // 添加 "最小化"
    windowMenu.addItem(NSMenuItem(title: "最小化", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m"))

    NSApplication.shared.mainMenu = mainMenu
  }

  // MARK: - Menu Actions

  @objc private func showAbout() {
    let alert = NSAlert()
    alert.messageText = "LaunchMe"
    alert.informativeText = "一个现代化的 macOS Launchpad 替代工具\n\n按 Option + Space 打开 Launchpad"
    alert.alertStyle = .informational
    alert.addButton(withTitle: "确定")
    alert.runModal()
  }

  @objc private func showPreferences() {
    // TODO: 实现偏好设置窗口
    let alert = NSAlert()
    alert.messageText = "偏好设置"
    alert.informativeText = "偏好设置功能即将推出"
    alert.alertStyle = .informational
    alert.addButton(withTitle: "确定")
    alert.runModal()
  }

  @objc private func showLaunchpad() {
    Task { @MainActor in
      appManager?.showLaunchpad()
    }
  }
}

