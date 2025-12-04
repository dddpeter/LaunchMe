import SwiftUI

/// Toast 通知视图
struct ToastNotification: View {

  // MARK: - Properties

  let message: String
  let type: ToastType
  let isVisible: Binding<Bool>

  @State private var internalIsVisible = false
  
  // MARK: - Body
  
  var body: some View {
    HStack(spacing: 12) {
      icon
        .font(.system(size: 20, weight: .semibold))

      Text(message)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.primary)

      Spacer()

      Button {
        isVisible.wrappedValue = false
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(.regularMaterial)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(overlayColor, lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    .scaleEffect(internalIsVisible ? 1.0 : 0.8)
    .opacity(internalIsVisible ? 1.0 : 0.0)
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: internalIsVisible)
    .onAppear {
      internalIsVisible = true
      isVisible.wrappedValue = true

      // 自动消失
      DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        if internalIsVisible {
          isVisible.wrappedValue = false
        }
      }
    }
      }
  
  // MARK: - View Components
  
  private var icon: some View {
    switch type {
    case .success:
      Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(.green)
    case .error:
      Image(systemName: "xmark.circle.fill")
        .foregroundStyle(.red)
    case .info:
      Image(systemName: "info.circle.fill")
        .foregroundStyle(.blue)
    case .warning:
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.orange)
    }
  }
  
  private var overlayColor: Color {
    switch type {
    case .success:
      return .green.opacity(0.3)
    case .error:
      return .red.opacity(0.3)
    case .info:
      return .blue.opacity(0.3)
    case .warning:
      return .orange.opacity(0.3)
    }
  }
}

// MARK: - Toast Type

enum ToastType {
  case success
  case error
  case info
  case warning
}

// MARK: - Toast Manager

@MainActor
class ToastManager: ObservableObject {
  
  // MARK: - Properties
  
  @Published fileprivate(set) var toasts: [ToastItem] = []
  
  // MARK: - Public Methods
  
  func show(_ message: String, type: ToastType = .info) {
    let toast = ToastItem(message: message, type: type)
    toasts.append(toast)
    
    // 自动移除
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
      self.removeToast(toast.id)
    }
  }
  
  func showSuccess(_ message: String) {
    show(message, type: .success)
  }
  
  func showError(_ message: String) {
    show(message, type: .error)
  }
  
  func showWarning(_ message: String) {
    show(message, type: .warning)
  }
  
  func removeToast(_ id: UUID) {
    toasts.removeAll { $0.id == id }
  }
  
  func clearAll() {
    toasts.removeAll()
  }
}

// MARK: - Toast Item

struct ToastItem: Identifiable, Equatable {
  let id: UUID
  let message: String
  let type: ToastType

  init(message: String, type: ToastType) {
    self.id = UUID()
    self.message = message
    self.type = type
  }

  static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
    return lhs.id == rhs.id
  }
}

// MARK: - Toast Container View

struct ToastContainerView: View {

  // MARK: - Properties

  @ObservedObject var toastManager: ToastManager
  @State private var visibleToasts: [UUID: Bool] = [:]

  // MARK: - Body

  var body: some View {
    VStack(spacing: 8) {
      ForEach(toastManager.toasts) { toast in
        ToastNotification(
          message: toast.message,
          type: toast.type,
          isVisible: Binding(
            get: { visibleToasts[toast.id] ?? false },
            set: { newValue in
              if !newValue {
                visibleToasts.removeValue(forKey: toast.id)
                toastManager.removeToast(toast.id)
              }
            }
          )
        )
        .transition(.asymmetric(
          insertion: .move(edge: .top).combined(with: .opacity),
          removal: .move(edge: .top).combined(with: .opacity)
        ))
      }
    }
    .padding(.top, 20)
    .padding(.horizontal, 20)
    .onReceive(toastManager.$toasts) { newToasts in
      // 为新的toast初始化可见状态
      let currentIds = Set(newToasts.map { $0.id })
      let visibleIds = Set(visibleToasts.keys)

      // 移除不再存在的toast
      visibleIds.subtracting(currentIds).forEach { id in
        visibleToasts.removeValue(forKey: id)
      }

      // 为新的toast设置为可见
      currentIds.subtracting(visibleIds).forEach { id in
        visibleToasts[id] = true
      }
    }
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toastManager.toasts)
  }
}

// MARK: - View Modifier

extension View {
  /// 显示 Toast 通知
  func toast(toastManager: ToastManager) -> some View {
    self.overlay(
      VStack {
        ToastContainerView(toastManager: toastManager)
        Spacer()
      },
      alignment: .top
    )
  }
}

// MARK: - Preview

#Preview("ToastNotification") {
  struct Wrapper: View {
    @State private var isVisible1 = true
    @State private var isVisible2 = true
    @State private var isVisible3 = true
    @State private var isVisible4 = true

    var body: some View {
      VStack(spacing: 20) {
        ToastNotification(
          message: "应用启动成功",
          type: .success,
          isVisible: $isVisible1
        )

        ToastNotification(
          message: "启动失败：应用未找到",
          type: .error,
          isVisible: $isVisible2
        )

        ToastNotification(
          message: "正在启动应用...",
          type: .info,
          isVisible: $isVisible3
        )

        ToastNotification(
          message: "权限不足",
          type: .warning,
          isVisible: $isVisible4
        )
      }
      .padding()
    }
  }

  return Wrapper()
}

#Preview("ToastContainer") {
  struct Wrapper: View {
    @StateObject private var toastManager = ToastManager()
    
    var body: some View {
      Color.gray.opacity(0.3)
        .ignoresSafeArea()
        .toast(toastManager: toastManager)
        .onAppear {
          toastManager.showSuccess("第一个通知")
          
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            toastManager.showError("第二个通知")
          }
          
          DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            toastManager.showWarning("第三个通知")
          }
        }
    }
  }
  
  return Wrapper()
}