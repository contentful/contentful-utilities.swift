//
//  ContentfulSyncSerializer
//
//  Created by Tomasz Szulc on 14/10/2020.
//

import Contentful
import Foundation

extension Client {

    @discardableResult
    func fetchContent(
        for syncSpace: SyncSpace,
        shouldDownloadAssets: Bool,
        reportDownloadedSyncSpace: @escaping (SyncSpace, Data, URL) -> Void,
        reportDownloadedAsset: @escaping (Asset, Data) -> Void,
        then completion: @escaping (Swift.Result<Void, Error>) -> Void
    ) -> URLSessionDataTask? {
        let parameters: [String: String]
        if syncSpace.hasMorePages {
            parameters = syncSpace.parameters
        } else {
            parameters = SyncSpace.SyncableTypes.all.parameters + syncSpace.parameters
        }

        let url = self.url(endpoint: .sync, parameters: parameters)

        return self.fetch(url: url) { [weak self] result in
            guard let self = self else {
                completion(.failure(SyncJSONDownloader.Error.failedToFetchSyncSpace))
                return
            }

            switch result {
            case .success(let data):
                do {
                    let updatedSyncSpace = try self.jsonDecoder.decode(SyncSpace.self, from: data)
                    reportDownloadedSyncSpace(updatedSyncSpace, data, url)

                    if shouldDownloadAssets {
                        self.fetchAssets(
                            assets: updatedSyncSpace.assets,
                            reportDownloadedAsset: reportDownloadedAsset,
                            completion: { result in
                                if updatedSyncSpace.hasMorePages {
                                    self.fetchContent(
                                        for: updatedSyncSpace,
                                        shouldDownloadAssets: shouldDownloadAssets,
                                        reportDownloadedSyncSpace: reportDownloadedSyncSpace,
                                        reportDownloadedAsset: reportDownloadedAsset,
                                        then: completion
                                    )
                                } else {
                                    completion(.success(()))
                                }
                            }
                        )
                    } else {
                        if updatedSyncSpace.hasMorePages {
                            self.fetchContent(
                                for: updatedSyncSpace,
                                shouldDownloadAssets: shouldDownloadAssets,
                                reportDownloadedSyncSpace: reportDownloadedSyncSpace,
                                reportDownloadedAsset: reportDownloadedAsset,
                                then: completion
                            )
                        } else {
                            completion(.success(()))
                        }
                    }
                } catch let error {
                    completion(.failure(error))
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func fetchAssets(
        assets: [Asset],
        reportDownloadedAsset: @escaping (Asset, Data) -> Void,
        completion: @escaping (Swift.Result<Void, Error>) -> Void
    ) {
        guard let asset = assets.last else {
            completion(.success(()))
            return
        }

        var remainingAssets = assets
        remainingAssets.removeLast()

        self.fetchData(for: asset) { [weak self] result in
            guard let self = self else {
                completion(.failure(SyncJSONDownloader.Error.clientNotAvailable))
                return
            }

            switch result {
            case .success(let data):
                reportDownloadedAsset(asset, data)

                self.fetchAssets(
                    assets: remainingAssets,
                    reportDownloadedAsset: reportDownloadedAsset,
                    completion: completion
                )

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
