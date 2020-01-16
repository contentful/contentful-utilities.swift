import Contentful
import ContentfulPersistence
import Files
import Foundation
import PromiseKit
public final class SyncJSONDownloader {
    private let spaceId: String
    private let accessToken: String
    private let outputDirectoryPath: String
    private let shouldDownloadMediaFiles: Bool
    private let environment: String
    public init(spaceId: String, accessToken: String, outputDirectoryPath: String, environment: String = "master", shouldDownloadMediaFiles: Bool) {
        self.spaceId = spaceId
        self.environment = environment
        self.accessToken = accessToken
        self.outputDirectoryPath = outputDirectoryPath
        self.shouldDownloadMediaFiles = shouldDownloadMediaFiles
    }

    public func run(then completion: @escaping (Contentful.Result<Bool>) -> Void) {
        let client = Client(spaceId: spaceId, environmentId: environment,
                            accessToken: accessToken)
        firstly {
            sync(client: client)
        }.then { syncSpace in
            self.fetchLocales(withClient: client).map({ syncSpace })
        }.then { syncSpace in
            self.fetchSync(withClient: client, syncSpace: syncSpace).map({ syncSpace })
        }.then { syncSpace in
            self.fetchAssets(withClient: client, syncSpace: syncSpace)
        }.done { _ in
            completion(Result.success(true))
        }.catch { error in
            completion(.error(error))
        }
    }

    private func sync(client c: Client) -> Promise<SyncSpace> {
        return Promise { promise in
            c.sync { result in
                guard let syncSpace = result.value else {
                    if let error = result.error {
                        promise.reject(error)
                    } else {
                        promise.reject(Error.failedToFetchSyncSpace)
                    }
                    return
                }
                promise.fulfill(syncSpace)
            }
        }
    }

    private func fetchAssets(withClient client: Client, syncSpace space: SyncSpace) -> Promise<Void> {
        return Promise { promise in
            if shouldDownloadMediaFiles == false || space.assets.isEmpty {
                promise.fulfill(())
                return
            }
            let syncGroup = DispatchGroup()
            var imageSaveErrorCount = 0
            for asset in space.assets {
                syncGroup.enter()
                client.fetchData(for: asset) { [weak self] data in
                    do {
                        guard let fetched = data.value else {
                            syncGroup.leave()
                            return
                        }
                        try self?.saveData(fetched, for: asset)
                        syncGroup.leave()
                    } catch {
                        imageSaveErrorCount += 1
                        syncGroup.leave()
                        promise.reject(error)
                    }
                }
            }
            syncGroup.notify(queue: DispatchQueue.main) {
                guard imageSaveErrorCount == 0 else {
                    promise.reject(SyncJSONDownloader.Error.failedToWriteFiles(imageSaveErrorCount))
                    return
                }
                promise.fulfill(())
            }
        }
    }

    private func fetchLocales(withClient client: Client) -> Promise<Void> {
        return Promise { promise in
            _ = client.fetch(url: client.url(endpoint: .locales)) { [weak self] result in
                guard let data = result.value, result.error == nil else {
                    promise.reject(result.error!)
                    return
                }
                do {
                    try self?.handleDataFetchedAtURL(data, url: client.url(endpoint: .locales))
                    promise.fulfill(())
                } catch {
                    promise.reject(error)
                }
            }
        }
    }

    private func fetchSync(withClient client: Client, syncSpace: SyncSpace) -> Promise<Void> {
        return Promise { promise in
            let url = client.url(endpoint: .sync, parameters: syncSpace.parameters)
            _ = client.fetch(url: url) { [unowned self] result in
                guard let data = result.value, result.error == nil else {
                    promise.reject(result.error!)
                    return
                }
                do {
                    try self.handleDataFetchedAtURL(data, url: url)
                } catch {
                    promise.reject(error)
                }
                let itinialUrl = client.url(endpoint: .sync, parameters: ["initial": "1"])
                _ = client.fetch(url: itinialUrl, then: { initialResult in
                    guard let data = initialResult.value, initialResult.error == nil else {
                        promise.reject(initialResult.error!)
                        return
                    }
                    do {
                        try self.handleDataFetchedAtURL(data, url: url)
                        promise.fulfill(())
                    } catch {
                        promise.reject(error)
                    }
                })
            }
        }
    }

    private func saveData(_ data: Data, for asset: Asset) throws {
        // FIXME: Break into method on persistent thing.
        guard let fileName = SynchronizationManager.fileName(for: asset) else {
            throw SDKError.localeHandlingError(message: "Filename not set")
        }
        let folder = try Folder(path: outputDirectoryPath)
        let file = try folder.createFile(named: fileName)
        try file.write(data)
    }

    public func handleDataFetchedAtURL(_ data: Data, url: URL) throws {
        try saveJSONDataToDiskIfNecessary(data, for: url)
    }

    private var fileNameIndex: Int = 0

    private func saveJSONDataToDiskIfNecessary(_ data: Data, for fetchURL: URL) throws {
        // Compare components
        guard let fetchURLComponents = URLComponents(url: fetchURL, resolvingAgainstBaseURL: false) else { return }

        switch fetchURL.lastPathComponent {
        // Write the space to disk.
        case "locales":
            try writeJSONDataToDisk(data, withFileName: "locales")
        case "sync":
            guard let fetchQueryItems = fetchURLComponents.queryItems else { return }

            for queryItem in fetchQueryItems {
                // Store file for initial sync.
                if let initial = queryItem.value, queryItem.name == "initial", initial == String(1) {
                    try writeJSONDataToDisk(data, withFileName: String(fileNameIndex))
                    fileNameIndex += 1
                } else if queryItem.name == "sync_token" {
                    // Store JSON file for subsequent sync with syncToken as the name.
                    try writeJSONDataToDisk(data, withFileName: String(fileNameIndex))
                    fileNameIndex += 1
                }
            }
        default:
            return
        }
    }

    private func writeJSONDataToDisk(_ data: Data, withFileName fileName: String) throws {
        let folder = try Folder(path: outputDirectoryPath)
        let file = try folder.createFile(named: fileName + ".json")
        try file.write(data)
    }
}

public extension SyncJSONDownloader {
    enum Error: Swift.Error {
        case invalidArguments
        case failedToCreateFile
        case failedToWriteFiles(Int)
        case failedToFetchSyncSpace
    }
}
