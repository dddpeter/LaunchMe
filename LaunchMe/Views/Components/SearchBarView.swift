import SwiftUI

/// Launchpad 搜索框。
struct SearchBarView: View {

  // MARK: - Properties

  @Binding var text: String
  var placeholder: String
  var isLoading: Bool
  var onClear: () -> Void

  @FocusState private var isFocused: Bool

  // MARK: - Body

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.secondary)

      TextField(placeholder, text: $text)
        .textFieldStyle(.plain)
        .focused($isFocused)
        .onAppear { DispatchQueue.main.async { isFocused = true } }

      if isLoading {
        ProgressView()
          .controlSize(.small)
      } else if !text.isEmpty {
        Button {
          text = ""
          onClear()
          isFocused = true
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 16, weight: .semibold))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("清除搜索")
      }
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 12)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(.regularMaterial)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(.white.opacity(0.08))
    )
    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
  }

}

// MARK: - Preview

#Preview("SearchBarView") {
  struct Wrapper: View {
    @State private var query = ""

    var body: some View {
      SearchBarView(text: $query,
                    placeholder: "搜索应用或文件夹",
                    isLoading: false,
                    onClear: {})
        .frame(width: 320)
        .padding()
    }
  }

  return Wrapper()
}

