// swift-tools-version:5.9
import Foundation
import PackageDescription

// With only the Command Line Tools installed, SwiftPM does not find the
// compiler plugin behind @Test and #expect, so point it there. With full
// Xcode selected (as on GitHub's Mac runners) it is found without help.
let commandLineTools = "/Library/Developer/CommandLineTools"
let testingPlugins = commandLineTools + "/usr/lib/swift/host/plugins/testing"
let selectedDeveloperDir = ProcessInfo.processInfo.environment["DEVELOPER_DIR"]
    ?? (try? FileManager.default.destinationOfSymbolicLink(atPath: "/var/db/xcode_select_link"))
    ?? ""
let testSettings: [SwiftSetting] =
    selectedDeveloperDir.hasPrefix(commandLineTools) && FileManager.default.fileExists(atPath: testingPlugins)
    ? [.unsafeFlags(["-plugin-path", testingPlugins])]
    : []

let package = Package(
    name: "WinDummy",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "WinDummy",
            path: "Sources/WinDummy"
        ),
        .testTarget(
            name: "WinDummyTests",
            dependencies: ["WinDummy"],
            path: "Tests/WinDummyTests",
            swiftSettings: testSettings
        ),
    ]
)
