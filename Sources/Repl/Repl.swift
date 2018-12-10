//
//  Repl.swift
//  Repl
//
//  Created by Yusuke Kita on 11/15/18.
//

import Syntax
import Lexer
import Sema
import AST

public struct Repl {
    
    public static func start(with input: String) {
        let lexer = Lexer(input: input)
        let parser = Parser(lexer: lexer)
        do {
            let program = try parser.parse()

            let evaluator = Evaluator()
            let object = try evaluator.evaluate(astNode: program)
            print(object.inspect())
        } catch let error as Error & CustomStringConvertible {
            print(error.description)
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
