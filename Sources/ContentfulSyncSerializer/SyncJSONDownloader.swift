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

public final class SyncJSONDownloader {
    private let spaceId: String
    private let accessToken: String
    private let outputDirectoryPath: String
    private let shouldDownloadMediaFiles: Bool

    public init(spaceId: String, accessToken: String, outputDirectoryPath: String, shouldDownloadMediaFiles: Bool) {
        self.spaceId = spaceId
        self.accessToken = accessToken
        self.outputDirectoryPath = outputDirectoryPath
        self.shouldDownloadMediaFiles = shouldDownloadMediaFiles
    }

    public func run(then completion: @escaping (Contentful.Result<Bool>) -> Void) {
        let client = Client(spaceId: spaceId,
                            accessToken: accessToken)

        client.sync { [unowned self] (result: Contentful.Result<SyncSpace>) in
            guard let syncSpace = result.value, result.error == nil else {
                completion(Result.error(result.error!))
                return
            }
            self.fetchLocales(withClient: client) { [unowned self] result in
                switch result {
                case .success:
                    self.fetchSync(withClient: client, syncSpace: syncSpace) { [unowned self] result in
                        switch result {
                        case .success:
                            if self.shouldDownloadMediaFiles && syncSpace.assets.count > 0 {
                                self.fetchAssets(withClient: client, syncSpace: syncSpace) { (result) in
                                    if let error = result.error {
                                        completion(.error(error))
                                    }else {
                                        completion(.success(true))
                                    }
                                }
                            } else {
                                completion(Result.success(true))
                            }
                        case let .error(error):
                            completion(.error(error))
                        }
                    }
                case let .error(error):
                    completion(.error(error))
                }
            }
        }
    }

    private func fetchAssets(withClient client: Client, syncSpace space: SyncSpace, completion: @escaping (Result<Bool>) -> Void) {
        let syncGroup = DispatchGroup()
        var imageSaveErrorCount = 0
        for asset in space.assets {
            syncGroup.enter()
            client.fetchData(for: asset) { [unowned self] data in
                do {
                    guard let fetched = data.value else {
                        syncGroup.leave()
                        return
                    }
                    try self.saveData(fetched, for: asset)
                    syncGroup.leave()
                } catch {
                    imageSaveErrorCount += 1
                    syncGroup.leave()
                    completion(Result.error(error))
                }
            }
        }
        syncGroup.notify(queue: DispatchQueue.main) {
            guard imageSaveErrorCount == 0 else {
                completion(Result.error(SyncJSONDownloader.Error.failedToWriteFiles(imageSaveErrorCount)))
                return
            }
            completion(Result.success(true))
        }
    }

    private func fetchLocales(withClient client: Client, completion: @escaping (Result<Bool>) -> Void) {
        _ = client.fetch(url: client.url(endpoint: .locales)) { [unowned self] result in
            guard let data = result.value, result.error == nil else {
                completion(Result(error: result.error!))
                return
            }
            self.handleDataFetchedAtURL(data, url: client.url(endpoint: .locales))
            completion(Result(success: true))
        }
    }

    private func fetchSync(withClient client: Client, syncSpace: SyncSpace, completion: @escaping (Result<Bool>) -> Void) {
        let url = client.url(endpoint: .sync, parameters: syncSpace.parameters)
        _ = client.fetch(url: url) { [unowned self] result in
            guard let data = result.value, result.error == nil else {
                completion(Result.error(result.error!))
                return
            }
            self.handleDataFetchedAtURL(data, url: url)
            completion(Result.success(true))
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


    public func handleDataFetchedAtURL(_ data: Data, url: URL) {
        saveJSONDataToDiskIfNecessary(data, for: url)
    }

    private var fileNameIndex: Int = 0

    private func saveJSONDataToDiskIfNecessary(_ data: Data, for fetchURL: URL) {
        // Compare components
        guard let fetchURLComponents = URLComponents(url: fetchURL, resolvingAgainstBaseURL: false) else { return }

        switch fetchURL.lastPathComponent {
        // Write the space to disk.
        case "locales":
            writeJSONDataToDisk(data, withFileName: "locales")
        case "sync":
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
