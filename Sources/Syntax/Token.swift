//
//  Token.swift
//  Syntax
//
//  Created by Yusuke Kita on 11/15/18.
//

public enum TokenType {
    case unknown, illegal, eof

    // Identifiers + literals
    case identifier, int, string
    
    // Operators
    case assign, plus, minus, bang, asterisk, slash, comma, colon, semicolon, lessThan, greaterThan, equal, notEqual
    
    case leftParen, rightParen, leftBrace, rightBrace, leftBracket, rightBracket
    
    // Keywords
    case function, `let`, `true`, `false`, `if`, `else`, `return`
    
    public init(symbol: Character) {
        guard let symbol = TokenSymbol(rawValue: symbol) else {
            self = .unknown
            return
        }
        
        switch symbol {
        case .equal: self = .assign
        case .plus: self = .plus
        case .minus: self = .minus
        case .bang: self = .bang
        case .asterisk: self = .asterisk
        case .slash: self = .slash
        case .comma: self = .comma
        case .colon: self = .colon
        case .semicolon: self = .semicolon
        case .lessThan: self = .lessThan
        case .greaterThan: self = .greaterThan
        case .leftParen: self = .leftParen
        case .rightParen: self = .rightParen
        case .leftBrace: self = .leftBrace
        case .rightBrace: self = .rightBrace
        case .leftBracket: self = .leftBracket
        case .rightBracket: self = .rightBracket
        case .doubleQuatation: fatalError()
        }
    }
    
    public init(number: String) {
        let value = Int(number)
        assert(value != nil)
        self = .int
    }
    
    public init(identifier: String) {
        guard let keyword = TokenKeyword(rawValue: identifier) else {
            self = .identifier
            return
        }
        
        switch keyword {
        case .fn: self = .function
        case .let: self = .let
        case .true: self = .true
        case .false: self = .false
        case .if: self = .if
        case .else: self = .else
        case .return: self = .return
        }
    }
}

extension TokenType: Hashable {}

public struct Token {
    public let type: TokenType
    public let literal: String
    
    public init(type: TokenType) {
        self.type = type
        
        let literal: String
        switch type {
        case .illegal: literal = "Illegal"
        case .eof: literal = "EOF"
        case .identifier, .int, .string:
            assertionFailure("not supported")
            literal = ""
        case .assign: literal = String(TokenSymbol.equal.rawValue)
        case .plus: literal = String(TokenSymbol.plus.rawValue)
        case .minus: literal = String(TokenSymbol.minus.rawValue)
        case .bang: literal = String(TokenSymbol.bang.rawValue)
        case .asterisk: literal = String(TokenSymbol.asterisk.rawValue)
        case .slash: literal = String(TokenSymbol.slash.rawValue)
        case .comma: literal = String(TokenSymbol.comma.rawValue)
        case .colon: literal = String(TokenSymbol.colon.rawValue)
        case .semicolon: literal = String(TokenSymbol.semicolon.rawValue)
        case .lessThan: literal = String(TokenSymbol.lessThan.rawValue)
        case .greaterThan: literal = String(TokenSymbol.greaterThan.rawValue)
        case .equal: literal = String(TokenSymbol.equal.rawValue) + String(TokenSymbol.equal.rawValue)
        case .notEqual: literal = String(TokenSymbol.bang.rawValue) + String(TokenSymbol.equal.rawValue)
        case .leftParen: literal = String(TokenSymbol.leftParen.rawValue)
        case .rightParen: literal = String(TokenSymbol.rightParen.rawValue)
        case .leftBrace: literal = String(TokenSymbol.leftBrace.rawValue)
        case .rightBrace: literal = String(TokenSymbol.rightBrace.rawValue)
        case .leftBracket: literal = String(TokenSymbol.leftBracket.rawValue)
        case .rightBracket: literal = String(TokenSymbol.rightBracket.rawValue)
        case .function: literal = TokenKeyword.fn.rawValue
        case .let: literal = TokenKeyword.let.rawValue
        case .true: literal = TokenKeyword.true.rawValue
        case .false: literal = TokenKeyword.false.rawValue
        case .if: literal = TokenKeyword.if.rawValue
        case .else: literal = TokenKeyword.else.rawValue
        case .return: literal = TokenKeyword.return.rawValue
        case .unknown: literal = ""
        }
        self.literal = literal
    }
    
    init(type: TokenType, literal: String) {
        self.type = type
        self.literal = literal
    }
    
    public static func makeIdentifier(identifier: String) -> Token {
        let type = TokenType(identifier: identifier)
        return Token(type: type, literal: identifier)
    }
    
    public static func makeNumber(number: String) -> Token {
        let type = TokenType(number: number)
        return Token(type: type, literal: number)
    }
    
    public static func makeString(string: String) -> Token {
        return Token(type: .string, literal: string)
    }
}

extension Token: Hashable {}
