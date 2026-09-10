import SwiftUI
import ScreammKit

/// The menu-bar stats popover: streak, week row, lifetime metrics, time saved. Reads a
/// snapshot of StatsData (rebuilt each time the popover opens).
struct StatsPanel: View {
    let data: StatsData
    var calendar: Calendar = .current
    var onQuit: () -> Void = { NSApp.terminate(nil) }

    private var isEmpty: Bool { data.totalDictations == 0 }

    var body: some View {
        VStack(spacing: 0) {
            streakHeader
            metrics
            savedChip
            footer
        }
        .frame(width: 300)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: Streak header

    private var streakHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 34))
                .foregroundStyle(.white)
            Text("\(data.currentStreak)")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
            Text(encouragement)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
            weekRow.padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(LinearGradient(colors: [Theme.brand, Theme.brandDeep],
                                   startPoint: .top, endPoint: .bottom))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isEmpty ? "No streak yet"
            : "\(data.currentStreak) day streak, \(data.totalWords) words dictated")
    }

    private var weekRow: some View {
        let today = calendar.startOfDay(for: Date())
        let days = (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        return HStack(spacing: 10) {
            ForEach(days, id: \.self) { day in
                let active = data.wasActive(on: day, calendar: calendar)
                VStack(spacing: 5) {
                    Text(dayLetter(day))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                    ZStack {
                        Circle()
                            .strokeBorder(.white.opacity(0.5), lineWidth: 2)
                            .background(Circle().fill(active ? .white : .clear))
                            .frame(width: 22, height: 22)
                        if active {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(Theme.brand)
                        }
                    }
                }
            }
        }
    }

    private var encouragement: String {
        if isEmpty { return "Say your first words to start a streak" }
        switch data.currentStreak {
        case 1: return "Day one. Come back tomorrow 🔥"
        case 2...6: return "\(data.currentStreak) days, you're on a roll"
        default: return "\(data.currentStreak) days strong"
        }
    }

    // MARK: Metrics

    private var metrics: some View {
        HStack(spacing: 12) {
            metric(value: isEmpty ? "—" : data.totalWords.formatted(), label: "words")
            metric(value: isEmpty ? "—" : "\(data.perDay.count)", label: "days used")
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }

    private func metric(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .monospacedDigit()
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var savedChip: some View {
        Text(savedText)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.brandDeep)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.brand.opacity(0.12)))
            .padding(.horizontal, 20).padding(.top, 14)
    }

    private var savedText: String {
        guard !isEmpty else { return "Your time saved will show up here" }
        let minutes = data.timeSavedMinutes
        if minutes >= 60 {
            return "≈ \(String(format: "%.1f", minutes / 60)) hrs saved  ~est"
        }
        return "≈ \(Int(minutes.rounded())) min saved  ~est"
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Divider().padding(.top, 16)
            HStack {
                Text("All local. Nothing leaves your Mac.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Quit", action: onQuit)
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20).padding(.vertical, 10)
        }
    }

    private func dayLetter(_ date: Date) -> String {
        let idx = calendar.component(.weekday, from: date) - 1
        let symbols = calendar.veryShortWeekdaySymbols
        return idx >= 0 && idx < symbols.count ? symbols[idx] : "?"
    }
}
