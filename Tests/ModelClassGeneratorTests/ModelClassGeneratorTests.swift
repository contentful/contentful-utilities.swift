//
//  ModelClassGeneratorTests.swift
//  ModelClassGeneratorTests
//
//  Created by JP Wright on 13.07.18.
//

@testable import ModelClassGenerator
import XCTest
import Interstellar
import Foundation


class ModelClassGeneratorTests: XCTestCase {

    func testExample() {
        let expectation = self.expectation(description: "")
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        StencilGenerator().go() { bool in
            print(bool.description)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }
}
