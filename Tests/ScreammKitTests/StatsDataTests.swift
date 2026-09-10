import Testing
import Foundation
@testable import ScreammKit

struct StatsDataTests {
    // Fixed UTC calendar so day math is deterministic regardless of the test machine.
    let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    func day(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }

    @Test func firstDictationStartsStreakAndFires() {
        var s = StatsData()
        let milestone = s.record(wordCount: 5, at: day(2026, 1, 1), calendar: cal)
        #expect(s.currentStreak == 1)
        #expect(s.totalWords == 5)
        #expect(s.totalDictations == 1)
        #expect(milestone == .firstDictation)
    }

    @Test func sameDayNoStreakBumpNoDoubleDay() {
        var s = StatsData()
        s.record(wordCount: 3, at: day(2026, 1, 1, 9), calendar: cal)
        s.record(wordCount: 4, at: day(2026, 1, 1, 17), calendar: cal)
        #expect(s.currentStreak == 1)
        #expect(s.totalWords == 7)
        #expect(s.perDay.count == 1)
    }

    @Test func consecutiveDaysIncrementStreak() {
        var s = StatsData()
        s.record(wordCount: 1, at: day(2026, 1, 1), calendar: cal)
        s.record(wordCount: 1, at: day(2026, 1, 2), calendar: cal)
        s.record(wordCount: 1, at: day(2026, 1, 3), calendar: cal)
        #expect(s.currentStreak == 3)
        #expect(s.longestStreak == 3)
    }

    @Test func gapResetsStreakButKeepsLongest() {
        var s = StatsData()
        s.record(wordCount: 1, at: day(2026, 1, 1), calendar: cal)
        s.record(wordCount: 1, at: day(2026, 1, 2), calendar: cal)
        s.record(wordCount: 1, at: day(2026, 1, 5), calendar: cal) // 2-day gap
        #expect(s.currentStreak == 1)
        #expect(s.longestStreak == 2)
    }

    @Test func midnightCrossingIsConsecutive() {
        var s = StatsData()
        s.record(wordCount: 1, at: day(2026, 1, 1, 23), calendar: cal)
        s.record(wordCount: 1, at: day(2026, 1, 2, 0), calendar: cal)
        #expect(s.currentStreak == 2)
    }

    @Test func clockBackwardsCountsWordsButFreezesStreak() {
        var s = StatsData()
        s.record(wordCount: 1, at: day(2026, 1, 5), calendar: cal)
        let before = s.currentStreak
        s.record(wordCount: 2, at: day(2026, 1, 3), calendar: cal) // earlier than last-active
        #expect(s.currentStreak == before)
        #expect(s.totalWords == 3)
    }

    @Test func wordMilestonesFireOnceInPriority() {
        var s = StatsData()
        #expect(s.record(wordCount: 999, at: day(2026, 1, 1), calendar: cal) == .firstDictation)
        #expect(s.record(wordCount: 1, at: day(2026, 1, 1), calendar: cal) == .words1k) // crosses 1000
        #expect(s.record(wordCount: 1, at: day(2026, 1, 1), calendar: cal) == nil)       // already past
    }

    @Test func streak7Fires() {
        var s = StatsData()
        for d in 1...7 { s.record(wordCount: 1, at: day(2026, 1, d), calendar: cal) }
        #expect(s.currentStreak == 7)
        #expect(s.milestonesReached.contains(Milestone.streak7.rawValue))
    }

    @Test func timeSavedIsPositive() {
        var s = StatsData()
        s.record(wordCount: 1000, at: day(2026, 1, 1), calendar: cal)
        #expect(s.timeSavedMinutes > 0)
    }

    @Test func wasActiveTracksDays() {
        var s = StatsData()
        s.record(wordCount: 1, at: day(2026, 1, 1), calendar: cal)
        #expect(s.wasActive(on: day(2026, 1, 1), calendar: cal))
        #expect(!s.wasActive(on: day(2026, 1, 2), calendar: cal))
    }
}
