import Testing
import Foundation
@testable import ScreammKit

@Suite("Profile")
struct ProfileTests {

    // MARK: - nil-safe copy (the whole point: never a dangling name or comma)

    @Test func possessiveWithName() {
        #expect(Profile(name: "Alex").possessive == "Alex's")
    }

    @Test func possessiveWithoutName() {
        #expect(Profile().possessive == "Your")
        #expect(Profile(name: "").possessive == "Your")
        #expect(Profile(name: "   ").possessive == "Your")
    }

    @Test func addressedWithName() {
        #expect(Profile(name: "Alex").addressed("Nice work") == "Nice work, Alex")
    }

    @Test func addressedWithoutName() {
        #expect(Profile().addressed("Nice work") == "Nice work!")
        #expect(Profile(name: "  ").addressed("Nice work") == "Nice work!")
    }

    @Test func displayNameTrims() {
        #expect(Profile(name: "  Alex  ").displayName == "Alex")
        #expect(Profile(name: "\n").displayName == nil)
    }

    // MARK: - Store

    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("screamm-profile-tests-\(UUID().uuidString)")
            .appendingPathComponent("profile.json")
    }

    @Test func missingFileStartsEmpty() {
        let store = ProfileStore(url: tempURL())
        #expect(store.profile.displayName == nil)
    }

    @Test func roundTripsThroughDisk() {
        let url = tempURL()
        let store = ProfileStore(url: url)
        store.update(Profile(name: "Alex"))
        store.flush()

        let reloaded = ProfileStore(url: url)
        #expect(reloaded.profile.displayName == "Alex")
    }

    @Test func clearingTheNamePersists() {
        let url = tempURL()
        let store = ProfileStore(url: url)
        store.update(Profile(name: "Alex"))
        store.flush()
        store.update(Profile(name: nil))
        store.flush()

        #expect(ProfileStore(url: url).profile.displayName == nil)
    }

    @Test func corruptFileIsBackedUpNotFatal() throws {
        let url = tempURL()
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: url)

        let store = ProfileStore(url: url)
        #expect(store.profile.displayName == nil)
        #expect(FileManager.default.fileExists(atPath: url.appendingPathExtension("bak").path))
    }
}
