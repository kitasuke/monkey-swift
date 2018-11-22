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
            testLetStatement(statement, name: expectedIdentifier)
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
            
            XCTAssertTrue(returnStatement.token.type == .return, "tokenType not \(TokenType.return). got=\(returnStatement.token.type)")
        }
    }
    
    func test_identifierExpression() {
        let input = "foobar;"
        
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
        
        guard !program.statements.isEmpty else {
            XCTFail("program.statements is empty")
            return
        }
        
        guard let stmt = program.statements[0] as? ExpressionStatement else {
            XCTFail("program.statements[0] not \(ExpressionStatement.self). got=\(type(of: program.statements[0]))")
            return
        }
        
        guard let identifier = stmt.expression as? Identifier else {
            XCTFail("stmt.expression not \(Identifier.self). got=\(stmt.expression)")
            return
        }
        
        XCTAssertTrue(identifier.value == "foobar", "identifier.value not foobar. got=\(identifier.value)")
        XCTAssertTrue(identifier.tokenLiteral == "foobar", "identifier.tokenLiteral not foobar. got=\(identifier.tokenLiteral)")
    }
    
    func test_parsingPrefixExpressions() {
        let prefixTests: [(input: String, `operator`: String, value: Int64)] = [
            (input: "!5", operator: "!", value: 5),
            (input: "-15", operator: "-", value: 15)
        ]
        
        prefixTests.forEach {
            let lexer = Lexer(input: $0.input)
            var parser = Parser(lexer: lexer)

            let program: Program
            do {
                program = try parser.parseProgram()
            } catch let error as ParserError {
                XCTFail(error.message); return
            } catch {
                XCTFail("parseProgram failed"); return
            }
            
            guard !program.statements.isEmpty else {
                XCTFail("program.statements is empty")
                return
            }
            
            guard let statement = program.statements[0] as? ExpressionStatement else {
                XCTFail("program.statements[0] not \(ExpressionStatement.self). got=\(type(of: program.statements[0]))")
                return
            }
            
            guard let expression = statement.expression as? PrefixExpression else {
                XCTFail("statement.expression not \(PrefixExpression.self). got=\(type(of: statement.expression))")
                return
            }
            
            XCTAssertTrue(expression.operator == $0.operator, "expression.operator not \($0.operator). got=\(expression.operator)")
            testIntegerLiteral($0.value, with: expression.right)
        }
    }
    
    private func testLetStatement(_ statement: Statement, name: String) {
        guard statement.tokenLiteral == Token(type: .let).literal else {
            XCTFail("tokenLiteral not \(Token(type: .let).literal). got=\(statement.tokenLiteral)")
            return
        }
        
        guard let letStatement = statement as? LetStatement else {
            XCTFail("statement not \(LetStatement.self). got=\(type(of: statement))")
            return
        }
        
        XCTAssertTrue(letStatement.name.value == name, "letStatement.name not \(name). got=\(letStatement.name)")
        XCTAssertTrue(letStatement.name.tokenLiteral == name, "letStatement.name.tokenLiteral not \(name). got=\(letStatement.name.tokenLiteral)")
    }
    
    private func testIntegerLiteral(_ value: Int64, with expression: Expression) {
        guard let integerLiteral = expression as? IntegerLiteral else {
            XCTFail("expression not \(IntegerLiteral.self). got=\(type(of: expression))")
            return
        }
        
        XCTAssertTrue(integerLiteral.value == value, "integerLiteral.value not \(value). got=\(integerLiteral.value)")
        XCTAssertTrue(integerLiteral.tokenLiteral == "\(value)", "integerLiteral.tokenLiteral not \(value). got=\(integerLiteral.tokenLiteral)")
    }
}
