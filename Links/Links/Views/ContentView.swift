import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var store: LinkStore
    @State private var showingAdd = false
    @State private var showingSettings = false
    @State private var copiedID: UUID?
    @State private var searchText = ""
    @State private var isDropTargeted = false

    private var filteredItems: [LinkItem] {
        if searchText.isEmpty { return store.items }
        let query = searchText.lowercased()
        return store.items.filter {
            $0.title.lowercased().contains(query) ||
            $0.value.lowercased().contains(query) ||
            $0.category.lowercased().contains(query)
        }
    }

    private var groupedItems: [(String, [LinkItem])] {
        let dict = Dictionary(grouping: filteredItems) { $0.category.isEmpty ? "Uncategorized" : $0.category }
        return dict.sorted { $0.key < $1.key }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Links")
                    .font(.headline)
                Spacer()
                Button(action: { showingSettings.toggle() }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingSettings) {
                    ShortcutSettingsView()
                        .environmentObject(store)
                }

                Button(action: { showingAdd.toggle() }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingAdd) {
                    AddItemView(isPresented: $showingAdd)
                        .environmentObject(store)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.body)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            Divider()

            if store.items.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No items yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Click + or drop files here")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text("No matches")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    let groups = groupedItems
                    let hasMultipleGroups = groups.count > 1 || (groups.count == 1 && groups[0].0 != "Uncategorized")

                    ForEach(groups, id: \.0) { category, items in
                        if hasMultipleGroups {
                            Section(header: Text(category).font(.caption).foregroundStyle(.secondary)) {
                                itemRows(items)
                            }
                        } else {
                            itemRows(items)
                        }
                    }
                }
                .listStyle(.plain)
            }

            Divider()

            // Footer
            HStack {
                Text("\(store.items.count) item\(store.items.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(store.shortcut.displayString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))

                Button(action: { NSApp.terminate(nil) }) {
                    Image(systemName: "power")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Quit Links")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor, lineWidth: isDropTargeted ? 2 : 0)
        )
        .onDrop(of: [.fileURL, .url], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
        }
    }

    @ViewBuilder
    private func itemRows(_ items: [LinkItem]) -> some View {
        ForEach(items) { item in
            LinkRowView(item: item, isCopied: copiedID == item.id) {
                store.copyToClipboard(item)
                withAnimation { copiedID = item.id }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        if copiedID == item.id { copiedID = nil }
                    }
                }
            }
        }
        .onDelete { offsets in
            let idsToDelete = offsets.map { items[$0].id }
            store.items.removeAll { idsToDelete.contains($0.id) }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
                    guard let data = data as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    DispatchQueue.main.async {
                        store.addItem(
                            title: url.lastPathComponent,
                            value: url.path,
                            kind: .file
                        )
                    }
                }
                handled = true
            } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { data, _ in
                    guard let data = data as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    DispatchQueue.main.async {
                        store.addItem(
                            title: url.host ?? url.absoluteString,
                            value: url.absoluteString,
                            kind: .link
                        )
                    }
                }
                handled = true
            }
        }
        return handled
    }
}

struct LinkRowView: View {
    let item: LinkItem
    let isCopied: Bool
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Drag handle
            DragSourceView(item: item)
                .frame(width: 20, height: 24)
                .overlay {
                    Image(systemName: item.kind == .link ? "link" : "doc")
                        .foregroundStyle(.secondary)
                        .allowsHitTesting(false)
                }
                .help("Drag to copy")

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body)
                    .lineLimit(1)
                Text(item.value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onCopy) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(isCopied ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .help("Copy to clipboard")
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
