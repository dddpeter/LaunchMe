import AppKit

let size: CGFloat = 1024
let cornerRadius: CGFloat = 256
let backgroundGradient = NSGradient(colors: [
  NSColor(calibratedRed: 0.02, green: 0.19, blue: 0.65, alpha: 1.0),
  NSColor(calibratedRed: 0.05, green: 0.33, blue: 1.0, alpha: 1.0)
])
let highlightGradient = NSGradient(colors: [
  NSColor(calibratedWhite: 1.0, alpha: 0.45),
  NSColor(calibratedWhite: 1.0, alpha: 0.0)
])
let glowColor = NSColor(calibratedRed: 0.21, green: 0.46, blue: 0.96, alpha: 0.75)

let miniIconGradients: [(NSColor, NSColor)] = [
  (NSColor(calibratedRed: 0.99, green: 0.37, blue: 0.35, alpha: 1.0),
   NSColor(calibratedRed: 0.84, green: 0.17, blue: 0.41, alpha: 1.0)),
  (NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.30, alpha: 1.0),
   NSColor(calibratedRed: 0.99, green: 0.58, blue: 0.19, alpha: 1.0)),
  (NSColor(calibratedRed: 0.20, green: 0.80, blue: 0.46, alpha: 1.0),
   NSColor(calibratedRed: 0.12, green: 0.62, blue: 0.36, alpha: 1.0)),
  (NSColor(calibratedRed: 0.42, green: 0.55, blue: 1.0, alpha: 1.0),
   NSColor(calibratedRed: 0.24, green: 0.37, blue: 0.92, alpha: 1.0))
]
let miniIconSymbols = ["bolt.fill", "music.note", "sparkles", "person.fill"]
let miniIconSymbolColor = NSColor(calibratedWhite: 1.0, alpha: 0.92)
let miniIconBorderColor = NSColor(calibratedWhite: 1.0, alpha: 0.55)
let miniIconShadowColor = NSColor(calibratedWhite: 0.0, alpha: 0.18)
let miniIconHighlightGradient = NSGradient(colors: [
  NSColor(calibratedWhite: 1.0, alpha: 0.35),
  NSColor(calibratedWhite: 1.0, alpha: 0.0)
])

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let rect = NSRect(x: 0, y: 0, width: size, height: size)
let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
backgroundGradient?.draw(in: path, angle: -35)

let highlightRect = rect.insetBy(dx: size * 0.22, dy: size * 0.28)
let highlightPath = NSBezierPath(roundedRect: highlightRect, xRadius: cornerRadius * 0.55, yRadius: cornerRadius * 0.45)
highlightGradient?.draw(in: highlightPath, angle: 90)

let insetRect = rect.insetBy(dx: size * 0.08, dy: size * 0.08)
let glowPath = NSBezierPath(roundedRect: insetRect, xRadius: cornerRadius * 0.82, yRadius: cornerRadius * 0.82)
glowColor.setStroke()
glowPath.lineWidth = size * 0.04
glowPath.stroke()

let miniIconSize = size * 0.2
let miniIconSpacing = size * 0.1
let totalWidth = miniIconSize * 2 + miniIconSpacing
let originX = (size - totalWidth) / 2
let originY = originX
let miniIconCornerRadius = miniIconSize * 0.24
let miniIconStrokeWidth = size * 0.012
let miniIconSymbolConfig = NSImage.SymbolConfiguration(pointSize: miniIconSize * 0.42, weight: .bold)

for row in 0..<2 {
  for column in 0..<2 {
    let index = row * 2 + column
    let (topColor, bottomColor) = miniIconGradients[index]
    let gradient = NSGradient(colors: [topColor, bottomColor])

    let offsetX = originX + CGFloat(column) * (miniIconSize + miniIconSpacing)
    let offsetY = originY + CGFloat(row) * (miniIconSize + miniIconSpacing)
    let iconRect = NSRect(x: offsetX, y: offsetY, width: miniIconSize, height: miniIconSize)

    NSGraphicsContext.current?.saveGraphicsState()
    miniIconShadowColor.setStroke()
    let shadowPath = NSBezierPath(roundedRect: iconRect.offsetBy(dx: size * 0.01, dy: size * -0.01),
                                   xRadius: miniIconCornerRadius,
                                   yRadius: miniIconCornerRadius)
    shadowPath.lineWidth = miniIconStrokeWidth
    shadowPath.stroke()
    NSGraphicsContext.current?.restoreGraphicsState()

    let iconPath = NSBezierPath(roundedRect: iconRect, xRadius: miniIconCornerRadius, yRadius: miniIconCornerRadius)
    gradient?.draw(in: iconPath, angle: 90)

    let glossRect = iconRect.insetBy(dx: miniIconSize * 0.12, dy: miniIconSize * 0.55)
    miniIconHighlightGradient?.draw(in: glossRect, angle: 90)

    miniIconBorderColor.setStroke()
    iconPath.lineWidth = miniIconStrokeWidth
    iconPath.stroke()

    if index < miniIconSymbols.count {
      let symbolName = miniIconSymbols[index]
      let symbolBaseImage = NSImage(
        systemSymbolName: symbolName,
        accessibilityDescription: nil
      )
      let symbolImage = symbolBaseImage?.withSymbolConfiguration(miniIconSymbolConfig)
      if let symbol = symbolImage {
        miniIconSymbolColor.set()
        let symbolRect = iconRect.insetBy(dx: miniIconSize * 0.28, dy: miniIconSize * 0.28)
        symbol.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 1.0)
      }
    }
  }
}

image.unlockFocus()

guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
  fatalError("无法创建 PNG 数据")
}

let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
  .appendingPathComponent("LaunchMe/Resources/AppIcon_1024.png")

do {
  try pngData.write(to: outputURL, options: .atomic)
  print("已生成图标: \(outputURL.path)")
} catch {
  fatalError("写入图标失败: \(error.localizedDescription)")
}
