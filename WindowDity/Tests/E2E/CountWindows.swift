// Count on-screen windows owned by a given process name
// Usage: swift CountWindows.swift <processName>
import CoreGraphics
import Foundation

let name = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "WindowDity"

guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
    print("0")
    exit(0)
}

let count = list.filter { ($0[kCGWindowOwnerName as String] as? String) == name }.count
print(count)
