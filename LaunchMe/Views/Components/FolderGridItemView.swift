import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// 展示文件夹概览的网格单元。
struct FolderGridItemView: View {

  // MARK: - Properties

  let folder: FolderItem
  let apps: [AppItem]
  /// 当前布局约束下的单元格目标宽度。
  let cellWidth: CGFloat
  /// 相对于默认图标尺寸的缩放系数。
  let iconScale: CGFloat
  let onTap: () -> Void
  let onDropApp: (String) -> Void

  private let iconColumns = [GridItem(.flexible()), GridItem(.flexible())]
  private var folderBackground: LinearGradient {
    let colors: [Color] = [
      .purple.opacity(0.8),
      .blue.opacity(0.7)
    ]
    return LinearGradient(
      colors: colors,
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  private var clampedScale: CGFloat {
    max(0.75, min(iconScale, 1.15))
  }

  private var folderSideLength: CGFloat {
    120 * clampedScale
  }

  private var innerIconSize: CGFloat {
    40 * clampedScale
  }

  private var containerPadding: CGFloat {
    16 * clampedScale
  }

  private var verticalSpacing: CGFloat {
    12 * clampedScale
  }

  private var innerGridSpacing: CGFloat {
    6 * clampedScale
  }

  private var titleFont: Font {
    .system(size: 15 * (0.92 + 0.08 * clampedScale), weight: .semibold)
  }

  private var detailFont: Font {
    .system(size: 12 * (0.94 + 0.06 * clampedScale))
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: verticalSpacing) {
      ZStack {
        RoundedRectangle(cornerRadius: 22 * clampedScale, style: .continuous)
          .fill(folderBackground)

        LazyVGrid(columns: iconColumns, spacing: innerGridSpacing) {
          ForEach(apps.prefix(4)) { app in
            Image(nsImage: app.resolvedIcon)
              .resizable()
              .scaledToFill()
              .frame(width: innerIconSize, height: innerIconSize)
              .clipShape(RoundedRectangle(cornerRadius: 10 * clampedScale, style: .continuous))
          }

          if apps.count < 4 {
            ForEach(0..<(4 - min(apps.count, 4)), id: \.self) { _ in
              RoundedRectangle(cornerRadius: 10 * clampedScale, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .frame(width: innerIconSize, height: innerIconSize)
            }
          }
        }
        .padding(containerPadding + 2)
      }
      .frame(width: folderSideLength, height: folderSideLength)
      .shadow(color: .black.opacity(0.35), radius: 10 * clampedScale, y: 6 * clampedScale)

      VStack(spacing: verticalSpacing * 0.6) {
        Text(folder.name)
          .font(titleFont)
          .multilineTextAlignment(.center)
          .lineLimit(2)

        Text("共 \(apps.count) 个应用")
          .font(detailFont)
          .foregroundStyle(.secondary)
      }
    }
    .padding(containerPadding)
    .frame(width: cellWidth)
    .background(
      RoundedRectangle(cornerRadius: 24 * clampedScale, style: .continuous)
        .fill(Color(nsColor: .windowBackgroundColor).opacity(0.85))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 24 * clampedScale, style: .continuous)
        .strokeBorder(Color.white.opacity(0.1))
    )
    .onTapGesture(perform: onTap)
    .onDrop(of: [UTType.text], isTargeted: nil) { providers in
      providers.loadFirstBundleIdentifier { bundleID in
        guard let bundleID else { return }
        onDropApp(bundleID)
      }
      return true
    }
  }

}

// MARK: - Drop Helpers

private extension Sequence where Element == NSItemProvider {

  func loadFirstBundleIdentifier(_ handler: @escaping (String?) -> Void) {
    guard let provider = first(where: { $0.canLoadObject(ofClass: NSString.self) }) else {
      handler(nil)
      return
    }
    provider.loadObject(ofClass: NSString.self) { object, _ in
      handler(object as? String)
    }
  }

}

