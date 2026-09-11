import SwiftUI

/// Two-tab settings: the custom dictionary and per-app code mode.
struct SettingsView: View {
    @ObservedObject var dictionary: DictionaryEditModel
    @ObservedObject var codeMode: CodeModeEditModel
    var onDone: () -> Void

    var body: some View {
        TabView {
            DictionarySettingsView(model: dictionary, onDone: onDone)
                .tabItem { Label("Dictionary", systemImage: "text.book.closed") }
            CodeModeSettingsView(model: codeMode)
                .tabItem { Label("Per-app", systemImage: "macwindow.on.rectangle") }
        }
        .frame(width: 500, height: 470)
    }
}
