// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "KeyboardCleaner",
    platforms: [.macOS("26.0")],
    products: [.executable(name: "KeyboardCleaner", targets: ["KeyboardCleaner"])],
    targets: [
        .executableTarget(name: "KeyboardCleaner"),
        .testTarget(name: "KeyboardCleanerTests", dependencies: ["KeyboardCleaner"])
    ]
)
