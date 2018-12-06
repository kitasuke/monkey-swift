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

final class EvaluatorTests: XCTestCase {
    func test_evaluateIntegerExpression() {
        let tests: [(input: String, expected: Int64)] = [
            (input: "5", expected: 5),
            (input: "5", expected: 10),
        ]
    }
    
    private func makeObject(from input: String) -> Object {
        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        
        let program: Program
        let object: Object
        do {
            program = try parser.parse()
            
            let evaluator = Evaluator()
            object = try evaluator.evaluate(with: program)
        } catch let error as Error & CustomStringConvertible {
            XCTFail(error.description); fatalError()
        } catch {
            XCTFail("unknown error"); fatalError()
        }
        return object
    }
}
