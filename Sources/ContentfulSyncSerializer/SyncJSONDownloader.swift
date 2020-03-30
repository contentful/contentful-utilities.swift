import Contentful
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
                        try self?.saveData(fetched, for: asset.file?.fileName)
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
                guard let self = self, let data = result.value, result.error == nil else {
                    promise.reject(result.error!)
                    return
                }
                do {
                    try self.writeJSONDataToDisk(data, withFileName: "locales")
                    promise.fulfill(())
                } catch {
                    promise.reject(error)
                }
            }
        }
    }

    private func fetchSync(withClient client: Client, syncSpace: SyncSpace) -> Promise<Void> {
        return Promise { promise in
            do {
                let data = try JSONEncoder().encode(syncSpace.entries)
                try writeJSONDataToDisk(data, withFileName: "entries")
                promise.fulfill(())
            } catch {
                promise.reject(error)
            }
        }
    }

    private func saveData(_ data: Data, for fileName: String?) throws {
        guard let fileName = fileName else { return }
        let folder = try Folder(path: outputDirectoryPath)
        let file = try folder.createFile(named: fileName)
        try file.write(data)
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
