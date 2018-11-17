//
//  Parser.swift
//  Parser
//
//  Created by Yusuke Kita on 11/15/18.
//

import Foundation
import Token
import Lexer
import Ast

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

public struct Parser {
    var lexer: Lexer
    var currentTokenType: TokenType = .unknown
    var peekTokenType: TokenType = .unknown
    
    
    public init(lexer: Lexer) {
        self.lexer = lexer
        
        setNextToken()
    }
    
    public mutating func parseProgram() throws -> Program {
        var statements: [Statement] = []
        
        while currentTokenType != .eof {
            do {
                if let statement = try parseStatement() {
                    statements.append(statement)
                }
            } catch let error { throw error }

            setNextToken()
        }
        
        guard !statements.isEmpty else {
            throw ParserError.noValidStatements
        }
        return Program(statements: statements)
    }
    
    mutating func parseStatement() throws -> Statement? {
        switch currentTokenType {
        case .let: return try parseLetStatement()
        default: return nil
        }
    }
    
    mutating func parseLetStatement() throws -> LetStatement {
        let letTokenType = currentTokenType
        
        do { try setNextToken(expects: .identifier(type: .notSet))
        } catch let error {
            throw error
        }
        
        let name = Identifier(tokenType: currentTokenType)
        
        do { try setNextToken(expects: .assign)
        }  catch let error {
            throw error
        }
        
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
            throw ParserError.peekTokenNotMatch(expected: tokenType, actual: peekTokenType)
        }
        
        setNextToken()
    }
}
