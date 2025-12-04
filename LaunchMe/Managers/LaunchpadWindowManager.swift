import AppKit
import SwiftUI

/// 管理 Launchpad 窗口的创建、显示和隐藏
@MainActor
final class LaunchpadWindowManager: ObservableObject {
  
  // MARK: - Properties
  
  private var launchpadWindow: LaunchpadWindow?
  private let viewModel: LaunchpadViewModel
  
  // MARK: - Initializer
  
  init(viewModel: LaunchpadViewModel) {
    self.viewModel = viewModel
  }
  
  // MARK: - Public Methods
  
  /// 创建并显示 Launchpad 窗口
  func showWindow() {
    if launchpadWindow == nil {
      launchpadWindow = LaunchpadWindow(viewModel: viewModel)
    }
    
    guard let window = launchpadWindow else { return }
    
    viewModel.willShowWindow()
    
    // 设置窗口为全屏
    if let screen = NSScreen.main {
      let screenFrame = screen.visibleFrame
      window.setFrame(screenFrame, display: true)
    }
    
    window.makeKeyAndOrderFront(nil)
    
    // 动画显示窗口
    WindowAnimator.show(window) { [weak self] in
      self?.viewModel.didShowWindow()
    }
  }
  
  /// 隐藏 Launchpad 窗口
  func hideWindow() {
    guard let window = launchpadWindow else { return }
    
    viewModel.willHideWindow()
    
    WindowAnimator.hide(window) { [weak self] in
      window.orderOut(nil)
      self?.viewModel.didHideWindow()
    }
  }
  
  /// 切换窗口显示状态
  func toggleWindow() {
    if launchpadWindow?.isWindowVisible == true {
      hideWindow()
    } else {
      showWindow()
    }
  }
  
  /// 检查窗口是否可见
  var isWindowVisible: Bool {
    launchpadWindow?.isWindowVisible ?? false
  }
  
  /// 检查窗口是否正在动画
  var isWindowAnimating: Bool {
    viewModel.isAnimating
  }
  
  // MARK: - Private Methods
  
  /// 清理窗口资源
  func cleanup() {
    launchpadWindow?.close()
    launchpadWindow = nil
  }
}

// MARK: - WindowAnimator

/// 窗口动画工具
struct WindowAnimator {
  
  /// 显示窗口动画
  static func show(_ window: NSWindow, completion: @escaping () -> Void) {
    // 设置初始状态
    window.alphaValue = 0.0
    window.setFrameOrigin(CGPoint(x: window.frame.origin.x, y: -window.frame.height))
    window.makeKeyAndOrderFront(nil)
    
    // 执行动画
    NSAnimationContext.runAnimationGroup({ context in
      context.duration = 0.4
      context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      context.allowsImplicitAnimation = true
      
      // 淡入和位移动画
      window.animator().alphaValue = 1.0
      window.animator().setFrameOrigin(CGPoint(x: window.frame.origin.x, y: 0))
      
      // 添加缩放效果
      if let contentView = window.contentView {
        let originalFrame = contentView.frame
        let scaledFrame = CGRect(
          x: originalFrame.origin.x - originalFrame.width * 0.1,
          y: originalFrame.origin.y - originalFrame.height * 0.1,
          width: originalFrame.width * 1.2,
          height: originalFrame.height * 1.2
        )
        
        contentView.frame = scaledFrame
        contentView.animator().frame = originalFrame
      }
    }, completionHandler: completion)
  }
  
  /// 隐藏窗口动画
  static func hide(_ window: NSWindow, completion: @escaping () -> Void) {
    NSAnimationContext.runAnimationGroup({ context in
      context.duration = 0.3
      context.timingFunction = CAMediaTimingFunction(name: .easeIn)
      context.allowsImplicitAnimation = true
      
      // 淡出和位移动画
      window.animator().alphaValue = 0.0
      window.animator().setFrameOrigin(CGPoint(x: window.frame.origin.x, y: -window.frame.height))
      
      // 添加缩放效果
      if let contentView = window.contentView {
        let originalFrame = contentView.frame
        let scaledFrame = CGRect(
          x: originalFrame.origin.x - originalFrame.width * 0.05,
          y: originalFrame.origin.y - originalFrame.height * 0.05,
          width: originalFrame.width * 1.1,
          height: originalFrame.height * 1.1
        )
        
        contentView.animator().frame = scaledFrame
      }
    }, completionHandler: completion)
  }
  
  /// 弹性动画效果
  static func bounce(_ window: NSWindow) {
    NSAnimationContext.runAnimationGroup({ context in
      context.duration = 0.6
      context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      context.allowsImplicitAnimation = true
      
      if let contentView = window.contentView {
        let originalFrame = contentView.frame
        let bounceFrame = CGRect(
          x: originalFrame.origin.x - 10,
          y: originalFrame.origin.y - 10,
          width: originalFrame.width + 20,
          height: originalFrame.height + 20
        )
        
        contentView.animator().frame = bounceFrame
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          contentView.animator().frame = originalFrame
        }
      }
    })
  }
  
  /// 震动效果
  static func shake(_ window: NSWindow) {
    let originalFrame = window.frame
    let shakeDistance: CGFloat = 8
    
    NSAnimationContext.runAnimationGroup({ context in
      context.duration = 0.4
      context.allowsImplicitAnimation = true
      
      // 左震动
      window.animator().setFrameOrigin(CGPoint(x: originalFrame.origin.x - shakeDistance, y: originalFrame.origin.y))
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        // 右震动
        window.animator().setFrameOrigin(CGPoint(x: originalFrame.origin.x + shakeDistance, y: originalFrame.origin.y))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          // 左震动
          window.animator().setFrameOrigin(CGPoint(x: originalFrame.origin.x - shakeDistance / 2, y: originalFrame.origin.y))
          
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 回到原位
            window.animator().setFrameOrigin(originalFrame.origin)
          }
        }
      }
    })
  }
}