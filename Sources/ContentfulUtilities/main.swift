//
//  main.swift
//  BundledDatabase
//
//  Created by JP Wright on 06.09.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Commander
import ContentfulSyncSerializer
import Foundation

// https://stackoverflow.com/a/39086761/4068264 // Important linker flags to get CLI running.
// Initialize commands.
let bundleSyncCommand = command(
    Option<String>("space-id", default: "", description: "The identifier for your Contentful space"),
    Option<String>("access-token", default: "", description: "Your content delivery API access token"),
    Option<String>("output", default: "", description: "The path to the directory for your output"),
    Flag("download-asset-data", default: false, description: "If true, downloads the binary media files as well")
) { (spaceId: String, accessToken: String, output: String, shouldDownloadMediaFiles: Bool) in

    let syncJSONDownloader = SyncJSONDownloader(spaceId: spaceId,
                                                accessToken: accessToken,
                                                outputDirectoryPath: output,
                                                shouldDownloadMediaFiles: shouldDownloadMediaFiles)

    syncJSONDownloader.run { result in
        switch result {
        case .success:
            print("Successfully stored JSON files for sync operation in directory \(CommandLine.arguments[3])")
            print("Add this directory to your bundle to ensure these files can be used by contentful-persistence.swift")
            exit(0)
        case let .error(error):
            print("Oh no! An error occurred: \(error)")
            exit(1)
        }
    }
    // Block until done.
    RunLoop.current.run()
}

//
let commandGroup = Group {
    $0.addCommand("sync-to-bundle", bundleSyncCommand)
}

//// Entry point.
commandGroup.run()
