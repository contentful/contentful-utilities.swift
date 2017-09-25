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
import CoreLocation

let syncJSONDownloader = SyncJSONDownloader(arguments: CommandLine.arguments)

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

RunLoop.current.run()
