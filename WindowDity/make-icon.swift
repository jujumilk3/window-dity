// Renders the WindowDity app icon (a 2x2 window-tiling motif) to a 1024px PNG.
// Usage: swift make-icon.swift <output.png>
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let canvas = 1024
let W = CGFloat(canvas)
let cs = CGColorSpaceCreateDeviceRGB()

guard let ctx = CGContext(
    data: nil, width: canvas, height: canvas,
    bitsPerComponent: 8, bytesPerRow: 0, space: cs,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    FileHandle.standardError.write(Data("failed to create context\n".utf8))
    exit(1)
}

ctx.clear(CGRect(x: 0, y: 0, width: W, height: W))

// Rounded app tile (macOS Big Sur proportions: ~80% of canvas, corner ~0.2237).
let margin: CGFloat = 100
let tile = CGRect(x: margin, y: margin, width: W - margin * 2, height: W - margin * 2)
let corner = tile.width * 0.2237

// Diagonal indigo -> violet gradient fill.
ctx.saveGState()
ctx.addPath(CGPath(roundedRect: tile, cornerWidth: corner, cornerHeight: corner, transform: nil))
ctx.clip()
let grad = CGGradient(
    colorsSpace: cs,
    colors: [
        CGColor(red: 0.36, green: 0.45, blue: 0.99, alpha: 1),
        CGColor(red: 0.50, green: 0.26, blue: 0.88, alpha: 1)
    ] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(grad,
    start: CGPoint(x: tile.minX, y: tile.maxY),
    end: CGPoint(x: tile.maxX, y: tile.minY),
    options: [])
ctx.restoreGState()

// 2x2 window-tiling motif; top-left cell is the bright "snap target".
ctx.saveGState()
ctx.addPath(CGPath(roundedRect: tile, cornerWidth: corner, cornerHeight: corner, transform: nil))
ctx.clip()

let inset: CGFloat = 178
let content = tile.insetBy(dx: inset, dy: inset)
let gap: CGFloat = 38
let cellW = (content.width - gap) / 2
let cellH = (content.height - gap) / 2
let cellCorner: CGFloat = 44

func cell(_ col: Int, _ row: Int) -> CGRect {
    CGRect(x: content.minX + CGFloat(col) * (cellW + gap),
           y: content.minY + CGFloat(row) * (cellH + gap),
           width: cellW, height: cellH)
}

ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 26,
              color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.22))

// row 1 = top (origin is bottom-left).
let cells: [(col: Int, row: Int, alpha: CGFloat)] = [
    (0, 1, 1.00),   // top-left  (accent)
    (1, 1, 0.58),   // top-right
    (0, 0, 0.58),   // bottom-left
    (1, 0, 0.58)    // bottom-right
]
for c in cells {
    ctx.addPath(CGPath(roundedRect: cell(c.col, c.row),
                       cornerWidth: cellCorner, cornerHeight: cellCorner, transform: nil))
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: c.alpha))
    ctx.fillPath()
}
ctx.restoreGState()

guard let image = ctx.makeImage() else { exit(1) }
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
let url = URL(fileURLWithPath: out)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { exit(1) }
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { exit(1) }
print("wrote \(url.path)")
