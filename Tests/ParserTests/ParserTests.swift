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
        
        let program: Program
        do {
            program = try parser.parseProgram()
        } catch let error as ParserError {
            XCTFail(error.message); return
        } catch {
            XCTFail("parseProgram failed"); return
        }
        
        let statementsCount = program.statements.count
        let expectedCount = 3
        guard statementsCount == expectedCount else {
            XCTFail("program.statements does not contain \(expectedCount) statements. got=\(statementsCount)")
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
    
    func test_returnStatement() {
        let input = """
            return 5;
            return 10;
            return 993322;
        """
        
        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        
        let program: Program
        do {
            program = try parser.parseProgram()
        } catch let error as ParserError {
            XCTFail(error.message); return
        } catch {
            XCTFail("parseProgram failed"); return
        }
        
        let statementsCount = program.statements.count
        let expectedCount = 3
        guard statementsCount == expectedCount else {
            XCTFail("program.statements does not contain \(expectedCount) statements. got=\(statementsCount)")
            return
        }
        
        program.statements.forEach { statement in
            guard let returnStatement = statement as? ReturnStatement else {
                XCTFail("statement not \(ReturnStatement.self). got=\(type(of: statement))")
                return
            }
            
            guard returnStatement.token.type == .return else {
                XCTFail("tokenType not \(TokenType.return). got=\(returnStatement.token.type)")
                return
            }
        }
    }
    
    private func testLetStatement(_ statement: Statement, name: String) -> Bool {
        guard statement.tokenLiteral == Token(type: .let).literal else {
            XCTFail("tokenLiteral not \(Token(type: .let).literal). got=\(statement.tokenLiteral)")
            return false
        }
        
        guard let letStatement = statement as? LetStatement else {
            XCTFail("statement not \(LetStatement.self). got=\(type(of: statement))")
            return false
        }
        
        guard letStatement.name.value == name else {
            XCTFail("value not \(letStatement.name.value). got=\(name)")
            return false
        }
        
        guard letStatement.name.tokenLiteral == name else {
            XCTFail("tokenLiteral not \(letStatement.name.tokenLiteral). got=\(name)")
            return false
        }
        
        return true
    }
}
