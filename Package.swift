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
        )
    ]
)
