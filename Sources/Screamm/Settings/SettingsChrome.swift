import SwiftUI

/// Shared building blocks for the settings window.
///
/// The structure follows what every settings screen that's actually pleasant to use does
/// (Linear, Graphite, Devin, Buffer): a sidebar of sections, and in each pane a stack of
/// **rows where the label and a one-line explanation sit on the left and the control sits on
/// the right**. The old version was two bare tables with no explanation of what anything did.

// MARK: - Page scaffold

/// A settings pane: big title, a sentence saying what this page is for, then content.
struct SettingsPage<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text(subtitle)
                        .font(.system(size: 12.5))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
    }
}

/// A small-caps group label above a card.
struct SettingsSectionHeader: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10.5, weight: .bold, design: .rounded))
            .tracking(0.6)
            .foregroundStyle(.secondary)
            .padding(.leading, 2)
    }
}

/// A rounded container that hairlines between its rows.
struct SettingsCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.045)))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1))
    }
}

/// The core row: title + optional description on the left, a control on the right.
struct SettingsRow<Control: View>: View {
    let title: String
    var description: String?
    @ViewBuilder var control: Control

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .semibold))
                if let description {
                    Text(description)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            control
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

struct SettingsDivider: View {
    var body: some View {
        Rectangle().fill(Color.primary.opacity(0.07)).frame(height: 1).padding(.leading, 14)
    }
}

/// Centered placeholder for an empty list — says what to do, not just that it's empty.
struct SettingsEmptyState: View {
    let symbol: String
    let title: String
    let hint: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Theme.brand.opacity(0.85))
            Text(title).font(.system(size: 13, weight: .semibold))
            Text(hint)
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, 20)
    }
}

/// The brand-orange text button used for "Add …" actions.
struct SettingsAddButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "plus.circle.fill")
                .font(.system(size: 12.5, weight: .semibold))
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.brand)
    }
}

/// A quiet round delete button that doesn't shout on every row.
struct SettingsRemoveButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "minus.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
        .help("Remove")
    }
}
