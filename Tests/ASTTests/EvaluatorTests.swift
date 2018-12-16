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
    
    func test_ifElseExpressions() {
        let tests: [(input: String, expected: Int64?)] = [
            (input: "if (true) { 10 }", expected: 10),
            (input: "if (false) { 10 }", expected: nil),
            (input: "if (1) { 10 }", expected: 10),
            (input: "if (1 < 2) { 10 }", expected: 10),
            (input: "if (1 > 2) { 10 }", expected: nil),
            (input: "if (1 > 2) { 10 } else { 20 }", expected: 20),
            (input: "if (1 < 2) { 10 } else { 20 }", expected: 10),
        ]
        
        tests.forEach {
            let object = makeObject(from: $0.input)
            if let value = $0.expected {
                testIntegerObject(object, expected: value)
            } else {
                testNullObject(object)
            }
        }
    }
    
    func test_returnStatements() {
        let tests: [(input: String, expected: Int64)] = [
            (input: "return 10;", expected: 10),
            (input: "return 10; 9;", expected: 10),
            (input: "return 2 * 5; 9;", expected: 10),
            (input: "9; return 2 * 5; 9;", expected: 10),
            (input:
                """
                    if (10 > 1) {
                         if (10 > 1) {
                           return 10;
                        }
                        return 1;
                    }
                """,
             expected: 10)
        ]
        
        tests.forEach {
            let object = makeObject(from: $0.input)
            testIntegerObject(object, expected: $0.expected)
        }
    }
    
    func test_letStatements() {
        let tests: [(input: String, expected: Int64)] = [
            (input: "let a = 5; a;", expected: 5),
            (input: "let a = 5 * 5; a;", expected: 25),
            (input: "let a = 5; let b = a; b;", expected: 5),
            (input: "let a = 5; let b = a; let c = a + b + 5; c;", expected: 15),
        ]
        
        tests.forEach {
            let object = makeObject(from: $0.input)
            testIntegerObject(object, expected: $0.expected)
        }
    }
    
    func test_functionObject() {
        let input = "fn(x) { x + 2; };"
        
        let object = makeObject(from: input)
        
        guard let function = object as? Function else {
            XCTFail("object not \(FunctionLiteral.self). got=\(type(of: object))")
            fatalError()
        }
        
        XCTAssertTrue(function.parameters.count == 1, "function.parameters.count not 1. got=\(function.parameters.count)")
        XCTAssertTrue(function.parameters[0].description == "x", "parameter.description not 'x'. got=\(function.parameters[0].description)")
        XCTAssertTrue(function.body.description == "(x + 2)", "body.description not `(x + 2)`. got=\(function.body.description)")
    }
    
    func test_functionApplication() {
        let tests: [(input: String, expected: Int64)] = [
            (input: "let identity = fn(x) { x; }; identity(5);", expected: 5),
            (input: "let identity = fn(x) { return 10; x; }; identity(5);", expected: 10),
        ]

        tests.forEach {
            let object = makeObject(from: $0.input)
            testIntegerObject(object, expected: $0.expected)
        }
    }
    
    func test_errorHandling() {
        let tests: [(input: String, expected: EvaluatorError)] = [
            (input: "5 + true;", expected: EvaluatorError.typeMissMatch(left: .integer, operator: "+", right: .boolean)),
            (input: "5 + true; 5;", expected: EvaluatorError.typeMissMatch(left: .integer, operator: "+", right: .boolean)),
            (input: "-true", expected: EvaluatorError.unknownOperator(left: nil, operator: "-", right: .boolean)),
            (input: "true + false;", expected: EvaluatorError.unknownOperator(left: .boolean, operator: "+", right: .boolean)),
            (input: "5; true + false; 5;", expected: EvaluatorError.unknownOperator(left: .boolean, operator: "+", right: .boolean)),
            (input: "if (10 > 1) { true + false; }", expected: EvaluatorError.unknownOperator(left: .boolean, operator: "+", right: .boolean)),
            (input:
                """
                    if (10 > 1) {
                      if (10 > 1) {
                        return true + false;
                      }
                    return 1;
                    }
                """,
             expected: EvaluatorError.unknownOperator(left: .boolean, operator: "+", right: .boolean)),
            (input: "foobar", expected: EvaluatorError.unknownNode(Identifier(token: .makeIdentifier(identifier: "foobar")))),
        ]
        
        tests.forEach {
            let program = makeProgram(from: $0.input)
            do {
                let environment = Environment()
                let evaluator = Evaluator()
                _ = try evaluator.evaluate(node: program, with: environment)
                XCTFail("shouldn't reach here")
            } catch let error as EvaluatorError {
                print(error)
                print($0.expected)
                XCTAssertTrue(error == $0.expected, "error wrong. got=\(error.description), want=\($0.expected)")
            } catch {
                XCTFail("unknown error"); fatalError()
            }
        }
    }
    
    private func test_stringLiteral() {
        let input = "\"hello world!\""
        let object = makeObject(from: input)
        
        testStringObject(object, expected: "hello world!")
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
    
    private func testStringObject(_ object: Object, expected: String) {
        guard let stringObject = object as? StringObject else {
            XCTFail("object not \(StringObject.self). got=\(type(of: object))")
            return
        }
        
        XCTAssertTrue(stringObject.value == expected, "stringObject.value wrong. want=\(expected), got=\(stringObject.value)")
    }
    
    private func testNullObject(_ object: Object) {
        XCTAssertTrue(object.type == .null, "")
    }
    
    private func makeProgram(from input: String) -> Program {
        let lexer = Lexer(input: input)
        let parser = Parser(lexer: lexer)
        
        let program: Program
        do {
            program = try parser.parse()
        } catch let error as Error & CustomStringConvertible {
            XCTFail(error.description); fatalError()
        } catch {
            XCTFail("unknown error"); fatalError()
        }
        return program
    }
    
    private func makeObject(from program: Program) -> Object {
        let object: Object
        do {
            let environment = Environment()
            let evaluator = Evaluator()
            object = try evaluator.evaluate(node: program, with: environment)
        } catch let error as Error & CustomStringConvertible {
            XCTFail(error.description); fatalError()
        } catch {
            XCTFail("unknown error"); fatalError()
        }
        return object
    }
    
    private func makeObject(from input: String) -> Object {
        let program = makeProgram(from: input)
        let object = makeObject(from: program)
        return object
    }
}

extension EvaluatorError: Equatable {
    public static func == (lhs: EvaluatorError, rhs: EvaluatorError) -> Bool {
        switch (lhs, rhs) {
        case (.typeMissMatch(let lhsLeft, let lhsOperator, let lhsRight),
              .typeMissMatch(let rhsLeft, let rhsOperator, let rhsRight)),
             (.unknownOperator(let lhsLeft?, let lhsOperator, let lhsRight),
              .unknownOperator(let rhsLeft?, let rhsOperator, let rhsRight)):
            return (lhsLeft == rhsLeft) && (lhsOperator == rhsOperator) && (lhsRight == rhsRight)
        case (.unknownOperator(_, let lhsOperator, let lhsRight),
              .unknownOperator(_, let rhsOperator, let rhsRight)):
            return (lhsOperator == rhsOperator) && (lhsRight == rhsRight)
        case (.unknownNode(let lhsNode), .unknownNode(let rhsNode)):
            return lhsNode.description == rhsNode.description
        default:
            // return false because there is no need to test other errors
            return false
        }
    }
}
