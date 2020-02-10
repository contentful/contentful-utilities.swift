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
            targets: ["ContentfulSyncSerializer"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/contentful/contentful-persistence.swift",
            .upToNextMajor(from: "0.13.0")),
        .package(
            url: "https://github.com/kylef/Commander",
            .upToNextMajor(from: "0.9.1")),
        .package(
            url: "https://github.com/johnsundell/files.git",
            from: "4.0.0"
        ),
		.package(
			url: "https://github.com/mxcl/PromiseKit.git",
			from: "6.8.0"
		)
    ],
    targets: [
        .target(
            name: "ContentfulUtilities",
            dependencies: [
                "ContentfulSyncSerializer",
                "Commander"
            ]
        ),
        .target(
            name: "ContentfulSyncSerializer",
            dependencies: [
                "ContentfulPersistence",
				"PromiseKit",
				"Files"
            ]
        ),
        .testTarget(
            name: "ContentfulSyncSerializerTests",
            dependencies: [
                "ContentfulSyncSerializer",
                "Files"
            ]
        ),
    ]
)
