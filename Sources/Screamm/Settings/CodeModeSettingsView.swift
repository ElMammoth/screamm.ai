import SwiftUI
import AppKit
import UniformTypeIdentifiers
import ScreammKit

@MainActor
final class CodeModeEditModel: ObservableObject {
    @Published var smartModeEnabled: Bool
    @Published var codeApps: [AppContextSettings.AppEntry]
    private let store: AppContextStore

    init(store: AppContextStore) {
        self.store = store
        self.smartModeEnabled = store.settings.smartModeEnabled
        self.codeApps = store.settings.codeApps
    }

    /// Pick an .app from /Applications and add its bundle id.
    func addApp() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]
        guard panel.runModal() == .OK, let url = panel.url,
              let bundleID = Bundle(url: url)?.bundleIdentifier else { return }
        let name = FileManager.default.displayName(atPath: url.path)
            .replacingOccurrences(of: ".app", with: "")
        guard !codeApps.contains(where: { $0.bundleID == bundleID }) else { return }
        codeApps.append(.init(bundleID: bundleID, name: name))
    }

    func remove(_ bundleID: String) { codeApps.removeAll { $0.bundleID == bundleID } }

    func save() {
        store.update(AppContextSettings(smartModeEnabled: smartModeEnabled, codeApps: codeApps))
    }
}

struct CodeModeSettingsView: View {
    @ObservedObject var model: CodeModeEditModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Per-app code mode")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                Text("In these apps, Screamm skips sentence capitalization so code stays as you say it (func, not Func).")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Toggle(isOn: $model.smartModeEnabled) {
                Text("Smart code mode")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(model.codeApps) { app in
                        HStack(spacing: 8) {
                            Text(app.name)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                            Text(app.bundleID)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                            Spacer()
                            Button { model.remove(app.bundleID) } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if model.codeApps.isEmpty {
                        Text("No apps yet. Add one below.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .opacity(model.smartModeEnabled ? 1 : 0.45)
            .disabled(!model.smartModeEnabled)

            Button { model.addApp() } label: {
                Label("Add app…", systemImage: "plus.circle.fill")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .buttonStyle(.plain).foregroundStyle(Theme.brand)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
