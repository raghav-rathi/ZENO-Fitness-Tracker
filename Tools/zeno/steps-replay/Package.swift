// swift-tools-version:5.9
import PackageDescription

// steps-replay: replays ZENO's hour-by-hour step merge over a copy of the app's database (see README.md).
let package = Package(
    name: "steps-replay",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "../../../Packages/StrandAnalytics"),
        .package(path: "../../../Packages/WhoopProtocol"),
    ],
    targets: [
        .executableTarget(
            name: "steps-replay",
            dependencies: [
                .product(name: "StrandAnalytics", package: "StrandAnalytics"),
                .product(name: "WhoopProtocol", package: "WhoopProtocol"),
            ],
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
    ]
)
