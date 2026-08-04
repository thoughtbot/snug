// Generates Support/AppIcon.icns: SF Symbol video glyph on a gradient
// rounded rect. Run: swift scripts/make-icon.swift && iconutil -c icns ...
// (see Makefile `icon` target).
import AppKit

let iconsetPath = "build/Snug.iconset"
try? FileManager.default.createDirectory(
    atPath: iconsetPath, withIntermediateDirectories: true)

func whiteSymbol(pointSize: CGFloat) -> NSImage? {
    guard let symbol = NSImage(systemSymbolName: "video.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(.init(pointSize: pointSize, weight: .medium))
    else { return nil }
    let tinted = NSImage(size: symbol.size)
    tinted.lockFocus()
    symbol.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1)
    NSColor.white.set()
    NSRect(origin: .zero, size: symbol.size).fill(using: .sourceAtop)
    tinted.unlockFocus()
    return tinted
}

func drawIcon(_ side: Int) -> NSImage {
    let s = CGFloat(side)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()
    let inset = s * 0.09
    let rect = NSRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let path = NSBezierPath(roundedRect: rect, xRadius: s * 0.185, yRadius: s * 0.185)
    NSGradient(
        starting: NSColor(calibratedRed: 0.00, green: 0.55, blue: 0.45, alpha: 1),
        ending: NSColor(calibratedRed: 0.00, green: 0.33, blue: 0.62, alpha: 1)
    )!.draw(in: path, angle: -60)
    if let glyph = whiteSymbol(pointSize: s * 0.40) {
        let g = glyph.size
        glyph.draw(
            in: NSRect(x: (s - g.width) / 2, y: (s - g.height) / 2, width: g.width, height: g.height),
            from: .zero, operation: .sourceOver, fraction: 1)
    }
    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, side: Int, name: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff)
    else { fatalError("render failed for \(name)") }
    rep.size = image.size
    guard let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("png failed for \(name)")
    }
    try! png.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(name).png"))
}

for base in [16, 32, 128, 256, 512] {
    writePNG(drawIcon(base), side: base, name: "icon_\(base)x\(base)")
    writePNG(drawIcon(base * 2), side: base * 2, name: "icon_\(base)x\(base)@2x")
}
print("iconset written to \(iconsetPath)")
