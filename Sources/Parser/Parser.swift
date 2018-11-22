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
    
    private mutating func parseStatement() throws -> Statement? {
        switch currentToken.type {
        case .let: return try parseLetStatement()
        case .return: return try parseReturnStatement()
        default: return parseExpressionStatement()
        }
    }
    
    private mutating func parseLetStatement() throws -> LetStatement {
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
        guard let value = try parseExpression() else {
            throw ParserError.expressionParsingFailed(token: peekToken)
        }
        
        while !isPeekToken(equalTo: .semicolon) {
            setNextToken()
        }
        
        return .init(token: letToken, name: name, value: value)
    }
    
    private mutating func parseReturnStatement() throws -> ReturnStatement {
        let returnToken = currentToken
        
        setNextToken()
        
        guard let value = try parseExpression() else {
            throw ParserError.expressionParsingFailed(token: peekToken)
        }
        
        while !isPeekToken(equalTo: .semicolon) {
            setNextToken()
        }
        
        return .init(token: returnToken, value: value)
    }
    
    private mutating func parseExpressionStatement() -> ExpressionStatement? {
        let expressionToken = currentToken
        
        let expression: Expression
        do {
            guard let _expression = try parseExpression() else {
                return nil
            }
            expression = _expression
        } catch {
            fatalError()
        }
        
        if isPeekToken(equalTo: .semicolon) {
            setNextToken()
        }
        
        return .init(token: expressionToken, expression: expression)
    }
    
    private mutating func parseExpression(for precedence: Precedence = .lowest) throws -> Expression? {
        // prefix parsing
        return try parsePrefixOperator()
    }
    
    private mutating func parsePrefixExpression() throws -> Expression {
        let prefixToken = currentToken
        
        setNextToken()
        guard let right = try parseExpression(for: .prefix) else {
            fatalError()
        }
        return PrefixExpression(token: currentToken, operator: prefixToken.literal, right: right)
    }
    
    private mutating func parsePrefixOperator() throws -> Expression? {
        switch currentToken.type {
        case .identifier: return parseIdentifier()
        case .int: return parseIntegerLiteral()
        case .bang, .minus: return try parsePrefixExpression()
        default: return nil
        }
    }
    
    private func parseIdentifier() -> Expression {
        return Identifier(token: currentToken)
    }
    
    private func parseIntegerLiteral() -> Expression {
        return IntegerLiteral(token: .makeNumber(number: currentToken.literal))
    }

    private mutating func setNextToken() {
        currentToken = peekToken
        peekToken = lexer.nextToken()
    }
    
    private func isCurrentToken(equalTo tokenType: TokenType) -> Bool {
        return currentToken.type == tokenType
    }
    
    private func isPeekToken(equalTo tokenType: TokenType) -> Bool {
        return peekToken.type == tokenType
    }
    
    private mutating func setNextToken(expects tokenType: TokenType) throws {
        guard isPeekToken(equalTo: tokenType) else {
            throw ParserError.peekTokenNotMatch(expected: tokenType, actual: peekToken.type)
        }
        
        setNextToken()
    }
}
