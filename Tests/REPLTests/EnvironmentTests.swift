//
//  EnvironmentTests.swift
//  ASTTests
//
//  Created by Yusuke Kita on 12/04/18.
//

import XCTest
import Syntax
import AST
@testable import REPL

final class EnvironmentTests: XCTestCase {
    func test_getObject() {
        let mockIdentifier = Identifier(token: .makeIdentifier(identifier: "foo"))
        let mockValue = IntegerObject(value: 5)
        let mockObjects: [Identifier: ObjectType] = [
            mockIdentifier: mockValue,
        ]
        let mockEnvironment = MockEnvironment(objects: mockObjects)
        
        XCTAssertTrue(
            mockEnvironment.object(for: mockIdentifier)?.description == mockValue.description,
            "environment.object(for: foo) wrong. want=\(mockValue.description)"
        )
    }
    
    func test_setObject() {
        let mockEnvironment = MockEnvironment(objects: [:])

        let mockIdentifier = Identifier(token: .makeIdentifier(identifier: "foo"))
        let mockValue = IntegerObject(value: 5)
        
        XCTAssertNil(mockEnvironment.object(for: mockIdentifier), "environment.object(for: foo) should be nil")
        
        mockEnvironment.set(mockValue, for: mockIdentifier)
        
        XCTAssertTrue(
            mockEnvironment.object(for: mockIdentifier)?.description == mockValue.description,
            "environment.object(for: foo) wrong. want=\(mockValue.description)"
        )
    }
}

final class MockEnvironment: EnvironmentType {
    let outer: EnvironmentType?
    var storedObjects: [Identifier : ObjectType]
    
    init(objects: [Identifier: ObjectType], outer: EnvironmentType? = nil) {
        self.outer = outer
        storedObjects = objects
    }
    
    func object(for identifier: Identifier) -> ObjectType? {
        return storedObjects[identifier]
    }
    
    func set(_ object: ObjectType, for identifier: Identifier) {
        storedObjects[identifier] = object
    }
}
