//
//  BundleDatabaseCLI.swift
//  ContentfulPersistence
//
//  Created by JP Wright on 07.09.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar
import Contentful
import ContentfulPersistence
import CoreLocation

// https://medium.com/@johnsundell/building-a-command-line-tool-using-the-swift-package-manager-3dd96ce360b1
public final class SyncJSONDownloader: DataDelegate {


    private let spaceId: String
    private let accessToken: String
    private let outputDirectoryPath: String

//    public let writingDirectoryPath: String

    public init(spaceId: String, accessToken: String, outputDirectoryPath: String) {
        self.spaceId = spaceId
        self.accessToken = accessToken
        self.outputDirectoryPath = outputDirectoryPath

//        writingDirectoryPath = arguments[3]
        syncGroup = DispatchGroup()
    }

    public func run(then completion: @escaping (Result<Bool>) -> Void) {
//        guard arguments.count == 4 else {
//            completion(Result.error(Error.invalidArguments))
//            return
//        }

        var clientConfiguration = ClientConfiguration()
        clientConfiguration.dataDelegate = self
        let client = Client(spaceId: spaceId,
                            accessToken: accessToken,
                            clientConfiguration: clientConfiguration)

        print("Writing sync JSON files to directory \(outputDirectoryPath)")

        client.initialSync { [weak self] (result: Result<SyncSpace>) in
            guard let syncSpace = result.value else {
                completion(Result.error(Error.failedToCreateFile))
                return
            }
            guard syncSpace.assets.count > 0 else {
                completion(Result.success(true))
                return
            }
            var imageSaveErrorCount = 0
            for asset in syncSpace.assets {

                self?.syncGroup.enter()
                client.fetchData(for: asset).then { data in
                    guard let strongSelf = self else {
                        completion(Result.error(SDKError.invalidClient()))
                        return
                    }
                    do {
                        try strongSelf.saveData(data, for: asset)
                        strongSelf.syncGroup.leave()
                    } catch {
                        // TODO: Log error
                        imageSaveErrorCount += 1
                        strongSelf.syncGroup.leave()
                    }

                }.error { error in
                    completion(Result.error(error))
                }
            }
            // Execute after all tasks have finished.
            self?.syncGroup.notify(queue: DispatchQueue.main) { _ in
                guard imageSaveErrorCount == 0 else {
                    completion(Result.error(SyncJSONDownloader.Error.failedToWriteFiles(imageSaveErrorCount)))
                    return
                }
                completion(Result.success(true))
            }
        }
    }

    private let syncGroup: DispatchGroup

    private func saveData(_ data: Data, for asset: Asset) throws {
        // FIXME: Break into method on persistent thing.
        guard let fileName = SynchronizationManager.fileName(for: asset) else {
            throw SDKError.invalidClient()
        }


        guard let directoryURL = Foundation.URL(string: outputDirectoryPath) else {
            throw SDKError.invalidClient()
        }

        let filePath = directoryURL.appendingPathComponent(fileName)
        guard FileManager.default.createFile(atPath: filePath.absoluteString, contents: data, attributes: nil) else {
            throw SDKError.invalidClient()
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
        case "/spaces/\(spaceId)/":
            writeJSONDataToDisk(data, withFileName: "space")
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
