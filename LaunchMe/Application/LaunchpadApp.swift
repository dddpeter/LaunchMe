import SwiftUI
import AppKit

/// LaunchpadApp 作为 LaunchMe 的入口
@main
struct LaunchpadApp: App {

  // MARK: - Properties

  @NSApplicationDelegateAdaptor(LaunchMeAppDelegate.self) var appDelegate

  // MARK: - Body

  var body: some Scene {
    Settings {
      EmptyView()
    }
  }
}
