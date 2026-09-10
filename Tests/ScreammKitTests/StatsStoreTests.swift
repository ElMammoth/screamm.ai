import Testing
import Foundation
@testable import ScreammKit

struct StatsStoreTests {
    func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("screamm-test-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("stats.json")
    }

    @Test func roundTripPersists() {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let first = StatsStore(url: url)
        first.recordDictation(wordCount: 10, at: Date())
        first.flush()

        let second = StatsStore(url: url)
        #expect(second.data.totalWords == 10)
        #expect(second.data.totalDictations == 1)
    }

    @Test func missingFileStartsEmpty() {
        let store = StatsStore(url: tempURL())
        #expect(store.data.totalWords == 0)
        #expect(store.data.currentStreak == 0)
    }

    @Test func corruptFileBacksUpAndStartsEmpty() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not valid json {{{".utf8).write(to: url)

        let store = StatsStore(url: url)
        #expect(store.data.totalWords == 0)
        #expect(FileManager.default.fileExists(atPath: url.appendingPathExtension("bak").path))
    }

    @Test func resetZeroesStats() {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = StatsStore(url: url)
        store.recordDictation(wordCount: 5, at: Date())
        store.reset()
        #expect(store.data.totalWords == 0)
    }
}
