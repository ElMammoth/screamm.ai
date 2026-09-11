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

    var body: some View {
        SettingsPage(
            title: "Dictionary",
            subtitle: "Whisper writes what it hears. When it gets a name or a bit of jargon wrong every time, teach it the fix here and Screamm will apply it to every dictation."
        ) {
            VStack(alignment: .leading, spacing: 9) {
                SettingsSectionHeader(text: "Replacements")

                SettingsCard {
                    if model.entries.isEmpty {
                        SettingsEmptyState(
                            symbol: "character.book.closed",
                            title: "No replacements yet",
                            hint: "A good first one: Screamm hears “screen”, and should write “Screamm”.")
                    } else {
                        columnHeader
                        SettingsDivider()
                        ForEach(Array($model.entries.enumerated()), id: \.element.id) { index, $entry in
                            if index > 0 { SettingsDivider() }
                            row($entry)
                        }
                    }
                }

                HStack {
                    SettingsAddButton(title: "Add replacement") { model.addEntry() }
                    Spacer()
                }
                .padding(.top, 2)

                Text("Matching is whole-word and ignores case, so a rule for “screen” never touches “screenshot”.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
    }

    /// Naming the two columns is the whole fix for "what do I type where".
    private var columnHeader: some View {
        HStack(spacing: 10) {
            Text("SCREAMM HEARS")
                .frame(maxWidth: .infinity, alignment: .leading)
            Color.clear.frame(width: 14, height: 1)
            Text("WRITE INSTEAD")
                .frame(maxWidth: .infinity, alignment: .leading)
            Color.clear.frame(width: 18, height: 1)
        }
        .font(.system(size: 9.5, weight: .bold, design: .rounded))
        .tracking(0.5)
        .foregroundStyle(.tertiary)
        .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 7)
    }

    private func row(_ entry: Binding<CustomDictionary.Entry>) -> some View {
        HStack(spacing: 10) {
            TextField("screen", text: entry.from)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.tertiary)
                .frame(width: 14)
            TextField("Screamm", text: entry.to)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
            SettingsRemoveButton { model.remove(entry.wrappedValue.id) }
                .frame(width: 18)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }
}
