//
//  Repl.swift
//  Repl
//
//  Created by Yusuke Kita on 11/15/18.
//

import Syntax
import Lexer
import Sema

public struct Repl {
    
    public static func start(with input: String) {
        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        do {
            let program = try parser.parse()
            print(program.description)
        } catch let error as Error & CustomStringConvertible {
            print(error.description)
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
