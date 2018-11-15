//
//  Token.swift
//  Token
//
//  Created by Yusuke Kita on 11/15/18.
//

public enum TokenSymbol: Character {
    case equal = "="
    case plus = "+"
    case minus = "-"
    case bang = "!"
    case asterisk = "*"
    case slash = "/"
    case comma = ","
    case semicolon = ";"
    case leftParen = "("
    case rightParen = ")"
    case leftBrace = "{"
    case rightBrace = "}"
    case lessThan = "<"
    case greaterThan = ">"
}

public enum TokenKeyword: String {
    case fn = "fn"
    case `let` = "let"
    case `true` = "true"
    case `false` = "false"
    case `if` = "if"
    case `else` = "else"
    case `return` = "return"
}

public enum TokenType: Equatable {
    case unknown, illegal, eof

    // Identifiers + literals
    case identifier(name: String), int(value: Int)
    
    // Operators
    case assign, plus, minus, bang, asterisk, slash, comma, semicolon, lessThan, greaterThan, equal, notEqual
    
    case leftParen, rightParen, leftBrace, rightBrace
    
    // Keywords
    case function, `let`, `true`, `false`, `if`, `else`, `return`
    
    public var literal: String {
        switch self {
        case .illegal: return "Illegal"
        case .eof: return "EOF"
        case .identifier(let name): return name
        case .int(let value): return "\(value)"
        case .assign: return String(TokenSymbol.equal.rawValue)
        case .plus: return String(TokenSymbol.plus.rawValue)
        case .minus: return String(TokenSymbol.minus.rawValue)
        case .bang: return String(TokenSymbol.bang.rawValue)
        case .asterisk: return String(TokenSymbol.asterisk.rawValue)
        case .slash: return String(TokenSymbol.slash.rawValue)
        case .comma: return String(TokenSymbol.comma.rawValue)
        case .semicolon: return String(TokenSymbol.semicolon.rawValue)
        case .lessThan: return String(TokenSymbol.lessThan.rawValue)
        case .greaterThan: return String(TokenSymbol.greaterThan.rawValue)
        case .equal: return TokenType.equal.literal + TokenType.equal.literal
        case .notEqual: return TokenType.bang.literal + TokenType.equal.literal
        case .leftParen: return String(TokenSymbol.leftParen.rawValue)
        case .rightParen: return String(TokenSymbol.rightParen.rawValue)
        case .leftBrace: return String(TokenSymbol.leftBrace.rawValue)
        case .rightBrace: return String(TokenSymbol.rightBrace.rawValue)
        case .function: return TokenKeyword.fn.rawValue
        case .let: return TokenKeyword.let.rawValue
        case .true: return TokenKeyword.true.rawValue
        case .false: return TokenKeyword.false.rawValue
        case .if: return TokenKeyword.if.rawValue
        case .else: return TokenKeyword.else.rawValue
        case .return: return TokenKeyword.return.rawValue
        case .unknown: return ""
        }
    }
    
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
        case .semicolon: self = .semicolon
        case .lessThan: self = .lessThan
        case .greaterThan: self = .greaterThan
        case .leftParen: self = .leftParen
        case .rightParen: self = .rightParen
        case .leftBrace: self = .leftBrace
        case .rightBrace: self = .rightBrace
        }
    }
    
    public init(number: String) {
        let value = Int(number)
        assert(value != nil)
        self = .int(value: value ?? 0)
    }
    
    public init(identifier: String) {
        guard let keyword = TokenKeyword(rawValue: identifier) else {
            self = .identifier(name: identifier)
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
