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

public struct Parser {
    var lexer: Lexer
    var currentToken = Token(type: .unknown)
    var peekToken = Token(type: .unknown)
    
    public init(lexer: Lexer) {
        self.lexer = lexer
        
        setNextToken()
    }
    
    public mutating func parseProgram() throws -> Program {
        var statements: [Statement] = []
        
        while currentToken.type != .eof {
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
        switch currentToken.type {
        case .let: return try parseLetStatement()
        case .return: return try parseReturnStatement()
        default: return parseExpressionStatement()
        }
    }
    
    mutating func parseLetStatement() throws -> LetStatement {
        let letToken = currentToken
        
        do { try setNextToken(expects: .identifier)
        } catch let error {
            throw error
        }
        
        let name = Identifier(token: currentToken)
        
        do { try setNextToken(expects: .assign)
        }  catch let error {
            throw error
        }
        
        setNextToken()
        guard let value = parseExpression() as? Identifier else {
            throw ParserError.expressionParsingFailed(token: peekToken)
        }
        
        while !isPeekToken(equalTo: .semicolon) {
            setNextToken()
        }
        
        return .init(token: letToken, name: name, value: value)
    }
    
    mutating func parseReturnStatement() throws -> ReturnStatement {
        let returnToken = currentToken
        
        setNextToken()
        
        guard let value = parseExpression() as? Identifier else {
            throw ParserError.expressionParsingFailed(token: peekToken)
        }
        
        while !isPeekToken(equalTo: .semicolon) {
            setNextToken()
        }
        
        return .init(token: returnToken, value: value)
    }
    
    mutating func parseExpressionStatement() -> ExpressionStatement? {
        let expressionToken = currentToken
        
        guard let expression = parseExpression() else {
            return nil
        }
        
        if isPeekToken(equalTo: .semicolon) {
            setNextToken()
        }
        
        return .init(token: expressionToken, expression: expression)
    }
    
    func parseExpression(for precedence: Precedence = .lowest) -> Expression? {
        // prefix parsing
        switch currentToken.type {
        case .identifier: return parseIdentifier()
        case .int: return parseIntegerLiteral()
        default: return nil
        }
    }
    
    func parseIdentifier() -> Expression {
        return Identifier(token: currentToken)
    }
    
    func parseIntegerLiteral() -> Expression {
        return Identifier(token: .makeNumber(number: currentToken.literal))
    }
    
    mutating func setNextToken() {
        currentToken = peekToken
        peekToken = lexer.nextToken()
    }
    
    func isCurrentToken(equalTo tokenType: TokenType) -> Bool {
        return currentToken.type == tokenType
    }
    
    func isPeekToken(equalTo tokenType: TokenType) -> Bool {
        return peekToken.type == tokenType
    }
    
    mutating func setNextToken(expects tokenType: TokenType) throws {
        guard isPeekToken(equalTo: tokenType) else {
            throw ParserError.peekTokenNotMatch(expected: tokenType, actual: peekToken.type)
        }
        
        setNextToken()
    }
}
