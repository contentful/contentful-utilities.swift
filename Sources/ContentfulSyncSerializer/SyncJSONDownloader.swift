//
//  BundleDatabaseCLI.swift
//  ContentfulPersistence
//
//  Created by JP Wright on 07.09.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Contentful
import ContentfulPersistence
import Foundation

// https://www.swiftbysundell.com/articles/building-a-command-line-tool-using-the-swift-package-manager/
public final class SyncJSONDownloader {
    private let syncGroup: DispatchGroup
    private let spaceId: String
    private let accessToken: String
    private let outputDirectoryPath: String
    private let shouldDownloadMediaFiles: Bool

    public init(spaceId: String, accessToken: String, outputDirectoryPath: String, shouldDownloadMediaFiles: Bool) {
        self.spaceId = spaceId
        self.accessToken = accessToken
        self.outputDirectoryPath = outputDirectoryPath
        self.shouldDownloadMediaFiles = shouldDownloadMediaFiles

        syncGroup = DispatchGroup()
    }

    public func run(then completion: @escaping (Result<Bool>) -> Void) {
        let clientConfiguration = ClientConfiguration()

        let client = Client(spaceId: spaceId,
                            accessToken: accessToken,
                            clientConfiguration: clientConfiguration)

        print("Writing sync JSON files to directory \(outputDirectoryPath)")

        client.sync { [unowned self] (result: Result<SyncSpace>) in
            guard let syncSpace = result.value, result.error == nil else {
                completion(Result.error(result.error!))
                return
            }
            guard self.shouldDownloadMediaFiles && syncSpace.assets.count > 0 else {
                completion(Result.success(true))
                return
            }
            var imageSaveErrorCount = 0
            for asset in syncSpace.assets {
                self.syncGroup.enter()
                client.fetchData(for: asset) { data in
                    do {
                        guard let fetched = data.value else {
                            self.syncGroup.leave()
                            return
                        }
                        try self.saveData(fetched, for: asset)
                        self.syncGroup.leave()
                    } catch {
                        // TODO: Log error
                        imageSaveErrorCount += 1
                        self.syncGroup.leave()
                    }
                }
//                client.fetchData(for: asset).then { data in
//                    do {
//                        try self.saveData(data, for: asset)
//                        self.syncGroup.leave()
//                    } catch {
//                        // TODO: Log error
//                        imageSaveErrorCount += 1
//                        self.syncGroup.leave()
//                    }
//
//                }.error { error in
//                    completion(Result.error(error))
//                }
            }
            // Execute after all tasks have finished.
            self.syncGroup.notify(queue: DispatchQueue.main) {
                guard imageSaveErrorCount == 0 else {
                    completion(Result.error(SyncJSONDownloader.Error.failedToWriteFiles(imageSaveErrorCount)))
                    return
                }
                completion(Result.success(true))
            }
        }
    }

    private func saveData(_ data: Data, for asset: Asset) throws {
        // FIXME: Break into method on persistent thing.
        guard let fileName = SynchronizationManager.fileName(for: asset) else {
            throw SDKError.localeHandlingError(message: "Filename not set")
        }

        guard let directoryURL = Foundation.URL(string: outputDirectoryPath) else {
            throw SDKError.localeHandlingError(message: "Output directory path not exists")
        }

        let filePath = directoryURL.appendingPathComponent(fileName)
        guard FileManager.default.createFile(atPath: filePath.absoluteString, contents: data, attributes: nil) else {
            throw SDKError.localeHandlingError(message: "Unable to create data at \(filePath.absoluteString)")
        }
    }

    // MARK: DataDelegate

    public func handleDataFetchedAtURL(_ data: Data, url: URL) {
        saveJSONDataToDiskIfNecessary(data, for: url)
    }

    private var fileNameIndex: Int = 0

    private func saveJSONDataToDiskIfNecessary(_ data: Data, for fetchURL: URL) {
        // Compare components
        guard let fetchURLComponents = URLComponents(url: fetchURL, resolvingAgainstBaseURL: false) else { return }

        switch fetchURLComponents.path {
        // Write the space to disk.
        case "/spaces/\(spaceId)/environments/master/locales":
            writeJSONDataToDisk(data, withFileName: "locales")
        case "/spaces/\(spaceId)/sync":
            guard let fetchQueryItems = fetchURLComponents.queryItems else { return }

            for queryItem in fetchQueryItems {
                // Store file for initial sync.
                if let initial = queryItem.value, queryItem.name == "initial", initial == String(1) {
                    writeJSONDataToDisk(data, withFileName: String(fileNameIndex))
                    fileNameIndex += 1
                } else if queryItem.name == "sync_token" {
                    // Store JSON file for subsequent sync with syncToken as the name.
                    writeJSONDataToDisk(data, withFileName: String(fileNameIndex))
                    fileNameIndex += 1
                }
            }
        default:
            return
        }
    }

    private func writeJSONDataToDisk(_ data: Data, withFileName fileName: String) {
        let directoryURL = Foundation.URL(string: outputDirectoryPath)!

        let filePath = directoryURL.appendingPathComponent(fileName)
        let fullPath = filePath.appendingPathExtension("json")
        FileManager.default.createFile(atPath: fullPath.absoluteString, contents: data, attributes: nil)
    }
}

public extension SyncJSONDownloader {
    enum Error: Swift.Error {
        case invalidArguments
        case failedToCreateFile
        case failedToWriteFiles(Int)
        // FIXME: Error messages.
    }
}
