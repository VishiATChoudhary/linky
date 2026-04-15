import SwiftUI

struct AddItemView: View {
    @EnvironmentObject var store: LinkStore
    @Binding var isPresented: Bool
    @State private var title = ""
    @State private var value = ""
    @State private var kind: LinkItem.Kind = .link
    @State private var category = ""
    @State private var showCategorySuggestions = false

    private var categorySuggestions: [String] {
        let existing = store.categories.filter { !$0.isEmpty }
        if category.isEmpty { return existing }
        return existing.filter { $0.lowercased().contains(category.lowercased()) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Item")
                .font(.headline)

            Picker("Type", selection: $kind) {
                ForEach(LinkItem.Kind.allCases, id: \.self) { k in
                    Text(k == .link ? "Link" : "File").tag(k)
                }
            }
            .pickerStyle(.segmented)

            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)

            HStack {
                TextField(kind == .link ? "URL" : "File path", text: $value)
                    .textFieldStyle(.roundedBorder)

                if kind == .file {
                    Button("Browse") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = true
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let url = panel.url {
                            value = url.path
                            if title.isEmpty {
                                title = url.lastPathComponent
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                TextField("Category (optional)", text: $category)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: category) { _ in
                        showCategorySuggestions = !category.isEmpty || !categorySuggestions.isEmpty
                    }

                if showCategorySuggestions && !categorySuggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(categorySuggestions, id: \.self) { suggestion in
                                Button(suggestion) {
                                    category = suggestion
                                    showCategorySuggestions = false
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                }
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Add") {
                    let finalTitle = title.isEmpty ? value : title
                    store.addItem(title: finalTitle, value: value, kind: kind, category: category)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(value.isEmpty)
            }
        }
        .padding(16)
        .frame(width: 320)
        .onAppear {
            showCategorySuggestions = !categorySuggestions.isEmpty
        }
    }
}
