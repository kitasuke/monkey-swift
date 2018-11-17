//
//  ParserTests.swift
//  ParserTests
//
//  Created by Yusuke Kita on 11/15/18.
//

import XCTest
import Token
import Lexer
import Ast
import Parser

final class ParserTests: XCTestCase {
    func test_letStatement() {
        let input = """
            let x = 5;
            let y = 10;
            let foobar = 838383;
        """
        
        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        guard let program = parser.parseProgram() else {
            XCTFail("parseProgram() returned nil")
            return
        }
        let statementsCount = program.statements.count
        let expectedCount = 3
        guard statementsCount == expectedCount else {
            XCTFail(String(format: "program.statements does not contain %d statements. got=%d", expectedCount, statementsCount))
            return
        }
        
        let expectedIdentifiers = [
            "x",
            "y",
            "foobar"
        ]
        
        for (index, expectedIdentifier) in expectedIdentifiers.enumerated() {
            let statement = program.statements[index]
            if !testLetStatement(statement, name: expectedIdentifier) {
                return
            }
        }
    }
    
    private func testLetStatement(_ statement: Statement, name: String) -> Bool {
        guard statement.tokenLiteral == TokenType.let.literal else {
            XCTFail(String(format: "statement.tokenLiteral not %s. got=%s", TokenType.let.literal, statement.tokenLiteral))
            return false
        }
        
        guard let letStatement = statement as? LetStatement else {
            XCTFail("statement not \(LetStatement.self). got=\(type(of: statement))")
            return false
        }
        
        guard letStatement.name.value == name else {
            XCTFail(String(format: "letStatement.name.value not %s. got=%s", letStatement.name.value, name))
            return false
        }
        
        guard letStatement.name.tokenLiteral == name else {
            XCTFail(String(format: "statement.name not %s. got=%s", letStatement.name.tokenLiteral, name))
            return false
        }
        
        return true
    }
}
