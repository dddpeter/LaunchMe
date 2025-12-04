import AppKit
import Carbon

/// 管理全局快捷键的注册和处理
@MainActor
final class GlobalHotkeyManager: ObservableObject {
  
  // MARK: - Properties

  private var hotKeyRef: EventHotKeyRef?
  private var eventSpec: EventTypeSpec?
  private var onHotkeyPressed: () -> Void
  
  // MARK: - Initializer

  init(onHotkeyPressed: @escaping () -> Void = {}) {
    self.onHotkeyPressed = onHotkeyPressed
  }
  
  // MARK: - Public Methods

  /// 设置热键回调
  func setCallback(_ callback: @escaping () -> Void) {
    self.onHotkeyPressed = callback
  }

  /// 注册全局快捷键（默认：Option + Space）
  func registerGlobalHotkey(keyCode: UInt16 = 49, modifiers: UInt32 = UInt32(optionKey)) {
    // 先注销现有的快捷键
    unregisterGlobalHotkey()
    
    var gMyHotKeyRef: EventHotKeyRef?
    var hotKeyID = EventHotKeyID(signature: OSType(0x6864736B), // 'hdsk'
                                 id: 1)
    
    // 使用指针正确调用 RegisterEventHotKey
    let status = withUnsafeMutablePointer(to: &hotKeyID) { hotKeyIDPtr in
      RegisterEventHotKey(
        UInt32(keyCode),
        modifiers,
        hotKeyIDPtr.pointee,
        GetApplicationEventTarget(),
        0,
        &gMyHotKeyRef
      )
    }
    
    if status == noErr {
      self.hotKeyRef = gMyHotKeyRef
      
      // 设置事件监听
      var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                    eventKind: OSType(kEventHotKeyPressed))
      self.eventSpec = eventSpec
      
      InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
        guard let userData = userData else { return Int32(eventNotHandledErr) }
        let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
        manager.handleHotkeyPressed()
        return noErr
      }, 1, &eventSpec, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), nil)
    }
  }
  
  /// 注销全局快捷键
  func unregisterGlobalHotkey() {
    if let hotKeyRef = hotKeyRef {
      UnregisterEventHotKey(hotKeyRef)
      self.hotKeyRef = nil
    }
  }
  
  // MARK: - Private Methods
  
  /// 处理快捷键按下事件
  private func handleHotkeyPressed() {
    onHotkeyPressed()
  }
  
  deinit {
    // 在 deinit 中异步执行主线程清理操作
    // 注意：由于 deinit 的特殊性，这里使用 Task 异步执行
    // 捕获 hotKeyRef 以避免在异步执行时访问 self
    let hotKeyRefToUnregister = hotKeyRef
    Task { @MainActor in
      if let hotKeyRef = hotKeyRefToUnregister {
        UnregisterEventHotKey(hotKeyRef)
      }
    }
  }
}

// MARK: - Key Code Constants

extension GlobalHotkeyManager {
  /// 常用的按键代码
  enum KeyCode: UInt16 {
    case space = 49
    case returnKey = 36
    case tab = 48
    case escape = 53
    case command = 55
    case shift = 56
    case option = 58
    case control = 59
    case function = 63
  }
  
  /// 修饰键常量
  static let commandKey: UInt32 = UInt32(cmdKey)
  static let optionKey: UInt32 = UInt32(optionKey)
  static let controlKey: UInt32 = UInt32(controlKey)
  static let shiftKey: UInt32 = UInt32(shiftKey)
}