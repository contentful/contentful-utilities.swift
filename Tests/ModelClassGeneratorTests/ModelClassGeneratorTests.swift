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
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        ContentTypeCodeGenerator().run {_ in 
            print("done")
        }
    }
}
