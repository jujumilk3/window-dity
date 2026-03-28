import Foundation
import CoreGraphics

enum LayoutPreset: String, CaseIterable {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case topLeftQuarter
    case topRightQuarter
    case bottomLeftQuarter
    case bottomRightQuarter
    case fullScreen

    var title: String {
        switch self {
        case .leftHalf:           return "Left Half"
        case .rightHalf:          return "Right Half"
        case .topHalf:            return "Top Half"
        case .bottomHalf:         return "Bottom Half"
        case .topLeftQuarter:     return "Top Left"
        case .topRightQuarter:    return "Top Right"
        case .bottomLeftQuarter:  return "Bottom Left"
        case .bottomRightQuarter: return "Bottom Right"
        case .fullScreen:         return "Full Screen"
        }
    }

    /// Compute the zone frame within the given screen visible frame.
    /// Uses macOS bottom-left origin coordinate system.
    func frame(in visibleFrame: CGRect) -> CGRect {
        let x = visibleFrame.origin.x
        let y = visibleFrame.origin.y
        let w = visibleFrame.width
        let h = visibleFrame.height
        let halfW = w / 2
        let halfH = h / 2

        switch self {
        case .leftHalf:
            return CGRect(x: x, y: y, width: halfW, height: h)
        case .rightHalf:
            return CGRect(x: x + halfW, y: y, width: halfW, height: h)
        case .topHalf:
            return CGRect(x: x, y: y + halfH, width: w, height: halfH)
        case .bottomHalf:
            return CGRect(x: x, y: y, width: w, height: halfH)
        case .topLeftQuarter:
            return CGRect(x: x, y: y + halfH, width: halfW, height: halfH)
        case .topRightQuarter:
            return CGRect(x: x + halfW, y: y + halfH, width: halfW, height: halfH)
        case .bottomLeftQuarter:
            return CGRect(x: x, y: y, width: halfW, height: halfH)
        case .bottomRightQuarter:
            return CGRect(x: x + halfW, y: y, width: halfW, height: halfH)
        case .fullScreen:
            return visibleFrame
        }
    }
}
