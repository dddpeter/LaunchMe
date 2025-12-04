import AppKit
import Foundation

/// 应用图标缓存管理器
@MainActor
class IconCacheManager: ObservableObject {
  
  // MARK: - Properties
  
  static let shared = IconCacheManager()
  
  private var iconCache: [String: NSImage] = [:]
  private let cacheQueue = DispatchQueue(label: "com.launchme.iconcache", qos: .utility)
  private let maxCacheSize = 500
  private let cacheDirectory: URL
  
  // MARK: - Initializer
  
  private init() {
    // 设置缓存目录
    let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory,
                                              in: .userDomainMask).first!
    cacheDirectory = supportDirectory.appendingPathComponent("LaunchMe/IconCache")
    
    // 创建缓存目录
    try? FileManager.default.createDirectory(at: cacheDirectory,
                                        withIntermediateDirectories: true)
    
    // 清理过期缓存
    cleanupExpiredCache()
  }
  
  // MARK: - Public Methods
  
  /// 获取应用图标
  func getIcon(for bundleIdentifier: String, bundleURL: URL) -> NSImage {
    // 检查内存缓存
    if let cachedIcon = iconCache[bundleIdentifier] {
      return cachedIcon
    }
    
    // 检查磁盘缓存
    let cacheURL = cacheDirectory.appendingPathComponent("\(bundleIdentifier).png")
    
    if FileManager.default.fileExists(atPath: cacheURL.path),
       let cachedImage = NSImage(contentsOf: cacheURL) {
      // 加载到内存缓存
      iconCache[bundleIdentifier] = cachedImage
      return cachedImage
    }
    
    // 生成新图标
    let icon = generateIcon(for: bundleURL)
    
    // 缓存图标
    cacheIcon(icon, for: bundleIdentifier, at: cacheURL)
    
    return icon
  }
  
  /// 预热缓存
  func preloadIcons(for apps: [AppItem]) {
    Task.detached(priority: .background) { [weak self] in
      await self?.preloadIconsInternal(apps)
    }
  }
  
  /// 清除缓存
  func clearCache() {
    iconCache.removeAll()
    
    // 清除磁盘缓存
    if let enumerator = FileManager.default.enumerator(at: cacheDirectory,
                                                  includingPropertiesForKeys: nil) {
      for case let fileURL as URL in enumerator {
        try? FileManager.default.removeItem(at: fileURL)
      }
    }
  }
  
  // MARK: - Private Methods
  
  private func generateIcon(for bundleURL: URL) -> NSImage {
    let workspace = NSWorkspace.shared
    var icon = workspace.icon(forFile: bundleURL.path)
    
    // 调整图标大小
    icon.size = NSSize(width: 128, height: 128)
    
    // 如果图标为空，使用系统默认图标
    if icon.isValid == false {
      icon = NSImage(systemSymbolName: "app.fill", accessibilityDescription: "应用图标") ?? NSImage()
      icon.size = NSSize(width: 128, height: 128)
    }
    
    return icon
  }
  
  private func cacheIcon(_ icon: NSImage, for bundleIdentifier: String, at cacheURL: URL) {
    // 检查缓存大小限制
    if iconCache.count >= maxCacheSize {
      // 移除最旧的缓存项
      let keysToRemove = Array(iconCache.keys.prefix(50))
      keysToRemove.forEach { iconCache.removeValue(forKey: $0) }
    }
    
    // 添加到内存缓存
    iconCache[bundleIdentifier] = icon
    
    // 异步保存到磁盘
    cacheQueue.async { [weak self] in
      guard let self = self else { return }
      self.saveIconToDisk(icon, at: cacheURL)
    }
  }
  
  private func saveIconToDisk(_ icon: NSImage, at url: URL) {
    guard let tiffData = icon.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
      return
    }
    
    try? pngData.write(to: url)
  }
  
  private func preloadIconsInternal(_ apps: [AppItem]) async {
    for app in apps {
      await MainActor.run { [weak self] in
        _ = self?.getIcon(for: app.bundleIdentifier, bundleURL: app.bundleURL)
      }
    }
  }
  
  private func cleanupExpiredCache() {
    cacheQueue.async { [weak self] in
      guard let self = self else { return }
      
      // 获取缓存文件的创建时间
      if let enumerator = FileManager.default.enumerator(at: self.cacheDirectory,
                                                    includingPropertiesForKeys: [.creationDateKey]) {
        var expiredFiles: [URL] = []
        let expirationInterval: TimeInterval = 7 * 24 * 60 * 60 // 7天
        
        for case let fileURL as URL in enumerator {
          do {
            let resourceValues = try fileURL.resourceValues(forKeys: [.creationDateKey])
            if let creationDate = resourceValues.creationDate {
              let age = Date().timeIntervalSince(creationDate)
              if age > expirationInterval {
                expiredFiles.append(fileURL)
              }
            }
          } catch {
            // 如果无法获取创建时间，删除该文件
            expiredFiles.append(fileURL)
          }
        }
        
        // 删除过期文件
        for fileURL in expiredFiles {
          try? FileManager.default.removeItem(at: fileURL)
        }
      }
    }
  }
}

// MARK: - NSImage Extension

extension NSImage {
  /// 检查图标是否有效
  var isValid: Bool {
    return self.size.width > 0 && self.size.height > 0 && self.tiffRepresentation != nil
  }
  
  /// 创建调整大小的副本
  func resized(to size: NSSize) -> NSImage {
    let newImage = NSImage(size: size)
    
    newImage.lockFocus()
    let context = NSGraphicsContext.current
    context?.imageInterpolation = .high
    self.draw(in: NSRect(origin: .zero, size: size),
               from: NSRect(origin: .zero, size: self.size),
               operation: .copy,
               fraction: 1.0)
    newImage.unlockFocus()
    
    return newImage
  }
  
  /// 创建圆形版本
  func circular() -> NSImage {
    let size = self.size
    let rect = NSRect(origin: .zero, size: size)
    let circularImage = NSImage(size: size)
    
    circularImage.lockFocus()
    
    // 创建圆形路径
    let path = NSBezierPath(ovalIn: rect)
    path.addClip()
    
    // 绘制图像
    self.draw(in: rect)
    
    circularImage.unlockFocus()
    
    return circularImage
  }
}