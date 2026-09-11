import SwiftUI
import ScreammKit

@MainActor
final class DictionaryEditModel: ObservableObject {
    @Published var entries: [CustomDictionary.Entry]
    private let store: DictionaryStore

    init(store: DictionaryStore) {
        self.store = store
        self.entries = store.dictionary.entries
    }

    func addEntry() { entries.append(.init(from: "", to: "")) }
    func remove(_ id: UUID) { entries.removeAll { $0.id == id } }

    /// Persist, dropping rows with an empty "heard" side.
    func save() {
        let cleaned = entries.filter { !$0.from.trimmingCharacters(in: .whitespaces).isEmpty }
        store.update(CustomDictionary(entries: cleaned))
    }
}

struct DictionarySettingsView: View {
    @ObservedObject var model: DictionaryEditModel
    var onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Custom dictionary")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                Text("Fix words Screamm mishears. Left = what it hears, right = what to write.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach($model.entries) { $entry in
                        HStack(spacing: 8) {
                            TextField("heard, e.g. screen", text: $entry.from)
                                .textFieldStyle(.roundedBorder)
                            Image(systemName: "arrow.right").foregroundStyle(.secondary)
                            TextField("write, e.g. Screamm", text: $entry.to)
                                .textFieldStyle(.roundedBorder)
                            Button { model.remove(entry.id) } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if model.entries.isEmpty {
                        Text("No words yet. Add one below.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 12)
                    }
                }
            }
            .frame(maxHeight: .infinity)

            HStack {
                Button { model.addEntry() } label: {
                    Label("Add word", systemImage: "plus.circle.fill")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .buttonStyle(.plain).foregroundStyle(Theme.brand)

                Spacer()

                Text("Saved locally")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Button("Done") { model.save(); onDone() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 480, height: 420)
    }
}
