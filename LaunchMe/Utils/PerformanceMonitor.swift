import Foundation
import SwiftUI
import os.log

/// 性能监控工具
class PerformanceMonitor {
  
  // MARK: - Properties
  
  static let shared = PerformanceMonitor()
  
  private let performanceLog = OSLog(subsystem: "com.launchme.performance", category: "Performance")
  private var measurements: [String: Measurement] = [:]
  
  // MARK: - Measurement
  
  private struct Measurement {
    let startTime: DispatchTime
    var endTime: DispatchTime?
    var metadata: [String: Any]
    
    var duration: TimeInterval? {
      guard let endTime = endTime else { return nil }
      return TimeInterval(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
    }
  }
  
  // MARK: - Public Methods
  
  /// 开始测量
  func startMeasurement(for operation: String, metadata: [String: Any] = [:]) {
    measurements[operation] = Measurement(startTime: DispatchTime.now(), metadata: metadata)
    
    // Performance monitoring started
  }
  
  /// 结束测量
  func endMeasurement(for operation: String) {
    guard var measurement = measurements[operation] else { return }
    measurement.endTime = DispatchTime.now()
    measurements[operation] = measurement
    
    if let duration = measurement.duration {
      let durationMs = duration / 1_000_000 // 转换为毫秒
      // Performance monitoring completed

      // 如果耗时过长，记录警告
      if durationMs > 1000 { // 超过1秒
        print("操作 \(operation) 耗时过长: \(durationMs)ms")
      }
    }
  }
  
  /// 测量代码块执行时间
  func measure<T>(for operation: String, metadata: [String: Any] = [:], block: () throws -> T) rethrows -> T {
    startMeasurement(for: operation, metadata: metadata)
    defer { endMeasurement(for: operation) }
    return try block()
  }
  
  /// 异步测量代码块执行时间
  func measure<T>(for operation: String, metadata: [String: Any] = [:], block: () async throws -> T) async rethrows -> T {
    startMeasurement(for: operation, metadata: metadata)
    defer { endMeasurement(for: operation) }
    return try await block()
  }
  
  /// 记录内存使用情况
  func logMemoryUsage(for operation: String) {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_,
                 task_flavor_t(MACH_TASK_BASIC_INFO),
                 $0,
                 &count)
      }
    }
    
    if kerr == KERN_SUCCESS {
      let memoryMB = Double(info.resident_size) / 1024.0 / 1024.0
      os_log(.info, log: performanceLog, 
              "操作 %{public}@ 内存使用: %.2fMB", operation, memoryMB)
    }
  }
  
  /// 记录应用数量
  func logAppCount(_ count: Int) {
    os_log(.info, log: performanceLog, "已加载应用数量: %d", count)
  }
  
  /// 记录文件夹数量
  func logFolderCount(_ count: Int) {
    os_log(.info, log: performanceLog, "已创建文件夹数量: %d", count)
  }
  
  /// 清理测量数据
  func clearMeasurements() {
    measurements.removeAll()
  }
}

// MARK: - Performance Metrics

struct PerformanceMetrics {
  
  // MARK: - Properties
  
  let operationName: String
  let duration: TimeInterval
  let memoryUsage: Double?
  let metadata: [String: Any]
  
  // MARK: - Computed Properties
  
  var durationMs: Double {
    duration / 1_000_000
  }
  
  var memoryUsageMB: Double? {
    memoryUsage.map { $0 / 1024 / 1024 }
  }
}

// MARK: - View Extension

extension View {
  /// 测量视图渲染性能
  func measurePerformance(_ operation: String) -> some View {
    self.onAppear {
      PerformanceMonitor.shared.startMeasurement(for: "\(operation)_view_appear")
    }
    .onDisappear {
      PerformanceMonitor.shared.endMeasurement(for: "\(operation)_view_appear")
    }
  }
}

// MARK: - Performance Report

extension PerformanceMonitor {
  
  /// 生成性能报告
  func generateReport() -> String {
    var report = "=== LaunchMe 性能报告 ===\n"
    report += "生成时间: \(Date())\n\n"
    
    for (operation, measurement) in measurements {
      if let duration = measurement.duration {
        let durationMs = duration / 1_000_000
        report += "\(operation): \(String(format: "%.2f", durationMs))ms\n"
        
        if !measurement.metadata.isEmpty {
          report += "  元数据: \(measurement.metadata)\n"
        }
      }
    }
    
    return report
  }
  
  /// 保存性能报告到文件
  func saveReport() {
    let report = generateReport()
    
    let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                           in: .userDomainMask).first!
    let reportURL = documentsPath.appendingPathComponent("LaunchMe_Performance_Report.txt")
    
    try? report.write(to: reportURL, atomically: true, encoding: .utf8)
    
    os_log(.info, log: performanceLog, "性能报告已保存到: %@", reportURL.path)
  }
}