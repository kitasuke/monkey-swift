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
    
    private var currentPrecedence: PrecedenceKind {
        return .precedence(for: currentToken.type)
    }
    private var peekPrecedence: PrecedenceKind {
        return .precedence(for: peekToken.type)
    }
    
    public init(lexer: Lexer) {
        self.lexer = lexer
        
        setNextToken()
    }
    
    public mutating func parseProgram() throws -> Program {
        var statements: [Statement] = []
        
        while currentToken.type != .eof {
            if let statement = try parseStatement() {
                statements.append(statement)
            }

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
    
    private mutating func parseBlockStatement() throws -> BlockStatement {
        let blockToken = currentToken
        var statements = [Statement]()
        
        setNextToken()
        
        while !isCurrentToken(equalTo: .rightBrace) &&
            !isCurrentToken(equalTo: .eof) {
            if let statement = try parseStatement() {
                statements.append(statement)
            }
            setNextToken()
        }
        return BlockStatement(token: blockToken, statements: statements)
    }
    
    private mutating func parseExpression(for precedence: PrecedenceKind = .lowest) throws -> Expression? {
        var expression: Expression
        guard let leftExpression = try parsePrefixOperator() else {
            return nil
        }
        expression = leftExpression
        
        while !isPeekToken(equalTo: .semicolon) &&
            precedence.rawValue < peekPrecedence.rawValue {
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
    
    private mutating func parseGroupedExpression() throws -> Expression? {
        setNextToken()
        
        guard let expression = try parseExpression() else {
            assertionFailure("failed to parse unexpected expression: \(currentToken)")
            return nil
        }
        
        try setNextToken(expects: .rightParen)
        
        return expression
    }
    
    private mutating func parseIfExpression() throws -> Expression? {
        let ifToken = currentToken
        
        try setNextToken(expects: .leftParen)
        setNextToken()
        
        guard let condition = try parseExpression() else {
            assertionFailure("failed to parse unexpected expression: \(currentToken)")
            return nil
        }
        
        try setNextToken(expects: .rightParen)
        try setNextToken(expects: .leftBrace)
        
        let consequence = try parseBlockStatement()
        
        let alternative: BlockStatement?
        if isPeekToken(equalTo: .else) {
            setNextToken()
            try setNextToken(expects: .leftParen)
            
            alternative = try parseBlockStatement()
        } else {
            alternative = nil
        }
        
        return IfExpression(token: ifToken, condition: condition, consequence: consequence, alternative: alternative)
    }
    
    private mutating func parsePrefixOperator() throws -> Expression? {
        switch currentToken.type {
        case .identifier: return parseIdentifier()
        case .int: return parseIntegerLiteral()
        case .true, .false: return parseBoolean()
        case .bang, .minus: return try parsePrefixExpression()
        case .leftParen: return try parseGroupedExpression()
        case .if: return try parseIfExpression()
        default: return nil
        }
    }
    
    private mutating func parseInfixExpression(with left: Expression) throws -> Expression? {
        let infixToken = currentToken
        
        let precedence = currentPrecedence
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
    
    private func parseBoolean() -> Expression {
        return Boolean(token: currentToken)
    }

    private mutating func setNextToken() {
        currentToken = peekToken
        peekToken = lexer.nextToken()
    }
    
    private mutating func setNextToken(expects tokenType: TokenType) throws {
        guard isPeekToken(equalTo: tokenType) else {
            throw ParserError.peekTokenNotMatch(expected: tokenType, actual: peekToken.type)
        }
        
        setNextToken()
    }
    
    private func isCurrentToken(equalTo tokenType: TokenType) -> Bool {
        return currentToken.type == tokenType
    }
    
    private func isPeekToken(equalTo tokenType: TokenType) -> Bool {
        return peekToken.type == tokenType
    }
}
