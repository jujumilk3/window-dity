// Standalone Swift script to simulate a mouse drag via CGEvent
// Usage: swift SimulateDrag.swift <startX> <startY> <endX> <endY>
// Requires Input Monitoring permission

import Foundation
import CoreGraphics

guard CommandLine.arguments.count == 5,
      let startX = Double(CommandLine.arguments[1]),
      let startY = Double(CommandLine.arguments[2]),
      let endX = Double(CommandLine.arguments[3]),
      let endY = Double(CommandLine.arguments[4]) else {
    print("Usage: swift SimulateDrag.swift <startX> <startY> <endX> <endY>")
    exit(1)
}

// Mouse down
guard let downEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown,
                               mouseCursorPosition: CGPoint(x: startX, y: startY),
                               mouseButton: .left) else {
    print("ERROR: Cannot create CGEvent — grant Input Monitoring permission")
    exit(2)
}
downEvent.post(tap: .cghidEventTap)
Thread.sleep(forTimeInterval: 0.1)

// Drag in steps
let steps = 20
for i in 1...steps {
    let t = Double(i) / Double(steps)
    let x = startX + (endX - startX) * t
    let y = startY + (endY - startY) * t
    guard let dragEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged,
                                   mouseCursorPosition: CGPoint(x: x, y: y),
                                   mouseButton: .left) else { continue }
    dragEvent.post(tap: .cghidEventTap)
    Thread.sleep(forTimeInterval: 0.05)
}

// Hold for overlays
Thread.sleep(forTimeInterval: 0.5)
print("DRAG_HOLDING")

// Mouse up
guard let upEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,
                             mouseCursorPosition: CGPoint(x: endX, y: endY),
                             mouseButton: .left) else {
    exit(2)
}
upEvent.post(tap: .cghidEventTap)
print("DRAG_DONE")
