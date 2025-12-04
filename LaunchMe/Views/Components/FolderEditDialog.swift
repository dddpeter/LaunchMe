import SwiftUI

/// 文件夹编辑对话框
struct FolderEditDialog: View {
  
  // MARK: - Properties
  
  @Binding var isPresented: Bool
  @State private var folderName: String
  @State private var isEditing: Bool
  let onSave: (String) -> Void
  
  // MARK: - Initializer
  
  init(isPresented: Binding<Bool>, 
       initialName: String = "", 
       onSave: @escaping (String) -> Void) {
    self._isPresented = isPresented
    self._folderName = State(initialValue: initialName)
    self._isEditing = State(initialValue: !initialName.isEmpty)
    self.onSave = onSave
  }
  
  // MARK: - Body
  
  var body: some View {
    VStack(spacing: 20) {
      // 标题
      Text(isEditing ? "重命名文件夹" : "新建文件夹")
        .font(.title2)
        .fontWeight(.semibold)
      
      // 输入框
      TextField("文件夹名称", text: $folderName)
        .textFieldStyle(.roundedBorder)
        .font(.body)
        .onAppear {
          // 自动选中所有文本
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isEditing = true
          }
        }
        .submitLabel(.done)
        .onSubmit {
          handleSave()
        }
      
      // 按钮
      HStack(spacing: 12) {
        Button("取消") {
          isPresented = false
        }
        .keyboardShortcut(.escape)
        
        Button(isEditing ? "重命名" : "创建") {
          handleSave()
        }
        .keyboardShortcut(.return)
        .buttonStyle(.borderedProminent)
        .disabled(folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
    .padding(24)
    .frame(width: 320)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(.regularMaterial)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .strokeBorder(.white.opacity(0.1))
    )
    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
  }
  
  // MARK: - Private Methods
  
  private func handleSave() {
    let trimmedName = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else { return }
    
    onSave(trimmedName)
    isPresented = false
  }
}

// MARK: - View Modifier

extension View {
  /// 显示文件夹编辑对话框
  func folderEditDialog(
    isPresented: Binding<Bool>,
    initialName: String = "",
    onSave: @escaping (String) -> Void
  ) -> some View {
    self.overlay(
      Group {
        if isPresented.wrappedValue {
          Color.black.opacity(0.3)
            .ignoresSafeArea()
            .onTapGesture {
              isPresented.wrappedValue = false
            }
          
          FolderEditDialog(
            isPresented: isPresented,
            initialName: initialName,
            onSave: onSave
          )
          .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
          ))
          .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented.wrappedValue)
        }
      }
    )
  }
}

// MARK: - Preview

#Preview("FolderEditDialog") {
  struct Wrapper: View {
    @State private var isPresented = true
    
    var body: some View {
      Color.gray.opacity(0.3)
        .ignoresSafeArea()
        .folderEditDialog(
          isPresented: $isPresented,
          initialName: "效率工具"
        ) { name in
          print("保存文件夹名称: \(name)")
        }
    }
  }
  
  return Wrapper()
}