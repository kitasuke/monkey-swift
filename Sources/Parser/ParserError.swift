//
//  ParserError.swift
//  ParserError
//
//  Created by Yusuke Kita on 11/15/18.
//

import Foundation
import Token
import Lexer

public enum ParserError: Error {
    case noValidStatements
    case peekTokenNotMatch(expected: TokenType, actual: TokenType)

    public var message: String {
        switch self {
        case .noValidStatements:
            return "found no valid statements"
        case .peekTokenNotMatch(let expected, let actual):
            return String(format: "expected next token to be %s. got=%s", expected.literal, actual.literal)
        }
    }
}
