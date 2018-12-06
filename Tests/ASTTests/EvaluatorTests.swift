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
            (input: "-5", expected: -5),
            (input: "-10", expected: -10),
            (input: "5 + 5 + 5 + 5 - 10", expected: 10),
            (input: "2 * 2 * 2 * 2 * 2", expected: 32),
            (input: "-50 + 100 + -50", expected: 0),
            (input: "5 * 2 + 10", expected: 20),
            (input: "5 + 2 * 10", expected: 25),
            (input: "20 + 2 * -10", expected: 0),
            (input: "50 / 2 * 2 + 10", expected: 60),
            (input: "2 * (5 + 10)", expected: 30),
            (input: "3 * 3 * 3 + 10", expected: 37),
            (input: "3 * (3 * 3) + 10", expected: 37),
            (input: "(5 + 10 * 2 + 15 / 3) * 2 + -10", expected: 50),
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
    
    func test_evaluateBangOperator() {
        let tests: [(input: String, expected: Bool)] = [
            (input: "!true", expected: false),
            (input: "!false", expected: true),
            (input: "!5", expected: false),
            (input: "!!true", expected: true),
            (input: "!!false", expected: false),
            (input: "!!5", expected: true),
            (input: "true == true", expected: true),
            (input: "false == false", expected: true),
            (input: "true == false", expected: false),
            (input: "true != false", expected: true),
            (input: "false != true", expected: true),
            (input: "(1 < 2) == true", expected: true),
            (input: "(1 < 2) == false", expected: false),
            (input: "(1 > 2) == true", expected: false),
            (input: "(1 > 2) == false", expected: true),
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
