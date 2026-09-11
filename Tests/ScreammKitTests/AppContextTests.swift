import Testing
import Foundation
@testable import ScreammKit

struct AppContextTests {
    @Test func codeAppGetsCodeModeOthersProse() {
        let s = AppContextSettings(
            smartModeEnabled: true,
            codeApps: [.init(bundleID: "com.apple.dt.Xcode", name: "Xcode")])
        #expect(s.mode(forBundleID: "com.apple.dt.Xcode") == .code)
        #expect(s.mode(forBundleID: "com.apple.Safari") == .prose)
        #expect(s.mode(forBundleID: nil) == .prose)
    }

    @Test func disabledIsAlwaysProse() {
        let s = AppContextSettings(
            smartModeEnabled: false,
            codeApps: [.init(bundleID: "com.apple.dt.Xcode", name: "Xcode")])
        #expect(s.mode(forBundleID: "com.apple.dt.Xcode") == .prose)
    }

    @Test func codeModeSkipsCapitalization() {
        let pipeline = CleanupPipeline()
        #expect(pipeline.process("hello world") == "Hello world")            // prose default
        #expect(pipeline.process("hello world", mode: .code) == "hello world") // code = no caps
    }

    @Test func storeRoundTrips() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("screamm-ctx-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("context.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let first = AppContextStore(url: url)
        first.update(AppContextSettings(
            smartModeEnabled: false,
            codeApps: [.init(bundleID: "com.example.app", name: "Example")]))
        first.flush()

        let second = AppContextStore(url: url)
        #expect(second.settings.smartModeEnabled == false)
        #expect(second.settings.codeApps.count == 1)
    }
}
