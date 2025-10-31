import AppKit
import SwiftUI

/// LaunchpadRootView 为 LaunchMe 提供最小可运行的 UI 占位。
@MainActor
struct LaunchpadRootView: View {

  // MARK: - Properties
  /// 当前窗口的占位标题，后续版本将替换为动态内容。
  private let placeholderTitle = String(localized: "LaunchMe")

  // MARK: - Body
  var body: some View {
    VStack(spacing: 16) {
      Image(nsImage: appIcon)
        .resizable()
        .scaledToFit()
        .frame(width: 128, height: 128)
        .accessibilityIdentifier("launchpad-icon")

      Text(placeholderTitle)
        .font(.system(size: 28, weight: .semibold, design: .rounded))
        .padding(.horizontal, 24)

      Text(String(localized: "即将为你带来全新的 Launchpad 体验。"))
        .font(.system(size: 16))
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }
    .padding(40)
    .frame(minWidth: 480, minHeight: 360)
    .background(.regularMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    .shadow(radius: 18)
  }

  // MARK: - Private Methods
  /// 从当前应用上下文中获取 Launchpad 图标以保持视觉一致性。
  private var appIcon: NSImage { NSApplication.shared.applicationIconImage }

}

// MARK: - Preview
#Preview("占位视图") {
  LaunchpadRootView()
    .frame(width: 480, height: 360)
}
