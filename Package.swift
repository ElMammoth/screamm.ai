// swift-tools-version: 5.9
import PackageDescription

// Screamm.ai — open-source, 100% on-device macOS dictation.
// v0.1 = headless end-to-end tool: hold Right-Cmd → record → transcribe (WhisperKit
// large-v3-turbo, warm) → rule-based cleanup → paste into the focused app.
//
// Structure:
//   ScreammKit  — testable logic + macOS integrations (Audio, Transcription, Injection,
//                 Hotkey, Cleanup, State, Permissions)
//   Screamm     — thin menu-bar executable that wires ScreammKit together
//   ScreammSpike— the throwaway engine spike (kept until deleted)
let package = Package(
    name: "Screamm",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0")
    ],
    targets: [
        .target(
            name: "ScreammKit",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit")
            ]
        ),
        .executableTarget(
            name: "Screamm",
            dependencies: ["ScreammKit"]
        ),
        .executableTarget(
            name: "ScreammSpike",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit")
            ]
        ),
        .testTarget(
            name: "ScreammKitTests",
            dependencies: ["ScreammKit"]
        )
    ]
)
