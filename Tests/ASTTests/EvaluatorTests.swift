//
//  EvaluatorTests.swift
//  ASTTests
//
//  Created by Yusuke Kita on 12/04/18.
//

import XCTest
import Syntax
import Lexer
import Sema
import AST

typealias Integer = AST.Integer
typealias Boolean = AST.Boolean

final class EvaluatorTests: XCTestCase {
    func test_evaluateIntegerExpression() {
        let tests: [(input: String, expected: Int64)] = [
            (input: "5", expected: 5),
            (input: "10", expected: 10),
        ]
        
        tests.forEach {
            let object = makeObject(from: $0.input)
            testIntegerObject(object, expected: $0.expected)
        }
    }
    
    func test_evaluateBooleanExpression() {
        let tests: [(input: String, expected: Bool)] = [
            (input: "true", expected: true),
            (input: "false", expected: false),
        ]
        
        tests.forEach {
            let object = makeObject(from: $0.input)
            testBooleanObject(object, expected: $0.expected)
        }
    }
    
    private func testIntegerObject(_ object: Object, expected: Int64) {
        guard let integer = object as? Integer else {
            XCTFail("object not \(Integer.self). got=\(type(of: object))")
            return
        }
        
        XCTAssertTrue(integer.value == expected, "integer.value wrong. want=\(expected), got=\(integer.value)")
    }
    
    private func testBooleanObject(_ object: Object, expected: Bool) {
        guard let boolean = object as? Boolean else {
            XCTFail("object not \(Boolean.self). got=\(type(of: object))")
            return
        }
        
        XCTAssertTrue(boolean.value == expected, "boolean.value wrong. want=\(expected), got=\(boolean.value)")
    }
    
    private func makeObject(from input: String) -> Object {
        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        
        let program: Program
        let object: Object
        do {
            program = try parser.parse()
            
            let evaluator = Evaluator()
            object = try evaluator.evaluate(astNode: program)
        } catch let error as Error & CustomStringConvertible {
            XCTFail(error.description); fatalError()
        } catch {
            XCTFail("unknown error"); fatalError()
        }
        return object
    }
}
