// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Links",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Links",
            path: "Links",
            exclude: [
                "Info.plist",
                "Links.entitlements",
            ],
            resources: [
                .process("Assets.xcassets"),
            ]
        ),
    ]
)
