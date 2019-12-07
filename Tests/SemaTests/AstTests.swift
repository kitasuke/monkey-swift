//
//  AstTests.swift
//  SemaTests
//
//  Created by Yusuke Kita on 11/15/18.
//

import XCTest
import Syntax
import Sema

final class AstTests: XCTestCase {
    func test_nextDescription() {
        
        let sourceFiles: [SourceFile] = [
            .init(
                statements: [
                    LetStatement(
                        token: .init(type: .let),
                        name: .init(token: .makeIdentifier(identifier: "x")),
                        value: IntegerLiteral(token: .makeNumber(number: "5"))
                    )
                ]
            ),
            .init(
                statements: [
                    LetStatement(
                        token: .init(type: .let),
                        name: .init(token: .makeIdentifier(identifier: "myVar")),
                        value: Identifier(token: .makeIdentifier(identifier: "anotherVar"))
                    )
                ]
            )
        ]
        
        let expectedDescriptions = [
            "let x = 5;",
            "let myVar = anotherVar;"
        ]
        
        for (index, program) in sourceFiles.enumerated() {
            XCTAssertTrue(program.description == expectedDescriptions[index], "program.description not \(expectedDescriptions[index])")
        }
    }
}
