import Foundation
import SwiftUI

class LinkStore: ObservableObject {
    static let shared = LinkStore()

    @Published var items: [LinkItem] {
        didSet { save() }
    }
    @Published var shortcut: Shortcut {
        didSet {
            saveShortcut()
            NotificationCenter.default.post(name: .shortcutDidChange, object: nil)
        }
    }

    private let itemsKey = "links_items"
    private let shortcutKey = "links_shortcut"

    private init() {
        if let data = UserDefaults.standard.data(forKey: itemsKey),
           let decoded = try? JSONDecoder().decode([LinkItem].self, from: data) {
            items = decoded
        } else {
            items = []
        }

        if let data = UserDefaults.standard.data(forKey: shortcutKey),
           let decoded = try? JSONDecoder().decode(Shortcut.self, from: data) {
            shortcut = decoded
        } else {
            shortcut = .default
        }
    }

    var categories: [String] {
        let cats = Set(items.map(\.category)).sorted()
        return cats
    }

    func addItem(title: String, value: String, kind: LinkItem.Kind, category: String = "") {
        items.append(LinkItem(title: title, value: value, kind: kind, category: category))
    }

    func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    func moveItems(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }

    func copyToClipboard(_ item: LinkItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.value, forType: .string)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: itemsKey)
        }
    }

    private func saveShortcut() {
        if let data = try? JSONEncoder().encode(shortcut) {
            UserDefaults.standard.set(data, forKey: shortcutKey)
        }
    }
}
