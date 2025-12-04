import AppKit
import SwiftUI

/// Launchpad 专用的无边框全屏窗口
final class LaunchpadWindow: NSWindow {
  
  // MARK: - Properties
  
  private let viewModel: LaunchpadViewModel
  private var contentViewHost: NSHostingView<LaunchpadRootView>?

  // MARK: - Initializer

  init(viewModel: LaunchpadViewModel) {
    self.viewModel = viewModel

    // 创建无边框全屏窗口
    super.init(
      contentRect: .zero,
      styleMask: [.borderless, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )

    setupWindow()
    setupContentView()
  }
  
  // MARK: - Setup Methods
  
  private func setupWindow() {
    // 设置窗口属性
    level = .floating
    backgroundColor = .clear
    isOpaque = false
    hasShadow = false
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    ignoresMouseEvents = false
    
    // 设置窗口为全屏但不遮挡菜单栏
    if let screen = NSScreen.main {
      let screenFrame = screen.visibleFrame
      setFrame(screenFrame, display: false)
    }
    
    // 监听窗口事件
    setupWindowNotifications()
  }
  
  private func setupContentView() {
    let contentView = LaunchpadRootView(viewModel: viewModel)
    let hostingView = NSHostingView(rootView: contentView)

    hostingView.translatesAutoresizingMaskIntoConstraints = false
    contentViewHost = hostingView

    self.contentView = hostingView

    // 设置约束 - NSWindow本身不提供layout anchors，需要使用contentView的frame
    hostingView.frame = self.contentView?.bounds ?? CGRect.zero
    hostingView.autoresizingMask = [.width, .height]
  }
  
  private func setupWindowNotifications() {
    // 监听窗口失焦事件
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(windowDidResignKey),
      name: NSWindow.didResignKeyNotification,
      object: self
    )
    
    // 监听屏幕变化事件
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenParametersChanged),
      name: NSApplication.didChangeScreenParametersNotification,
      object: nil
    )
  }
  
  // MARK: - Event Handling
  
  override func keyDown(with event: NSEvent) {
    // ESC 键关闭窗口
    if event.keyCode == 53 {
      _ = viewModel.toggleVisibility()
      return
    }
    
    // Command + Q 退出应用
    if event.keyCode == 12 && event.modifierFlags.contains(.command) {
      NSApplication.shared.terminate(nil)
      return
    }
    
    super.keyDown(with: event)
  }
  
  override func mouseDown(with event: NSEvent) {
    // 检查点击是否在窗口内容区域外
    let contentRect = contentView?.frame ?? .zero
    let clickPoint = event.locationInWindow
    
    if !contentRect.contains(clickPoint) {
      // 点击窗口外部，关闭窗口
      _ = viewModel.toggleVisibility()
      return
    }
    
    super.mouseDown(with: event)
  }
  
  // MARK: - Notification Handlers
  
  @objc private func windowDidResignKey() {
    // 窗口失焦时自动隐藏
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      guard let self = self else { return }
      if self.isVisible && !self.isKeyWindow {
        _ = self.viewModel.toggleVisibility()
      }
    }
  }
  
  @objc private func screenParametersChanged() {
    // 屏幕参数变化时更新窗口尺寸
    DispatchQueue.main.async { [weak self] in
      guard let self = self, let screen = NSScreen.main else { return }
      let screenFrame = screen.visibleFrame
      self.setFrame(screenFrame, display: true)
    }
  }
  
  // MARK: - Cleanup
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}

// MARK: - Window Extensions

extension LaunchpadWindow {
  
  /// 检查窗口是否真正可见（不仅仅是已创建）
  var isWindowVisible: Bool {
    isVisible && !isMiniaturized
  }
  
  /// 安全地关闭窗口
  func safeClose() {
    orderOut(nil)
    close()
  }
}