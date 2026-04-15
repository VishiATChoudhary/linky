import AppKit
import SwiftUI
import Carbon.HIToolbox

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var hotKeyRef: EventHotKeyRef?
    var eventHandler: EventHandlerRef?
    let store = LinkStore.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "link", accessibilityDescription: "Links")
            button.action = #selector(togglePopover)
        }

        let contentView = ContentView()
            .environmentObject(store)

        popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 480)
        popover.behavior = .semitransient
        popover.contentViewController = NSHostingController(rootView: contentView)

        registerHotKey()

        // Re-register when shortcut changes
        NotificationCenter.default.addObserver(
            self, selector: #selector(shortcutChanged),
            name: .shortcutDidChange, object: nil
        )
    }

    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    @objc func shortcutChanged() {
        unregisterHotKey()
        registerHotKey()
    }

    func registerHotKey() {
        let shortcut = store.shortcut

        let hotKeyID = EventHotKeyID(signature: OSType(0x4C4E4B53), id: 1) // "LNKS"
        var carbonModifiers: UInt32 = 0
        if shortcut.modifiers.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
        if shortcut.modifiers.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if shortcut.modifiers.contains(.control) { carbonModifiers |= UInt32(controlKey) }
        if shortcut.modifiers.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyHandler,
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
        if status != noErr {
            NSLog("Links: Failed to install event handler: \(status)")
        }

        let regStatus = RegisterEventHotKey(
            shortcut.carbonKeyCode, carbonModifiers, hotKeyID,
            GetApplicationEventTarget(), 0, &hotKeyRef
        )
        if regStatus != noErr {
            NSLog("Links: Failed to register hotkey: \(regStatus)")
        }
    }

    func unregisterHotKey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }
}

private func hotKeyHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData = userData else { return OSStatus(eventNotHandledErr) }
    let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
    DispatchQueue.main.async {
        appDelegate.togglePopover()
    }
    return noErr
}

extension Notification.Name {
    static let shortcutDidChange = Notification.Name("shortcutDidChange")
}
