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
        default: return try parseExpressionStatement()
        }
    }
    
    private mutating func parseLetStatement() throws -> LetStatement {
        let letToken = currentToken
        
        try setNextToken(expects: .identifier)

        let name = Identifier(token: currentToken)
        
        try setNextToken(expects: .assign)
        
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
    
    private mutating func parseExpressionStatement() throws -> ExpressionStatement? {
        let expressionToken = currentToken
        
        guard let expression = try parseExpression() else {
            return nil
        }
        
        if isPeekToken(equalTo: .semicolon) {
            setNextToken()
        }
        
        return .init(token: expressionToken, expression: expression)
    }
    
    private mutating func parseExpression(for precedence: PrecedenceKind = .lowest) throws -> Expression? {
        var expression: Expression
        guard let leftExpression = try parsePrefixOperator() else {
            return nil
        }
        expression = leftExpression
        
        while !isPeekToken(equalTo: .semicolon) &&
            precedence.rawValue < peekPrecedence().rawValue {
            guard let infixExpression = try parseInfixOperator(with: expression) else {
                return leftExpression
            }
            
            expression = infixExpression
        }
        
        return expression
    }
    
    private mutating func parsePrefixExpression() throws -> Expression? {
        let prefixToken = currentToken
        
        setNextToken()
        guard let right = try parseExpression(for: .prefix) else {
            assertionFailure("failed to parse unexpected expression: \(currentToken)")
            return nil
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
    
    private mutating func parseInfixExpression(with left: Expression) throws -> Expression? {
        let infixToken = currentToken
        
        let precedence = currentPrecedence()
        setNextToken()
        
        guard let right = try parseExpression(for: precedence) else {
            return nil
        }
        
        return InfixExpression(token: infixToken, left: left, right: right)
    }
    
    private mutating func parseInfixOperator(with left: Expression) throws -> Expression? {
        switch peekToken.type {
        case .plus, .minus, .slash, .asterisk, .equal, .notEqual, .lessThan, .greaterThan:
            setNextToken()
            return try parseInfixExpression(with: left)
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
    
    private func peekPrecedence() -> PrecedenceKind {
        return PrecedenceKind.precedence(for: peekToken.type)
    }
    
    private func currentPrecedence() -> PrecedenceKind {
        return PrecedenceKind.precedence(for: currentToken.type)
    }
}
