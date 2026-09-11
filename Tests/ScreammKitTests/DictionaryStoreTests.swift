import Testing
import Foundation
@testable import ScreammKit

struct DictionaryStoreTests {
    func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("screamm-dict-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("dictionary.json")
    }

    @Test func roundTripPersists() {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let first = DictionaryStore(url: url)
        first.update(CustomDictionary(entries: [.init(from: "screen", to: "Screamm")]))
        first.flush()

        let second = DictionaryStore(url: url)
        #expect(second.dictionary.entries.count == 1)
        #expect(second.dictionary.apply(to: "screen") == "Screamm")
    }

    @Test func missingFileStartsEmpty() {
        #expect(DictionaryStore(url: tempURL()).dictionary.entries.isEmpty)
    }

    @Test func corruptFileBacksUpAndStartsEmpty() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("garbage{{{".utf8).write(to: url)

        let store = DictionaryStore(url: url)
        #expect(store.dictionary.entries.isEmpty)
        #expect(FileManager.default.fileExists(atPath: url.appendingPathExtension("bak").path))
    }

    @Test func cleanupPipelineAppliesDictionaryAsFinalStage() {
        let d = CustomDictionary(entries: [.init(from: "screen", to: "Screamm")])
        // "um screen is cool" → strip filler → capitalize → dictionary
        #expect(CleanupPipeline().process("um screen is cool", dictionary: d) == "Screamm is cool")
    }
}
