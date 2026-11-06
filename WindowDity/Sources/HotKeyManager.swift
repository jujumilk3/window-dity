import Foundation
import Carbon.HIToolbox

/// System-wide hotkeys via Carbon's RegisterEventHotKey: they fire while other
/// apps are frontmost, swallow the key press and need no extra permission.
final class HotKeyManager {
    typealias Binding = (shortcut: KeyShortcut, action: () -> Void)

    private static let signature: OSType = 0x5744_5459  // "WDTY"

    private var bindings: [Binding] = []
    private var refs: [EventHotKeyRef] = []
    private var actions: [UInt32: () -> Void] = [:]
    private var handler: EventHandlerRef?

    /// While suspended no hotkey is registered (used during shortcut recording).
    var isSuspended = false {
        didSet {
            guard isSuspended != oldValue else { return }
            if isSuspended { unregisterAll() } else { registerAll() }
        }
    }

    init() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let event, let userData else { return OSStatus(eventNotHandledErr) }
            var hotKeyID = EventHotKeyID()
            let err = GetEventParameter(
                event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID
            )
            guard err == noErr else { return err }
            Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue().fire(hotKeyID.id)
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), &handler)
    }

    deinit {
        unregisterAll()
        if let handler { RemoveEventHandler(handler) }
    }

    /// Replaces every registered hotkey with `bindings`.
    func setBindings(_ bindings: [Binding]) {
        self.bindings = bindings
        if !isSuspended { registerAll() }
    }

    private func registerAll() {
        unregisterAll()
        for (i, binding) in bindings.enumerated() {
            let id = UInt32(i + 1)
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(
                binding.shortcut.keyCode, binding.shortcut.modifiers,
                EventHotKeyID(signature: Self.signature, id: id),
                GetApplicationEventTarget(), 0, &ref
            )
            if status == noErr, let ref {
                refs.append(ref)
                actions[id] = binding.action
            } else {
                NSLog("WindowDity: could not register hotkey %@ (status %d)",
                      binding.shortcut.displayString, status)
            }
        }
    }

    private func unregisterAll() {
        refs.forEach { UnregisterEventHotKey($0) }
        refs = []
        actions = [:]
    }

    private func fire(_ id: UInt32) {
        actions[id]?()
    }
}
