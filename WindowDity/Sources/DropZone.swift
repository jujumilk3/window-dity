import AppKit

struct DropZone {
    let preset: LayoutPreset
    let screenFrame: CGRect
    let title: String
    let color: NSColor

    static func allZones(for screen: NSScreen) -> [DropZone] {
        let visibleFrame = screen.visibleFrame
        let colors: [LayoutPreset: NSColor] = [
            .leftHalf:           .systemBlue,
            .rightHalf:          .systemBlue,
            .topHalf:            .systemGreen,
            .bottomHalf:         .systemGreen,
            .topLeftQuarter:     .systemOrange,
            .topRightQuarter:    .systemOrange,
            .bottomLeftQuarter:  .systemOrange,
            .bottomRightQuarter: .systemOrange,
            .fullScreen:         .systemPurple,
        ]

        return LayoutPreset.allCases.map { preset in
            DropZone(
                preset: preset,
                screenFrame: preset.frame(in: visibleFrame),
                title: preset.title,
                color: colors[preset] ?? .systemBlue
            )
        }
    }
}
