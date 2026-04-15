import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DragSourceView: NSViewRepresentable {
    let item: LinkItem

    func makeNSView(context: Context) -> DragSourceNSView {
        DragSourceNSView(item: item)
    }

    func updateNSView(_ nsView: DragSourceNSView, context: Context) {
        nsView.item = item
    }
}

class DragSourceNSView: NSView {
    var item: LinkItem

    init(item: LinkItem) {
        self.item = item
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        let pasteboardItem = NSPasteboardItem()

        if item.kind == .file {
            let url = URL(fileURLWithPath: item.value)
            pasteboardItem.setString(url.absoluteString, forType: .fileURL)
            pasteboardItem.setString(item.value, forType: .string)
        } else {
            if let _ = URL(string: item.value) {
                pasteboardItem.setString(item.value, forType: .URL)
            }
            pasteboardItem.setString(item.value, forType: .string)
        }

        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)

        let iconName = item.kind == .file ? "doc.fill" : "link"
        let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
            ?? NSImage(size: NSSize(width: 32, height: 32))

        draggingItem.setDraggingFrame(
            NSRect(x: 0, y: 0, width: 32, height: 32),
            contents: image
        )

        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }
}

extension DragSourceNSView: NSDraggingSource {
    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        return .copy
    }
}
