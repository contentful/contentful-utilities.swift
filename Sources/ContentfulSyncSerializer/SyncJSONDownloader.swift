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
    private var entriesFileNameIndex: Int = 0

    public init(
        spaceId: String,
        accessToken: String,
        outputDirectoryPath: String,
        environment: String = "master",
        shouldDownloadMediaFiles: Bool
    ) {
        self.spaceId = spaceId
        self.environment = environment
        self.accessToken = accessToken
        self.outputDirectoryPath = outputDirectoryPath
        self.shouldDownloadMediaFiles = shouldDownloadMediaFiles
    }

    public func run(then completion: @escaping (Contentful.Result<Bool>) -> Void) {
        self.entriesFileNameIndex = 0

        let client = Client(
            spaceId: spaceId,
            environmentId: environment,
            accessToken: accessToken
        )

        firstly {
            self.sync(client: client)
        }.then { _ in
            self.fetchLocales(withClient: client).map({ SyncSpace() })
        }.then { syncSpace in
            self.fetchContent(withClient: client, syncSpace: syncSpace).map({ SyncSpace() })
        }.done { _ in
            completion(.success(true))
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

    private func fetchContent(withClient client: Client, syncSpace: SyncSpace) -> Promise<Void> {
        return Promise { promise in
            _ = client.fetchContent(
                for: syncSpace,
                shouldDownloadAssets: shouldDownloadMediaFiles,
                reportDownloadedSyncSpace: { [weak self] downloadedSyncSpace, data, url in
                guard let self = self else {
                    promise.reject(SyncJSONDownloader.Error.clientNotAvailable)
                    return
                }

                do {
                    let fileName = String(self.entriesFileNameIndex)
                    self.entriesFileNameIndex += 1

                    try self.writeJSONDataToDisk(data, withFileName: fileName)

                } catch let error {
                    promise.reject(error)
                }

            }, reportDownloadedAsset: { [weak self] (asset, data) in
                guard let self = self else {
                    promise.reject(SyncJSONDownloader.Error.clientNotAvailable)
                    return
                }

                guard let fileName = asset.file?.fileName else {
                    return
                }

                do {
                    try self.saveData(data, for: fileName)
                } catch let error {
                    promise.reject(error)
                }

            }, then: { result in
                switch result {
                case .success:
                    promise.fulfill(())
                case .failure(let error):
                    promise.reject(error)
                }
            })
        }
    }

    private func saveData(_ data: Data, for fileName: String) throws {
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
        case clientNotAvailable
    }
}
