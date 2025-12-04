import SwiftUI
import AppKit

/// LaunchpadApp 作为 LaunchMe 的入口
@main
struct LaunchpadApp: App {

  // MARK: - Properties

  @NSApplicationDelegateAdaptor(LaunchMeAppDelegate.self) var appDelegate

  // MARK: - Body

  var body: some Scene {
    WindowGroup {
      EmptyView()
        .frame(width: 0, height: 0)
        .opacity(0)
    }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
    .defaultSize(width: 0, height: 0)
  }
}
