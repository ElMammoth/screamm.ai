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
        SettingsPage(
            title: "Per-app",
            subtitle: "Screamm normally capitalizes sentences for you. In a code editor that's wrong — you want func, not Func. These apps get raw, uncapitalized text instead."
        ) {
            VStack(alignment: .leading, spacing: 9) {
                SettingsCard {
                    SettingsRow(
                        title: "Code mode",
                        description: "Detect the app you're dictating into and skip auto-capitalization in the ones below."
                    ) {
                        Toggle("", isOn: $model.smartModeEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .tint(Theme.brand)
                    }
                }

                SettingsSectionHeader(text: "Apps in code mode")
                    .padding(.top, 4)

                SettingsCard {
                    if model.codeApps.isEmpty {
                        SettingsEmptyState(
                            symbol: "chevron.left.forwardslash.chevron.right",
                            title: "No apps yet",
                            hint: "Add your editor or terminal and Screamm will stop capitalizing in it.")
                    } else {
                        ForEach(Array(model.codeApps.enumerated()), id: \.element.id) { index, app in
                            if index > 0 { SettingsDivider() }
                            appRow(app)
                        }
                    }
                }
                .opacity(model.smartModeEnabled ? 1 : 0.45)
                .disabled(!model.smartModeEnabled)

                HStack {
                    SettingsAddButton(title: "Add app…") { model.addApp() }
                        .disabled(!model.smartModeEnabled)
                    Spacer()
                }
                .padding(.top, 2)
            }
        }
    }

    private func appRow(_ app: AppContextSettings.AppEntry) -> some View {
        HStack(spacing: 10) {
            icon(for: app.bundleID)
                .resizable().frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(app.name).font(.system(size: 13, weight: .semibold))
                Text(app.bundleID)
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1).truncationMode(.middle)
            }
            Spacer(minLength: 8)
            SettingsRemoveButton { model.remove(app.bundleID) }
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
    }

    /// Real app icons make the list scannable and prove Screamm resolved the right bundle id.
    private func icon(for bundleID: String) -> Image {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
        }
        return Image(systemName: "app.dashed")
    }
}
