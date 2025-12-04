import AppKit
import SwiftUI

/// 展示单个应用的图标与名称。
struct AppGridItemView: View {

  // MARK: - Properties

  let app: AppItem
  let isGrouped: Bool
  /// 图标的目标边长，来自网格布局。
  let iconSize: CGFloat
  private let labelWidthPadding: CGFloat = 40

  /// 允许使用默认图标尺寸创建视图。
  init(app: AppItem, isGrouped: Bool, iconSize: CGFloat = 96) {
    self.app = app
    self.isGrouped = isGrouped
    self.iconSize = iconSize
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: 10) {
      Image(nsImage: app.resolvedIcon)
        .resizable()
        .scaledToFit()
        .frame(width: iconSize, height: iconSize)
        .clipShape(RoundedRectangle(cornerRadius: iconSize * 0.22, style: .continuous))
        .shadow(color: .black.opacity(0.28), radius: 8, y: 6)

      Text(app.displayName)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(Color.white.opacity(0.92))
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .frame(maxWidth: iconSize + labelWidthPadding)

      if isGrouped {
        Text("已在文件夹中")
          .font(.system(size: 10))
          .padding(.horizontal, 10)
          .padding(.vertical, 3)
          .background(.ultraThinMaterial, in: Capsule())
          .foregroundStyle(Color.white.opacity(0.8))
      }
    }
    .frame(maxWidth: .infinity)
    .contentShape(Rectangle())
    .accessibilityElement(children: .combine)
    .accessibilityLabel(Text(app.displayName))
  }
}

