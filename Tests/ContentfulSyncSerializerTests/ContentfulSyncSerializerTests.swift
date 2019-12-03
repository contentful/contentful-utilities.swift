//
//  BundledDatabaseTests.swift
//  BundledDatabaseTests
//
//  Created by JP Wright on 07.09.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

@testable import ContentfulSyncSerializer
import XCTest
import Foundation
import Files


class ContentfulSyncSerializerTests: XCTestCase {

    func testSavingJSONFilesToDirectory() {

        do {
            // Setup a temp test folder that can be used as a sandbox
            let tempFolder = Folder.temporary
            let testFolder = try tempFolder.createSubfolderIfNeeded(
                withName: "ContentfulSyncSerializerTests"
            )
            // Empty the test folder to ensure a clean state
            try testFolder.empty()

            // Make the temp folder the current working folder
            let fileManager = FileManager.default
            fileManager.changeCurrentDirectoryPath(testFolder.path)

            // Uses Complex Sync Test Space to check mulitpage sync. First argument is always working directory.
            let syncJSONDowloader = SyncJSONDownloader(spaceId: "smf0sqiu0c5s",
                                                       accessToken: "14d305ad526d4487e21a99b5b9313a8877ce6fbf540f02b12189eea61550ef34",
                                                       outputDirectoryPath: testFolder.path,
                                                       shouldDownloadMediaFiles: false)

            let expectation = self.expectation(description: "Will download JSON files")
            // syncJSONDowloader the tool and assert that the file was created
            syncJSONDowloader.run() { result in
                guard let success = result.value, success == true else {
                    XCTAssert(false, "SyncJSONDownloader failed to sync json files with error: \(result.error!)")
                    expectation.fulfill()
                    return
                }
                XCTAssertNotNil(try? testFolder.file(named: "locales.json"))
                XCTAssertNotNil(try? testFolder.file(named: "0.json"))
                XCTAssertNotNil(try? testFolder.file(named: "1.json"))

                expectation.fulfill()
            }
            waitForExpectations(timeout: 10.0, handler: nil)
            try testFolder.delete()
        } catch {
            XCTAssert(false, "Test failed due to error being thrown: \(error)")
        }
    }

    func testSavingImageDataFilesToDirectory() {

        do {
            // Setup a temp test folder that can be used as a sandbox
            let tempFolder = Folder.temporary
            let testFolder = try tempFolder.createSubfolderIfNeeded(
                withName: "ContentfulSyncSerializerTests"
            )
            // Empty the test folder to ensure a clean state
            try testFolder.empty()

            // Make the temp folder the current working folder
            let fileManager = FileManager.default
            fileManager.changeCurrentDirectoryPath(testFolder.path)

            // Uses Complex Sync Test Space.
            let syncJSONDowloader = SyncJSONDownloader(spaceId: "cfexampleapi",
                                                       accessToken: "b4c0n73n7fu1",
                                                       outputDirectoryPath: testFolder.path,
                                                       shouldDownloadMediaFiles: true)

            let expectation = self.expectation(description: "Will download JSON files")
            // syncJSONDowloader the tool and assert that the file was created
            syncJSONDowloader.run() { result in
                guard let success = result.value, success == true else {
                    XCTAssert(false, "SyncJSONDownloader failed to sync json files")
                    expectation.fulfill()
                    return
                }
                XCTAssertNotNil(try? testFolder.file(named: "locales.json"))
                XCTAssertNotNil(try? testFolder.file(named: "0.json"))
                XCTAssertNotNil(try? testFolder.file(named: "cache_1x0xpXu4pSGS4OukSyWGUK.jpg"))
                XCTAssertNotNil(try? testFolder.file(named: "cache_happycat.jpg"))
                XCTAssertNotNil(try? testFolder.file(named: "cache_jake.png"))
                XCTAssertNotNil(try? testFolder.file(named: "cache_nyancat.png"))

                expectation.fulfill()
            }
            waitForExpectations(timeout: 10.0, handler: nil)
            try testFolder.delete()
        } catch {
            XCTAssert(false, "Test failed due to error being thrown: \(error)")
        }
    }
}

