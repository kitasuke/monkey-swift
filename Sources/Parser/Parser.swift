//
//  Parser.swift
//  Parser
//
//  Created by Yusuke Kita on 11/15/18.
//

import Token
import Lexer
import Ast

enum TokenParseError: Error {
    case peekTokenNotMatch
}

public struct Parser {
    var lexer: Lexer
    var currentTokenType: TokenType = .unknown
    var peekTokenType: TokenType = .unknown
    
    public init(lexer: Lexer) {
        self.lexer = lexer
        
        setNextToken()
    }
    
    public mutating func parseProgram() -> Program? {
        var statements: [Statement] = []
        
        while currentTokenType != .eof {
            if let statement = parseStatement() {
                statements.append(statement)
            }
            setNextToken()
        }
        
        guard !statements.isEmpty else {
            return nil
        }
        return Program(statements: statements)
    }
    
    mutating func parseStatement() -> Statement? {
        switch currentTokenType {
        case .let: return parseLetStatement()
        default: return nil
        }
    }
    
    mutating func parseLetStatement() -> LetStatement? {
        let letTokenType = currentTokenType
        
        do { try setNextToken(expects: .identifier(type: .notSet))
        } catch { return nil }
        
        let name = Identifier(tokenType: currentTokenType)
        
        do { try setNextToken(expects: .assign)
        } catch { return nil }
        
        while !isCurrentToken(equalTo: .semicolon) {
            setNextToken()
        }
        
        return LetStatement(tokenType: letTokenType, name: name)
    }
    
    mutating func setNextToken() {
        currentTokenType = peekTokenType
        peekTokenType = lexer.nextTokenType()
    }
    
    func isCurrentToken(equalTo tokenType: TokenType) -> Bool {
        return currentTokenType == tokenType
    }
    
    func isPeekToken(equalTo tokenType: TokenType) -> Bool {
        return peekTokenType == tokenType
    }
    
    mutating func setNextToken(expects tokenType: TokenType) throws {
        guard isPeekToken(equalTo: tokenType) else {
            throw TokenParseError.peekTokenNotMatch
        }
        
        setNextToken()
    }
}
