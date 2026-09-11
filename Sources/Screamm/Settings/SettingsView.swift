import SwiftUI

/// The settings window: a sidebar of sections plus a detail pane.
///
/// Replaces the old two-tab TabView. Tabs hid what the app could do and gave every pane the
/// same flat table; a sidebar names the sections up front and leaves room to grow.
struct SettingsView: View {
    @ObservedObject var dictionary: DictionaryEditModel
    @ObservedObject var codeMode: CodeModeEditModel
    var onDone: () -> Void

    enum Pane: String, CaseIterable, Identifiable {
        case dictionary, perApp, about
        var id: String { rawValue }

        var label: String {
            switch self {
            case .dictionary: return "Dictionary"
            case .perApp:     return "Per-app"
            case .about:      return "About"
            }
        }
        var symbol: String {
            switch self {
            case .dictionary: return "text.book.closed.fill"
            case .perApp:     return "macwindow.on.rectangle"
            case .about:      return "lock.shield.fill"
            }
        }
    }

    @State private var pane: Pane = .dictionary

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            VStack(spacing: 0) {
                Group {
                    switch pane {
                    case .dictionary: DictionarySettingsView(model: dictionary)
                    case .perApp:     CodeModeSettingsView(model: codeMode)
                    case .about:      AboutSettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                footer
            }
        }
        .frame(width: 660, height: 480)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Screamm")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.brand)
                .padding(.horizontal, 12).padding(.top, 16).padding(.bottom, 10)

            ForEach(Pane.allCases) { p in
                Button { pane = p } label: {
                    HStack(spacing: 8) {
                        Image(systemName: p.symbol)
                            .font(.system(size: 12))
                            .frame(width: 16)
                        Text(p.label).font(.system(size: 13, weight: .medium))
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(pane == p ? Color.white : Color.primary)
                    .padding(.horizontal, 9).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(pane == p ? Theme.brand : .clear))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
            }
            Spacer()
        }
        .frame(width: 170)
        .frame(maxHeight: .infinity)
        .background(Color.primary.opacity(0.03))
    }

    /// One persistent footer instead of a "Done" button buried in a single tab.
    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 6) {
                Image(systemName: "lock.fill").font(.system(size: 10)).foregroundStyle(.secondary)
                Text("Saved on this Mac. Nothing is uploaded.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Button("Done", action: onDone).keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
    }
}
