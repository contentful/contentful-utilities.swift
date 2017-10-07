//
//  main.swift
//  BundledDatabase
//
//  Created by JP Wright on 06.09.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//


// https://stackoverflow.com/a/39086761/4068264 // Important linker flags to get CLI running.
import Foundation
import Interstellar
import ContentfulSyncSerializer
import Commander


// Initialize commands.
let bundleSyncCommand = command(
    Argument<String>("spaceId", description: "The identifier for your Contentful space"),
    Argument<String>("accessToken", description: "Your content delivery API access token"),
    Argument<String>("output", description: "The path to the directory for your output")
) { (spaceId: String, accessToken: String, output: String) in

    let syncJSONDownloader = SyncJSONDownloader(spaceId: spaceId, accessToken: accessToken, outputDirectoryPath: output)

    syncJSONDownloader.run { result in
        switch result {
        case .success:
            print("Successfully stored JSON files for sync operation in directory \(CommandLine.arguments[3])")
            print("Add this directory to your bundle to ensure these files can be used by contentful-persistence.swift")
            exit(0)
        case .error(let error):
            print("Oh no! An error occurred: \(error)")
            exit(1)
        }
    }
    // Block until done.
    RunLoop.current.run()
}

let commandGroup = Group {
    $0.addCommand("sync-to-bundle", bundleSyncCommand)
}
// Entry point.
commandGroup.run()
