import SwiftUI

/// 展示文件夹详细内容的浮层视图。
struct FolderOverlayView: View {

  // MARK: - Properties

  let folder: FolderItem
  let apps: [AppItem]
  let onClose: () -> Void
  let onOpenApp: (AppItem) -> Void
  let onRemoveApp: (AppItem) -> Void
  let onRevealApp: (AppItem) -> Void

  private let gridColumns = [GridItem(.adaptive(minimum: 120, maximum: 160), spacing: 16, alignment: .top)]

  // MARK: - Body

  var body: some View {
    VStack(spacing: 16) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(folder.name)
            .font(.system(size: 22, weight: .semibold))
          Text("共 \(apps.count) 个应用")
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
        }

        Spacer()

        Button(role: .cancel, action: onClose) {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 22, weight: .semibold))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("关闭文件夹")
      }

      Divider()

      ScrollView {
        LazyVGrid(columns: gridColumns, spacing: 20) {
          ForEach(apps) { app in
            AppGridItemView(app: app, isGrouped: true)
              .onTapGesture { onOpenApp(app) }
              .contextMenu {
                Button("打开") { onOpenApp(app) }
                Button("在访达中显示") { onRevealApp(app) }
                Divider()
                Button(role: .destructive) {
                  onRemoveApp(app)
                } label: {
                  Label("从文件夹移除", systemImage: "folder.badge.minus")
                }
              }
          }
        }
        .padding(.bottom, 8)
      }
    }
    .padding(24)
    .frame(minWidth: 520, maxWidth: 640, minHeight: 360, maxHeight: 520)
    .background(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(.regularMaterial)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .strokeBorder(Color.white.opacity(0.12))
    )
    .shadow(color: .black.opacity(0.45), radius: 24, y: 20)
  }

}

