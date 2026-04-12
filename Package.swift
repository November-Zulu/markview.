// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MarkView",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MarkView", targets: ["MarkView"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.3.0")
    ],
    targets: [
        .executableTarget(
            name: "MarkView",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ],
            path: "Sources/MarkView",
            exclude: ["Resources/Info.plist"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/MarkView/Resources/Info.plist"
                ])
            ]
        ),
        .testTarget(
            name: "MarkViewTests",
            dependencies: ["MarkView"],
            path: "Tests/MarkViewTests"
        )
    ]
)
