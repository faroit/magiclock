// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "magiclock",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .executable(name: "magiclock", targets: ["magiclock"])
    ],
    targets: [
        .executableTarget(
            name: "magiclock",
            path: "magiclock",
            exclude: [
                "Assets.xcassets",
                "Info.plist",
                "MainMenu.xib"
            ],
            resources: [
                .copy("trayicon.png"),
                .copy("trayicon@2x.png"),
                .copy("trayicon-tic.png"),
                .copy("trayicon-tic@2x.png")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreMIDI"),
                .linkedFramework("IOKit")
            ]
        )
    ]
)
