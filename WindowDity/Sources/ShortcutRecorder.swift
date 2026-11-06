import SwiftUI
import AppKit
import Carbon.HIToolbox

/// Click to record a global shortcut. While recording: a combo with ⌘/⌥/⌃
/// (or a function key) is captured, Esc cancels, Delete clears.
struct ShortcutRecorder: View {
    @Binding var shortcut: KeyShortcut?

    @State private var isRecording = false
    @State private var liveModifiers: UInt32 = 0
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 6) {
            Button(action: { isRecording ? stopRecording() : startRecording() }) {
                Text(label)
                    .monospacedDigit()
                    .frame(minWidth: 150)
            }
            .help(isRecording ? "Press a shortcut. Esc cancels, Delete clears."
                              : "Click to record a shortcut")

            if shortcut != nil && !isRecording {
                Button(action: { shortcut = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Clear shortcut")
            }
        }
        .onDisappear { stopRecording() }
    }

    private var label: String {
        if isRecording {
            let mods = KeyShortcut.modifierSymbols(liveModifiers)
            return mods.isEmpty ? "Type shortcut…" : mods + "…"
        }
        return shortcut?.displayString ?? "Record Shortcut"
    }

    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        liveModifiers = 0
        NotificationCenter.default.post(name: .shortcutRecordingDidChange, object: nil,
                                        userInfo: ["active": true])

        // A local monitor sees key events before the sheet's Save (Return) and
        // Cancel (Esc) buttons do, and returning nil swallows them.
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if event.type == .flagsChanged {
                liveModifiers = KeyShortcut.carbonModifiers(from: event.modifierFlags)
                return event
            }
            let mods = KeyShortcut.carbonModifiers(from: event.modifierFlags)
            switch Int(event.keyCode) {
            case kVK_Escape where mods == 0:
                stopRecording()
            case kVK_Delete where mods == 0, kVK_ForwardDelete where mods == 0:
                shortcut = nil
                stopRecording()
            default:
                if let recorded = KeyShortcut(event: event) {
                    shortcut = recorded
                    stopRecording()
                } else {
                    NSSound.beep()
                }
            }
            return nil
        }
    }

    private func stopRecording() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        guard isRecording else { return }
        isRecording = false
        liveModifiers = 0
        NotificationCenter.default.post(name: .shortcutRecordingDidChange, object: nil,
                                        userInfo: ["active": false])
    }
}
