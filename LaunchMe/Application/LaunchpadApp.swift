import SwiftUI

/// LaunchpadApp 作为 LaunchMe 的入口，提供最基础的窗口场景。
@main
struct LaunchpadApp: App {

  // MARK: - Properties

  /// 占位根视图，将在后续迭代中承载完整功能。
  private let rootView = LaunchpadRootView()

  // MARK: - Body

  var body: some Scene {
    WindowGroup {
      rootView
    }
  }

}

