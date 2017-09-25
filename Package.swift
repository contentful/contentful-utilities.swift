// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "ContentfulUtilities",
    targets: [
        Target(
            name: "ContentfulUtilities",
            dependencies: [
                "ContentfulSyncSerializer",
                ]
        ),
        Target(name: "ContentfulSyncSerializer")
    ],
    dependencies: [
      .Package(url: "https://github.com/contentful/contentful-persistence.swift", Version(0, 6, 1)),
      .Package(url: "https://github.com/johnsundell/files.git", majorVersion: 1)
    ]
)
