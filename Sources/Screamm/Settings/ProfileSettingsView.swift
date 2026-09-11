import SwiftUI
import ScreammKit

/// Edit model for the profile tab. Mirrors the dictionary/code-mode pattern: edit a local copy,
/// save on window close.
@MainActor
final class ProfileEditModel: ObservableObject {
    @Published var name: String

    private let store: ProfileStore

    init(store: ProfileStore) {
        self.store = store
        self.name = store.profile.name ?? ""
    }

    var preview: Profile { Profile(name: name) }

    func save() {
        store.update(Profile(name: preview.displayName))
    }
}

/// The "You" tab: one field, and an honest line about where it lives.
struct ProfileSettingsView: View {
    @ObservedObject var model: ProfileEditModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("What should we call you?")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Text("Screamm uses your first name to personalize your streak and celebrations. Leave it blank and it just says \"you\".")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 14)

            TextField("e.g. Alex", text: $model.name)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 14))
                .padding(.horizontal, 20)

            // Show the user exactly what their choice does.
            HStack(spacing: 6) {
                Image(systemName: "eye").foregroundStyle(.secondary)
                Text("\(model.preview.possessive) day streak · \(model.preview.addressed("Nice work"))")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20).padding(.top, 10)

            Spacer()

            HStack(spacing: 7) {
                Image(systemName: "lock.fill").foregroundStyle(Theme.brand)
                Text("Stored only on this Mac. Screamm never asks for more than a first name, and nothing here is ever uploaded.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20).padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
