import AppKit
import SwiftUI

/// LaunchpadRootView 为 LaunchMe 提供完整的主界面
@MainActor
struct LaunchpadRootView: View {

  // MARK: - Properties

  @StateObject private var viewModel: LaunchpadViewModel
  @StateObject private var toastManager = ToastManager()
  @State private var isLoading = false

  // MARK: - Initializer

  init(viewModel: LaunchpadViewModel? = nil) {
    if let viewModel = viewModel {
      _viewModel = StateObject(wrappedValue: viewModel)
    } else {
      let appDiscoveryService = AppDiscoveryService()
      let folderService = FolderPersistenceService()
      let searchViewModel = SearchViewModel()
      _viewModel = StateObject(wrappedValue: LaunchpadViewModel(
        appDiscoveryService: appDiscoveryService,
        folderService: folderService,
        searchViewModel: searchViewModel
      ))
    }
  }

  // MARK: - Body

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // 背景渐变
        backgroundView

        VStack(spacing: 0) {
          // 顶部标题栏
          topBar
            .padding(.top, 20)

          // 搜索栏
          searchBarSection
            .padding(.horizontal, 40)
            .padding(.vertical, 16)

          // 主内容区域
          mainContent(geometry: geometry)
        }

        VStack {
            HStack {
              Spacer()
              ToastContainerView(toastManager: toastManager)
            }
            Spacer()
          }
          .zIndex(1000)
      }
    }
    .onAppear {
      viewModel.loadInitialData()
    }
    .onReceive(viewModel.$loadingError) { error in
      if let error = error {
        toastManager.showError(error)
      }
    }
  }

  // MARK: - View Components

  private var backgroundView: some View {
    LinearGradient(
      colors: [
        Color(red: 0.1, green: 0.1, blue: 0.2),
        Color(red: 0.2, green: 0.1, blue: 0.3),
        Color(red: 0.1, green: 0.2, blue: 0.4)
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
    .ignoresSafeArea()
  }

  private var topBar: some View {
    HStack {
      Image(nsImage: NSApplication.shared.applicationIconImage)
        .resizable()
        .scaledToFit()
        .frame(width: 32, height: 32)
        .clipShape(RoundedRectangle(cornerRadius: 8))

      Text("LaunchMe")
        .font(.system(size: 24, weight: .bold, design: .rounded))
        .foregroundStyle(.white)

      Spacer()

      // 关闭按钮
      Button {
        // 通知窗口管理器关闭窗口
        NotificationCenter.default.post(name: NSNotification.Name("HideLaunchpad"), object: nil)
      } label: {
        Image(systemName: "xmark.circle.fill")
          .font(.system(size: 20))
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
      .keyboardShortcut(.escape)
    }
    .padding(.horizontal, 40)
  }

  private var searchBarSection: some View {
    SearchBarView(
      text: .init(
        get: { viewModel.searchViewModel.query },
        set: { viewModel.searchViewModel.updateQuery($0) }
      ),
      placeholder: "搜索应用或文件夹",
      isLoading: viewModel.isLoading,
      onClear: {
        viewModel.searchViewModel.reset()
      }
    )
  }

  private func mainContent(geometry: GeometryProxy) -> some View {
    Group {
      if viewModel.isLoading {
        loadingView
      } else if let activeFolder = viewModel.activeFolder {
        folderContent(folder: activeFolder, geometry: geometry)
      } else {
        DraggableAppGrid(
          items: viewModel.gridItems,
          viewModel: viewModel,
          geometry: geometry,
          onFolderCreated: {
            toastManager.showSuccess("文件夹已创建")
          }
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 40)
    .padding(.bottom, 40)
  }

  private var loadingView: some View {
    VStack(spacing: 20) {
      ProgressView()
        .scaleEffect(1.5)
        .progressViewStyle(CircularProgressViewStyle(tint: .white))

      Text("正在加载应用...")
        .font(.headline)
        .foregroundStyle(.white)
    }
  }

  private func folderContent(folder: FolderItem, geometry: GeometryProxy) -> some View {
    VStack(spacing: 16) {
      // 文件夹标题栏
      HStack {
        Button {
          viewModel.closeActiveFolder()
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)

        Text(folder.name)
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(.white)

        Spacer()

        Button {
          // 编辑文件夹
        } label: {
          Image(systemName: "pencil")
            .font(.system(size: 16))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

      // 文件夹内的应用网格
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 6), spacing: 20) {
        ForEach(viewModel.activeFolderApps) { app in
          AppGridItemView(app: app, isGrouped: true, iconSize: calculateFolderIconSize(geometry))
            .onTapGesture {
              viewModel.openApp(app)
            }
            .contextMenu {
              Button("打开") {
                viewModel.openApp(app)
              }
              Button("从文件夹移除") {
                viewModel.removeApp(app, from: folder.id)
                toastManager.showSuccess("已从文件夹移除")
              }
            }
        }
      }
    }
  }

  // MARK: - Helper Methods

  private func calculateFolderIconSize(_ geometry: GeometryProxy) -> CGFloat {
    let availableWidth = geometry.size.width - 80
    let columnWidth = availableWidth / 6
    return max(80, min(120, columnWidth - 20))
  }
}

// MARK: - Preview
#Preview("LaunchpadRootView") {
  LaunchpadRootView()
    .frame(width: 1000, height: 700)
}
