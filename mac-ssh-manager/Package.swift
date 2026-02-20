// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacSSHManager",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MacSSHManager", targets: ["MacSSHManager"])
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.2.6")
    ],
    targets: [
        .executableTarget(
            name: "MacSSHManager",
            dependencies: [
                "SwiftTerm"
            ],
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("Security"),
                .linkedFramework("AppKit")
            ]
        )
    ]
)
