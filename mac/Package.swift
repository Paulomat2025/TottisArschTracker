// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ArtTimeTracker",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ArtTimeTracker",
            path: "ArtTimeTracker",
            exclude: ["Assets.xcassets"],
            resources: [
                .copy("love-sound.wav")
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        )
    ]
)
