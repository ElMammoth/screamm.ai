import Foundation

/// Milestones worth celebrating. Raw values are stable ids stored in `milestonesReached`
/// so each fires exactly once, ever.
public enum Milestone: String, CaseIterable, Sendable {
    case firstDictation = "first_dictation"
    case words1k = "words_1k"
    case words10k = "words_10k"
    case streak7 = "streak_7"
    case streak30 = "streak_30"
}

/// Local-only usage stats. The record logic is PURE (no I/O) so it's fully unit-testable;
/// `StatsStore` wraps it with persistence.
///
///   record(wordCount, at) ─▶ streak math (Calendar) ─▶ counts ─▶ milestone check
///
/// Streak math uses `Calendar` day comparison, never 86400s arithmetic (DST-safe), and
/// guards a backwards clock so the streak can't freeze.
public struct StatsData: Codable, Equatable, Sendable {
    public var schemaVersion: Int = 1
    public var totalWords: Int = 0
    public var totalDictations: Int = 0
    public var perDay: [String: Int] = [:]        // local "yyyy-MM-dd" -> words
    public var currentStreak: Int = 0
    public var longestStreak: Int = 0
    public var lastActiveDay: Date? = nil          // start-of-day of the last active day
    public var milestonesReached: Set<String> = []

    public init() {}

    /// Estimated minutes saved vs typing. Honest, rough: typing ~40 wpm, speaking ~150 wpm.
    public var timeSavedMinutes: Double {
        Double(totalWords) * (1.0 / 40.0 - 1.0 / 150.0)
    }

    /// Did the user dictate on the given day?
    public func wasActive(on date: Date, calendar: Calendar = .current) -> Bool {
        perDay[Self.dayKey(calendar.startOfDay(for: date), calendar)] != nil
    }

    /// Record one dictation. Returns the highest-priority milestone newly reached (if any).
    @discardableResult
    public mutating func record(wordCount: Int, at date: Date, calendar: Calendar = .current) -> Milestone? {
        let words = max(0, wordCount)
        let today = calendar.startOfDay(for: date)
        let key = Self.dayKey(today, calendar)

        var clockBackwards = false
        if let last = lastActiveDay {
            let lastStart = calendar.startOfDay(for: last)
            if today < lastStart {
                clockBackwards = true                    // clock moved back: count words, freeze streak
            } else if calendar.isDate(today, inSameDayAs: lastStart) {
                // same day: streak unchanged
            } else {
                let dayBefore = calendar.date(byAdding: .day, value: -1, to: today)!
                currentStreak = calendar.isDate(lastStart, inSameDayAs: dayBefore) ? currentStreak + 1 : 1
            }
        } else {
            currentStreak = 1                            // first ever
        }

        if !clockBackwards {
            lastActiveDay = today
            longestStreak = max(longestStreak, currentStreak)
        }
        totalWords += words
        totalDictations += 1
        perDay[key, default: 0] += words

        return checkMilestones()
    }

    private mutating func checkMilestones() -> Milestone? {
        // Highest priority first, so the "best" newly-reached milestone is returned while
        // still marking all newly-reached ones.
        let candidates: [(Milestone, Bool)] = [
            (.streak30, currentStreak >= 30),
            (.streak7, currentStreak >= 7),
            (.words10k, totalWords >= 10_000),
            (.words1k, totalWords >= 1_000),
            (.firstDictation, totalDictations >= 1),
        ]
        var result: Milestone?
        for (milestone, reached) in candidates where reached && !milestonesReached.contains(milestone.rawValue) {
            milestonesReached.insert(milestone.rawValue)
            if result == nil { result = milestone }
        }
        return result
    }

    /// Timezone-consistent local day key.
    static func dayKey(_ date: Date, _ calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
