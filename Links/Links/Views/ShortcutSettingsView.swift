import SwiftUI
import Carbon.HIToolbox

struct ShortcutSettingsView: View {
    @EnvironmentObject var store: LinkStore
    @State private var isRecording = false
    @State private var recordedDisplay = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keyboard Shortcut")
                .font(.headline)

            Text("Current: \(store.shortcut.displayString)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                if isRecording {
                    Text("Press new shortcut...")
                        .font(.body)
                        .foregroundStyle(.orange)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                        .overlay {
                            ShortcutRecorderRepresentable { shortcut in
                                store.shortcut = shortcut
                                isRecording = false
                            }
                            .frame(width: 0, height: 0)
                        }
                } else {
                    Text(store.shortcut.displayString)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                }

                Button(isRecording ? "Cancel" : "Record") {
                    isRecording.toggle()
                }
            }

            Button("Reset to Default (⌘⇧L)") {
                store.shortcut = .default
                isRecording = false
            }
            .font(.caption)
        }
        .padding(16)
        .frame(width: 280)
    }
}

struct ShortcutRecorderRepresentable: NSViewRepresentable {
    let onRecord: (Shortcut) -> Void

    func makeNSView(context: Context) -> ShortcutRecorderView {
        let view = ShortcutRecorderView(onRecord: onRecord)
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: ShortcutRecorderView, context: Context) {}
}

class ShortcutRecorderView: NSView {
    let onRecord: (Shortcut) -> Void

    init(onRecord: @escaping (Shortcut) -> Void) {
        self.onRecord = onRecord
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Require at least one modifier
        guard !flags.isEmpty, event.keyCode != UInt16(kVK_Escape) else { return }

        var modifiers = Shortcut.Modifiers()
        if flags.contains(.command) { modifiers.insert(.command) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.control) { modifiers.insert(.control) }
        if flags.contains(.shift) { modifiers.insert(.shift) }

        // Need at least one modifier key
        guard !modifiers.isEmpty else { return }

        let shortcut = Shortcut(keyCode: Int(event.keyCode), modifiers: modifiers)
        onRecord(shortcut)
    }
}
