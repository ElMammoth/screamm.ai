import SwiftUI

/// Three-tab settings: the custom dictionary, per-app code mode, and you.
struct SettingsView: View {
    @ObservedObject var dictionary: DictionaryEditModel
    @ObservedObject var codeMode: CodeModeEditModel
    @ObservedObject var profile: ProfileEditModel
    var onDone: () -> Void

    var body: some View {
        TabView {
            DictionarySettingsView(model: dictionary, onDone: onDone)
                .tabItem { Label("Dictionary", systemImage: "text.book.closed") }
            CodeModeSettingsView(model: codeMode)
                .tabItem { Label("Per-app", systemImage: "macwindow.on.rectangle") }
            ProfileSettingsView(model: profile)
                .tabItem { Label("You", systemImage: "person.crop.circle") }
        }
        .frame(width: 500, height: 470)
    }
}
