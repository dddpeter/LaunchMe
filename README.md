# LaunchMe - macOS Launchpad 替代品

一个功能完整、性能优异的 macOS Launchpad 替代应用，采用 SwiftUI + AppKit 混合架构，提供流畅的用户体验。

## ✨ 主要功能

### 🚀 核心功能
- **全局快捷键启动** - 默认 `Option + Space`，可自定义
- **无边框浮层窗口** - 全屏半透明背景，不遮挡菜单栏
- **流畅动画效果** - 淡入淡出、缩放、弹性动画
- **智能应用发现** - 自动扫描系统已安装应用
- **高性能图标缓存** - 快速加载，内存优化

### 🔍 搜索功能
- **实时搜索** - 即时过滤应用和文件夹
- **智能匹配** - 支持应用名、Bundle ID、类别搜索
- **拼音首字母** - 支持中文拼音搜索
- **搜索高亮** - 清晰显示匹配结果

### 📁 文件夹管理
- **拖拽创建** - 拖拽应用到另一个应用上创建文件夹
- **文件夹编辑** - 重命名、删除文件夹
- **应用管理** - 添加、移除应用到文件夹
- **文件夹浮层** - 点击展开查看文件夹内容

### 🎯 交互体验
- **右键菜单** - 打开、在访达中显示、文件夹管理
- **拖拽操作** - 直观的应用和文件夹管理
- **Toast 通知** - 友好的操作反馈
- **错误处理** - 完善的错误提示和恢复机制

## 🏗️ 技术架构

### 架构设计
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   SwiftUI     │    │    AppKit      │    │   Services     │
│                │    │                │    │                │
│ • Views       │◄──►│ • Window Mgr   │◄──►│ • App Discovery │
│ • Components  │    │ • Global Hotkey │    │ • Folder Persist│
│ • Animations  │    │ • Window Anim   │    │ • Icon Cache   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   ViewModels   │
                    │                │
                    │ • LaunchpadVM  │
                    │ • SearchVM     │
                    │ • Toast Manager │
                    └─────────────────┘
```

### 核心组件

#### 窗口管理
- `LaunchpadWindowManager` - 窗口生命周期管理
- `GlobalHotkeyManager` - 全局快捷键处理
- `LaunchpadWindow` - 自定义无边框窗口

#### 视图组件
- `LaunchpadContentView` - 主界面视图
- `DraggableAppGrid` - 支持拖拽的应用网格
- `FolderOverlayView` - 文件夹内容浮层
- `ToastNotification` - 通知提示系统

#### 服务层
- `AppDiscoveryService` - 应用发现和扫描
- `FolderPersistenceService` - 文件夹数据持久化
- `IconCacheManager` - 图标缓存管理

#### 工具类
- `PerformanceMonitor` - 性能监控和优化
- `WindowAnimator` - 窗口动画效果

## 🚀 快速开始

### 系统要求
- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Swift 5.9+

### 安装运行
1. 克隆项目：
```bash
git clone https://github.com/your-username/LaunchMe.git
cd LaunchMe
```

2. 打开项目：
```bash
open LaunchMe.xcodeproj
```

3. 运行应用：
- 在 Xcode 中选择目标设备
- 点击运行按钮 (⌘+R)
- 应用启动后，使用 `Option + Space` 呼出 Launchpad

### 基本使用
1. **呼出 Launchpad** - 按 `Option + Space`
2. **搜索应用** - 直接输入应用名称
3. **启动应用** - 点击应用图标或按回车
4. **创建文件夹** - 拖拽应用到另一个应用上
5. **管理文件夹** - 右键点击文件夹进行编辑
6. **隐藏 Launchpad** - 按 `ESC` 或点击外部区域

## 🎨 自定义配置

### 快捷键设置
在 `GlobalHotkeyManager.swift` 中修改默认快捷键：
```swift
// 修改为 Command + Space
hotkeyManager.registerGlobalHotkey(keyCode: 49, modifiers: cmdKey)
```

### 界面调整
在 `LaunchpadContentView.swift` 中调整布局参数：
```swift
// 修改网格列数
private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 6)

// 调整图标大小
private let minIconSize: CGFloat = 64
private let maxIconSize: CGFloat = 100
```

## 📊 性能优化

### 图标缓存
- 内存缓存最多 500 个图标
- 磁盘缓存自动清理过期文件（7天）
- 后台异步加载，不阻塞 UI

### 搜索优化
- 防抖处理，避免频繁搜索
- 后台线程执行，保持 UI 流畅
- 智能索引，快速匹配

### 内存管理
- 弱引用避免循环引用
- 及时释放不需要的资源
- 性能监控和内存使用追踪

## 🧪 测试

### 运行单元测试
```bash
# 运行所有测试
xcodebuild test -scheme LaunchMe

# 运行特定测试类
xcodebuild test -scheme LaunchMe -only-testing:LaunchMeTests/LaunchpadViewModelTests
```

### 测试覆盖
- `LaunchpadViewModelTests` - 核心业务逻辑测试
- `AppDiscoveryServiceTests` - 应用发现服务测试
- `FolderPersistenceServiceTests` - 文件夹持久化测试

## 🔧 开发指南

### 代码结构
```
LaunchMe/
├── Application/          # 应用入口和生命周期
├── Managers/           # 管理器类
├── Models/             # 数据模型
├── Services/           # 服务层
├── ViewModels/         # 视图模型
├── Views/              # SwiftUI 视图
│   └── Components/     # 可复用组件
├── Utils/              # 工具类
└── Resources/          # 资源文件
```

### 编码规范
- 使用 `@Observable` 替代 `ObservableObject`
- 遵循 MVVM 架构模式
- 使用 `async/await` 处理异步操作
- 添加性能监控和错误处理

### 贡献指南
1. Fork 项目
2. 创建功能分支：`git checkout -b feature/new-feature`
3. 提交更改：`git commit -am 'Add new feature'`
4. 推送分支：`git push origin feature/new-feature`
5. 提交 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- 感谢 SwiftUI 社区的优秀实践
- 参考了系统 Launchpad 的交互设计
- 使用了开源社区的图标和动画库

## 📞 反馈与支持

- 🐛 **Bug 报告**：[Issues](https://github.com/your-username/LaunchMe/issues)
- 💡 **功能建议**：[Discussions](https://github.com/your-username/LaunchMe/discussions)
- 📧 **邮件联系**：your-email@example.com

---

**LaunchMe** - 让你的 macOS 应用启动更高效！ 🚀