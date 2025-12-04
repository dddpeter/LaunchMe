# LaunchMe 功能实现计划

## 目标概述

- 构建一个遵循 MVVM 架构的 macOS Launchpad 替代品，实现核心交互：快速打开/关闭浮层、检索本地应用、管理应用分组（文件夹）。
- 视图层保持声明式，业务集中在 ViewModel，充分利用 Swift 并发与 Combine，兼顾性能与可测试性。

## 阶段一：基础框架与状态管理

- **状态模型**
  - `AppItem`: `struct`，包含 `bundleIdentifier`、`displayName`、`icon`、`category`。
  - `FolderItem`: `struct`，包含 `id`、`name`、`apps: [AppItem]`、`isExpanded`。
  - `LaunchpadState`: `@Observable` 或 `ObservableObject`，持有 `apps`、`folders`、`searchText`、`isVisible`、`isAnimating` 等属性。
- **服务层**
  - `AppDiscoveryService`: 通过 Launch Services / `NSWorkspace` 扫描已安装应用，支持缓存（`AppCacheManager`）。
  - `FolderPersistenceService`: 使用 SwiftData 或 JSON 保存文件夹信息，支持导入导出。
- **视图模型**
  - `LaunchpadViewModel`: 提供 `show()`、`hide()`、`toggle()`、`searchApps(query:)`、`addAppToFolder(app:, folderID:)` 等接口，负责调度动画与状态更新。
  - `SearchViewModel`: 独立管理搜索建议与关键字高亮，减轻主 VM 负担。

## 阶段二：打开 / 关闭动画

- **窗口控制**
  - 继续使用无边框自定义 `NSWindow` + `NSHostingView`。
  - 新增 `WindowAnimator` 封装 `NSAnimationContext` / `CAAnimation`，实现淡入淡出、缩放、背景模糊渐变。
  - ViewModel 调用动画后更新 `isVisible` / `isAnimating`，与 UI 状态保持同步。
- **交互细节**
  - 支持全局快捷键唤起、鼠标/键盘失焦自动收起。

## 阶段三：搜索能力

- **数据索引**
  - 为 `apps` 生成内存索引（Trie 或前缀缓存），支持模糊匹配与拼音首字母。
- **UI 呈现**
  - `SearchBarView`: SwiftUI 自定义组件，使用 debounce 触发搜索。
  - 搜索结果采用 `LazyVGrid`，提供关键词高亮。
- **性能优化**
  - 搜索逻辑运行在后台 `Task(priority: .userInitiated)`。
  - 使用节流防止频繁重绘。

## 阶段四：应用文件夹

- **数据结构**
  - 支持一级嵌套结构（应用 → 文件夹），`FolderItem` 保存排序信息。
- **UI 组件**
  - `FolderView`: SwiftUI Grid，结合 `DragGesture` / `DropDelegate` 实现拖拽排序。
  - 文件夹展开采用浮层或嵌入式，辅以背景遮罩。
- **交互逻辑**
  - 新建、删除、重命名文件夹（含确认提示）。
  - 拖拽添加 / 移出应用，自动保存（`FolderPersistenceService`），支持回滚与备份。

## 阶段五：测试与工具

- **单元测试**
  - 针对 `LaunchpadViewModel`、`AppDiscoveryService`、`SearchViewModel` 编写 XCTest。
  - 使用 `measure` 验证搜索性能、动画延迟。
- **UI 测试**
  - 通过 `XCTest` UI 或 `ViewInspector` 检查搜索栏、文件夹开合、动画状态。
- **性能监控**
  - 添加 `os_signpost` 标记动画与搜索耗时。
  - 使用 Instruments 追踪动画帧率、内存峰值。

## 阶段六：后续优化

- 应用增量同步（监听 `NSWorkspace` 通知）。
- 快捷键配置 UI、多主题/透明度设置。
- 布局的 iCloud / JSON 导入导出。

## 时间与资源建议

- 迭代顺序：框架 → 动画 → 搜索 → 文件夹 → 测试。
- 每阶段预估 3–5 天（可视团队并行度调整），整体约 3–4 周完成最小可用版本。
- 建议各阶段结束进行 Demo / Review 以确保体验与性能满足预期。


