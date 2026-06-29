// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "magiclock",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .library(name: "MagiclockCore", targets: ["MagiclockCore"]),
        .executable(name: "magiclock", targets: ["magiclock"]),
        .executable(name: "MagiclockCoreTestRunner", targets: ["MagiclockCoreTestRunner"])
    ],
    targets: [
        .target(
            name: "AbletonLinkBridge",
            path: "Sources/AbletonLinkBridge",
            publicHeadersPath: "include",
            cxxSettings: [
                .define("LINK_PLATFORM_UNIX", to: "1"),
                .define("LINK_PLATFORM_MACOSX", to: "1"),
                .headerSearchPath("../../Vendor/AbletonLink/include"),
                .headerSearchPath("../../Vendor/AbletonLink/modules/asio-standalone/asio/include")
            ],
            linkerSettings: [
                .linkedLibrary("c++")
            ]
        ),
        .target(
            name: "MagiclockCore",
            dependencies: ["AbletonLinkBridge"],
            path: "Sources/MagiclockCore"
        ),
        .executableTarget(
            name: "magiclock",
            dependencies: ["MagiclockCore"],
            path: "magiclock",
            exclude: [
                "Assets.xcassets",
                "Info.plist",
                "MainMenu.xib",
                "magiclock-Bridging-Header.h"
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
        ),
        .executableTarget(
            name: "MagiclockCoreTestRunner",
            dependencies: ["MagiclockCore"],
            path: "Tests/MagiclockCoreTestRunner"
        )
    ],
    cxxLanguageStandard: .cxx17
)
