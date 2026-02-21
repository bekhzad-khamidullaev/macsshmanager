// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "macsshmanager",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "macsshmanager", targets: ["macsshmanager"])
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.2.6")
    ],
    targets: [
        .executableTarget(
            name: "macsshmanager",
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
