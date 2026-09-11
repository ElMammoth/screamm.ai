import SwiftUI
import AppKit

/// The privacy promise, stated plainly and in one place. For a dictation app that listens to
/// your microphone all day, "where does my voice go" is the first question a user has, and
/// leaving it unanswered in the UI is a product bug.
struct AboutSettingsView: View {

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        return "Version \(v)"
    }

    var body: some View {
        SettingsPage(
            title: "About",
            subtitle: "Screamm turns speech into text entirely on your Mac, using Whisper on the Apple Neural Engine."
        ) {
            VStack(alignment: .leading, spacing: 9) {
                SettingsSectionHeader(text: "Privacy")
                SettingsCard {
                    promise("mic.slash.fill", "Your audio never leaves this Mac",
                            "Recordings are transcribed in memory and discarded the moment they're used. Nothing is written to disk, ever.")
                    SettingsDivider()
                    promise("wifi.slash", "No network, no account, no telemetry",
                            "The only thing Screamm ever downloads is the speech model itself, once. There is no usage tracking of any kind.")
                    SettingsDivider()
                    promise("internaldrive.fill", "Your data stays yours",
                            "Streak, dictionary and per-app settings live in a plain JSON file in Application Support that you can read or delete.")
                }

                SettingsSectionHeader(text: "Shortcut").padding(.top, 4)
                SettingsCard {
                    SettingsRow(title: "Dictate",
                                description: "Hold to record, release to paste at your cursor.") {
                        Text("Right ⌘")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .padding(.horizontal, 9).padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.primary.opacity(0.08)))
                    }
                }

                HStack(spacing: 12) {
                    Text(version).font(.system(size: 11)).foregroundStyle(.secondary)
                    Link("Source on GitHub", destination: URL(string: "https://github.com/ElMammoth/screamm.ai")!)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.brand)
                }
                .padding(.top, 6)
            }
        }
    }

    private func promise(_ symbol: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundStyle(Theme.brand)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .semibold))
                Text(body)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
    }
}
