//
//  Repl.swift
//  Repl
//
//  Created by Yusuke Kita on 11/15/18.
//

import Token
import Lexer
import Parser

public struct Repl {
    
    public static func start(with input: String) {
        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        do {
            let program = try parser.parseProgram()
            print(program.description)
        } catch let error as ParserError {
            print(error.message)
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
