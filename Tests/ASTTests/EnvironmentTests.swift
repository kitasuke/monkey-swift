//
//  EnvironmentTests.swift
//  ASTTests
//
//  Created by Yusuke Kita on 12/04/18.
//

import XCTest
import Syntax
import Lexer
import Sema
import AST

final class EnvironmentTests: XCTestCase {
    func test_getObject() {
        let mockIdentifier = Identifier(token: .makeIdentifier(identifier: "foo"))
        let mockValue = Integer(value: 5)
        let mockObjects: [Identifier: Object] = [
            mockIdentifier: mockValue,
        ]
        let mockEnvironment = MockEnvironment(objects: mockObjects)
        
        XCTAssertTrue(
            mockEnvironment.object(for: mockIdentifier)?.inspect() == mockValue.inspect(),
            "environment.object(for: foo) wrong. want=\(mockValue.inspect())"
        )
    }
    
    func test_setObject() {
        let mockEnvironment = MockEnvironment(objects: [:])

        let mockIdentifier = Identifier(token: .makeIdentifier(identifier: "foo"))
        let mockValue = Integer(value: 5)
        
        XCTAssertNil(mockEnvironment.object(for: mockIdentifier), "environment.object(for: foo) should be nil")
        
        mockEnvironment.set(mockValue, for: mockIdentifier)
        
        XCTAssertTrue(
            mockEnvironment.object(for: mockIdentifier)?.inspect() == mockValue.inspect(),
            "environment.object(for: foo) wrong. want=\(mockValue.inspect())"
        )
    }
}

final class MockEnvironment: EnvironmentType {
    let outer: EnvironmentType?
    var storedObjects: [Identifier : Object]
    
    init(objects: [Identifier: Object], outer: EnvironmentType? = nil) {
        self.outer = outer
        storedObjects = objects
    }
    
    func object(for identifier: Identifier) -> Object? {
        return storedObjects[identifier]
    }
    
    func set(_ object: Object, for identifier: Identifier) {
        storedObjects[identifier] = object
    }
}
