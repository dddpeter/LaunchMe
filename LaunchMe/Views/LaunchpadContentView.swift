import SwiftUI

/// Launchpad 主内容视图
struct LaunchpadContentView: View {
  
  // MARK: - Properties
  
  @State private var apps: [String] = ["Safari", "Mail", "Calendar", "Notes", "Photos", "Music", "Xcode"]
  @State private var isLoading = false
  
  // MARK: - Body
  
  var body: some View {
    VStack(spacing: 20) {
      // 标题
      Text("LaunchMe")
        .font(.system(size: 32, weight: .bold, design: .rounded))
        .foregroundColor(.white)
      
      // 搜索栏
      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundColor(.secondary)
        
        TextField("搜索应用...", text: .constant(""))
          .textFieldStyle(.roundedBorder)
          .foregroundColor(.primary)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(.regularMaterial)
      )
      
      // 应用网格
      if isLoading {
        ProgressView("正在加载应用...")
          .scaleEffect(1.5)
          .padding(.top, 50)
      } else {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
          ForEach(apps, id: \.self) { app in
            VStack(spacing: 8) {
              Image(systemName: "app.fill")
                .font(.system(size: 32))
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)
              
              Text(app)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            }
            .padding(16)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(.blue.opacity(0.8))
            )
            .onTapGesture {
              print("点击了应用: \(app)")
            }
          }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 40)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      LinearGradient(
        colors: [.blue.opacity(0.8), .purple.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .onAppear {
      // 模拟加载过程
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        isLoading = false
      }
    }
  }
}

// MARK: - Preview

#Preview("LaunchpadContentView") {
  LaunchpadContentView()
    .frame(width: 800, height: 600)
}