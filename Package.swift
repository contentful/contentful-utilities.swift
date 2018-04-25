// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "ContentfulUtilities",
    products: [
        .executable(
            name: "ContentfulUtilities",
            targets: ["ContentfulUtilities"]
        ),
        .library(
            name: "ContentfulSyncSerializer",
            type: .dynamic,
            targets: ["ContentfulSyncSerializer"])
    ],
    dependencies: [
      .package(url: "https://github.com/contentful/contentful-persistence.swift", .upToNextMinor(from: "0.11.0")),
      .package(url: "https://github.com/contentful/contentful.swift", .upToNextMinor(from: "2.0.0")),
      .package(url: "https://github.com/jensravens/Interstellar", .upToNextMinor(from: "2.1.0")),
      .package(url: "https://github.com/kylef/Commander", .upToNextMinor(from: "0.8.0")),
      .package(url: "https://github.com/johnsundell/files.git", .upToNextMajor(from: "2.2.1"))
    ],
    targets: [
        .target(
            name: "ContentfulUtilities",
            dependencies: [
                "ContentfulSyncSerializer",
                "Commander",
                "Interstellar"
            ]
        ),
        .target(
            name: "ContentfulSyncSerializer",
            dependencies: [
                "ContentfulPersistence",
                "Contentful",
                "Interstellar"
            ]
        ),
        .testTarget(
            name: "ContentfulSyncSerializerTests",
            dependencies: [
                "ContentfulSyncSerializer",
                "Files", 
                "Interstellar"
            ]
        )
    ]
)

