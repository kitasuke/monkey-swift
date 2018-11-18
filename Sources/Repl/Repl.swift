//
//  Repl.swift
//  Repl
//
//  Created by Yusuke Kita on 11/15/18.
//

import Token
import Lexer

private let prompt = ">> "

public struct Repl {
    
    public static func start(with input: String) {
        var lexer = Lexer(input: input)
        var token = lexer.nextToken()

        while token.type != .eof {
            print(token.literal)
            token = lexer.nextToken()
        }
    }
}
