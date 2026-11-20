// swift-tools-version:5.9
import PackageDescription

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
            swiftSettings: [
                // With only the Command Line Tools, SwiftPM does not find the
                // plugin behind @Test and #expect. Full Xcode does not need this.
                .unsafeFlags(["-plugin-path", "/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing"]),
            ]
        ),
    ]
)
