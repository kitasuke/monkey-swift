//
//  ParserError.swift
//  Sema
//
//  Created by Yusuke Kita on 11/15/18.
//

import Foundation
import Syntax
import Lexer

public enum ParserError: Error, CustomStringConvertible {
    case noValidStatements
    case peekTokenNotMatch(expected: TokenType, actual: TokenType)
    case expressionParsingFailed(token: Token)

    public var description: String {
        switch self {
        case .noValidStatements:
            return "found no valid statements"
        case .peekTokenNotMatch(let expected, let actual):
            return "expected next token to be \(expected). got=\(actual)"
        case .expressionParsingFailed(let token):
            return "expression parsing failed from \(token.type)"
        }
    }
}
