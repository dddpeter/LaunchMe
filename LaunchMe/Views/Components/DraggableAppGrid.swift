import SwiftUI
import UniformTypeIdentifiers

/// 支持拖拽的应用网格视图
struct DraggableAppGrid: View {
  
  // MARK: - Properties
  
  let items: [LaunchpadViewModel.ContentItem]
  let viewModel: LaunchpadViewModel
  let geometry: GeometryProxy
  let onFolderCreated: () -> Void
  
  @State private var draggedItem: LaunchpadViewModel.ContentItem?
  @State private var dragOffset: CGSize = .zero
  @State private var isDragging = false
  @State private var showingCreateFolder = false
  @State private var draggedApps: Set<String> = []
  
  // MARK: - Body
  
  var body: some View {
    ZStack {
      // 主要网格内容
      gridView
        .overlay(
          // 拖拽时的视觉反馈
          dragFeedbackView,
          alignment: .topLeading
        )
      
      // 创建文件夹的提示区域
      if isDragging && showingCreateFolder {
        createFolderHint
      }
    }
    .onDrop(of: [UTType.text], isTargeted: nil) { providers in
      handleDropOnEmptySpace(providers: providers)
    }
  }
  
  // MARK: - View Components
  
  private var gridView: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 8), spacing: 20) {
      ForEach(items) { item in
        gridItem(for: item)
          .scaleEffect(isDraggingItem(item) ? 0.8 : 1.0)
          .opacity(isDraggingItem(item) ? 0.5 : 1.0)
          .animation(.easeInOut(duration: 0.2), value: isDragging)
      }
    }
  }
  
  @ViewBuilder
  private func gridItem(for item: LaunchpadViewModel.ContentItem) -> some View {
    switch item {
    case .app(let app):
      appGridItem(app: app)
    case .folder(let folder):
      folderGridItem(folder: folder)
    }
  }
  
  private func appGridItem(app: AppItem) -> some View {
    let iconSize = calculateIconSize()
    let isGrouped = viewModel.isAppGrouped(app)
    
    return AppGridItemView(app: app, isGrouped: isGrouped, iconSize: iconSize)
      .onTapGesture {
        guard !isDragging else { return }
        viewModel.openApp(app)
      }
      .contextMenu {
        appContextMenu(app: app)
      }
      .onDrag {
        draggedItem = .app(app)
        isDragging = true
        draggedApps = [app.bundleIdentifier]
        return NSItemProvider(object: app.bundleIdentifier as NSString)
      }
      .onDrop(of: [UTType.text], isTargeted: nil) { providers in
        handleDropOnApp(app: app, providers: providers)
      }
  }
  
  private func folderGridItem(folder: FolderItem) -> some View {
    let apps = viewModel.apps(in: folder)
    let cellWidth = calculateCellWidth()
    let iconScale = calculateIconScale()
    
    return FolderGridItemView(
      folder: folder,
      apps: apps,
      cellWidth: cellWidth,
      iconScale: iconScale,
      onTap: {
        guard !isDragging else { return }
        viewModel.openFolder(folder)
      },
      onDropApp: { bundleID in
        if let app = viewModel.app(for: bundleID) {
          viewModel.addApp(app, to: folder.id)
        }
      }
    )
    .onDrag {
      draggedItem = .folder(folder)
      isDragging = true
      return NSItemProvider(object: folder.id.uuidString as NSString)
    }
  }
  
  private var dragFeedbackView: some View {
    Group {
      if isDragging, let draggedItem = draggedItem {
        switch draggedItem {
        case .app(let app):
          AppGridItemView(app: app, isGrouped: false, iconSize: 64)
            .frame(width: 64, height: 64)
            .opacity(0.8)
            .offset(dragOffset)
        case .folder(let folder):
          let apps = viewModel.apps(in: folder)
          FolderGridItemView(
            folder: folder,
            apps: apps,
            cellWidth: 80,
            iconScale: 0.6,
            onTap: {},
            onDropApp: { _ in }
          )
          .frame(width: 80, height: 80)
          .opacity(0.8)
          .offset(dragOffset)
        }
      }
    }
  }
  
  private var createFolderHint: some View {
    VStack {
      Spacer()
      
      HStack {
        Spacer()
        
        VStack(spacing: 12) {
          Image(systemName: "folder.badge.plus")
            .font(.system(size: 32))
            .foregroundStyle(.white)
          
          Text("拖拽到这里创建文件夹")
            .font(.headline)
            .foregroundStyle(.white)
        }
        .padding(20)
        .background(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.blue.opacity(0.8))
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        
        Spacer()
      }
      
      Spacer()
    }
    .transition(.opacity.combined(with: .scale))
    .animation(.easeInOut(duration: 0.3), value: showingCreateFolder)
  }
  
  // MARK: - Context Menus
  
  private func appContextMenu(app: AppItem) -> some View {
    Group {
      Button("打开") {
        viewModel.openApp(app)
      }
      
      Button("在访达中显示") {
        viewModel.revealInFinder(app)
      }
      
      Divider()
      
      if !viewModel.isAppGrouped(app) {
        Menu("添加到文件夹") {
          ForEach(viewModel.folders) { folder in
            Button(folder.name) {
              viewModel.addApp(app, to: folder.id)
            }
          }
          
          Divider()
          
          Button("新建文件夹") {
            // TODO: 实现新建文件夹对话框
          }
        }
      } else {
        Button("从文件夹移除") {
          viewModel.removeApp(app)
        }
      }
    }
  }
  
  // MARK: - Drag & Drop Handlers
  
  private func handleDropOnApp(app: AppItem, providers: [NSItemProvider]) -> Bool {
    guard let provider = providers.first else { return false }
    
    provider.loadObject(ofClass: NSString.self) { object, _ in
      guard let bundleID = object as? String else { return }
      
      Task { @MainActor in
        // 如果拖拽的是应用，创建文件夹
        if let draggedApp = viewModel.app(for: bundleID), draggedApp.bundleIdentifier != app.bundleIdentifier {
          let folderName = "新文件夹"
          viewModel.createFolder(named: folderName)
          
          // 将两个应用添加到新文件夹
          if let newFolder = viewModel.folders.last {
            viewModel.addApp(app, to: newFolder.id)
            viewModel.addApp(draggedApp, to: newFolder.id)
          }
        }
      }
    }
    
    return true
  }
  
  private func isDraggingItem(_ item: LaunchpadViewModel.ContentItem) -> Bool {
    switch item {
    case .app(let app):
      return draggedApps.contains(app.bundleIdentifier)
    case .folder(let folder):
      if case .folder(let draggedFolder) = draggedItem {
        return draggedFolder.id == folder.id
      }
      return false
    }
  }

  private func handleDropOnEmptySpace(providers: [NSItemProvider]) -> Bool {
    guard !showingCreateFolder else { return false }
    
    // 如果拖拽到空白区域，显示创建文件夹提示
    showingCreateFolder = true
    
    // 延迟处理拖拽
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      showingCreateFolder = false
      isDragging = false
      draggedItem = nil
    }
    
    return true
  }
  
  // MARK: - Helper Methods
  
  private func calculateIconSize() -> CGFloat {
    let availableWidth = geometry.size.width - 80
    let columnWidth = availableWidth / 8
    return max(80, min(120, columnWidth - 20))
  }
  
  private func calculateCellWidth() -> CGFloat {
    let availableWidth = geometry.size.width - 80
    return availableWidth / 8
  }
  
  private func calculateIconScale() -> CGFloat {
    let iconSize = calculateIconSize()
    return iconSize / 96.0
  }
}

// MARK: - Preview

#Preview("DraggableAppGrid") {
  struct Wrapper: View {
    @State private var viewModel: LaunchpadViewModel

    init() {
      let appDiscoveryService = AppDiscoveryService()
      let folderService = FolderPersistenceService()
      let searchViewModel = SearchViewModel()
      self._viewModel = State(initialValue: LaunchpadViewModel(
        appDiscoveryService: appDiscoveryService,
        folderService: folderService,
        searchViewModel: searchViewModel
      ))
    }

    var body: some View {
      GeometryReader { geometry in
        DraggableAppGrid(
          items: viewModel.gridItems,
          viewModel: viewModel,
          geometry: geometry,
          onFolderCreated: {}
        )
      }
      .onAppear {
        viewModel.loadInitialData()
      }
    }
  }

  return Wrapper()
    .frame(width: 1200, height: 800)
}