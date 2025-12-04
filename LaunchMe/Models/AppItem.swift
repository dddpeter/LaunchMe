import AppKit

/// 表示本地安装的应用信息。
struct AppItem: Identifiable, Hashable {

  // MARK: - Properties

  let id: String
  let bundleIdentifier: String
  let displayName: String
  let bundleURL: URL
  let categories: [String]
  let icon: NSImage?

  // MARK: - Initializer

  init(bundleIdentifier: String,
       displayName: String,
       bundleURL: URL,
       categories: [String],
       icon: NSImage?) {
    self.id = bundleIdentifier
    self.bundleIdentifier = bundleIdentifier
    self.displayName = displayName
    self.bundleURL = bundleURL
    self.categories = categories
    self.icon = icon
  }

  // MARK: - Computed Properties

  var resolvedIcon: NSImage {
    if let icon { return icon }
    if let fallback = NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil) {
      fallback.isTemplate = false
      return fallback
    }
    return NSImage(size: NSSize(width: 128, height: 128))
  }

  var searchKeywords: [String] {
    var keywords: [String] = [displayName, bundleIdentifier]
    if let lastComponent = bundleIdentifier.split(separator: ".").last {
      keywords.append(String(lastComponent))
    }
    keywords.append(contentsOf: categories)
    return keywords
  }

  // MARK: - Helpers

  func matches(query: String) -> Bool {
    let normalizedQuery = query.lowercased()
    if displayName.normalizedForSearch().contains(normalizedQuery) { return true }
    if bundleIdentifier.normalizedForSearch().contains(normalizedQuery) { return true }
    return searchKeywords.contains { $0.normalizedForSearch().contains(normalizedQuery) }
  }

  static func placeholders(limit: Int = 12) -> [AppItem] {
    (0..<limit).map { index in
      AppItem(bundleIdentifier: "placeholder.bundle.\(index)",
              displayName: "示例应用 \(index + 1)",
              bundleURL: URL(fileURLWithPath: "/Applications"),
              categories: ["Sample"],
              icon: NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil))
    }
  }

  // MARK: - Hashable

  static func == (lhs: AppItem, rhs: AppItem) -> Bool { lhs.bundleIdentifier == rhs.bundleIdentifier }

  func hash(into hasher: inout Hasher) {
    hasher.combine(bundleIdentifier)
  }

}

private extension String {

  func normalizedForSearch() -> String {
    trimmingCharacters(in: .whitespacesAndNewlines)
      .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
  }

}

