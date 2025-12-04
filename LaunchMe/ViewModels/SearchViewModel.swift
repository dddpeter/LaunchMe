import Foundation
import Observation

/// 负责管理 Launchpad 搜索逻辑的视图模型。
@MainActor
@Observable
final class SearchViewModel {

  // MARK: - Properties

  var query: String = "" {
    didSet { scheduleFiltering() }
  }

  private(set) var results: [AppItem] = []

  /// 原始应用列表，作为搜索数据源。
  private var allApps: [AppItem] = []
  private var filteringTask: Task<Void, Never>?

  // MARK: - Public Methods

  func updateSource(_ apps: [AppItem]) {
    allApps = apps
    scheduleFiltering(immediate: true)
  }

  func displayedApps(fallback apps: [AppItem]) -> [AppItem] {
    query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? apps : results
  }

  func reset() {
    query = ""
    results = allApps
  }

  // MARK: - Private Methods

  private func scheduleFiltering(immediate: Bool = false) {
    filteringTask?.cancel()

    let normalizedQuery = query.normalizedForSearch()
    let source = allApps

    filteringTask = Task { [normalizedQuery, source] in
      if !immediate {
        try? await Task.sleep(for: .milliseconds(150))
      }
      guard !Task.isCancelled else { return }
      if normalizedQuery.isEmpty {
        results = source
      } else {
        results = source.filter { $0.matches(query: normalizedQuery) }
      }
    }
  }

}

private extension String {

  func normalizedForSearch() -> String {
    trimmingCharacters(in: .whitespacesAndNewlines)
      .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
  }

}

