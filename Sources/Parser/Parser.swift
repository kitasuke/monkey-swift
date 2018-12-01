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
        
        // set initial state
        setNextToken()
    }
    
    public mutating func parseProgram() throws -> Program {
        var statements: [Statement] = []
        
        while currentToken.type != .eof {
            if let statement = try parseStatement() {
                statements.append(statement)
            }

            // move to next token
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
        // let
        let letToken = currentToken
        
        // x
        try setNextToken(expects: .identifier)

        let name = Identifier(token: currentToken)
        
        // =
        try setNextToken(expects: .assign)
        
        // x or 5
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
        // return
        let returnToken = currentToken
        
        // x or 5
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
        // x; x = y;...
        let blockToken = currentToken
        setNextToken()
        
        var statements = [Statement]()
        while !isCurrentToken(equalTo: .rightBrace) &&
            !isCurrentToken(equalTo: .eof) {
            if let statement = try parseStatement() {
                statements.append(statement)
            }
            // move to next token
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
        // (
        setNextToken()
        
        // x
        guard let expression = try parseExpression() else {
            assertionFailure("failed to parse unexpected expression: \(currentToken)")
            return nil
        }
        
        // )
        try setNextToken(expects: .rightParen)
        
        return expression
    }
    
    private mutating func parseIfExpression() throws -> Expression? {
        // if
        let ifToken = currentToken
        
        // (
        try setNextToken(expects: .leftParen)
        setNextToken()
        
        // x == y
        guard let condition = try parseExpression() else {
            assertionFailure("failed to parse unexpected expression: \(currentToken)")
            return nil
        }
        
        // )
        try setNextToken(expects: .rightParen)
        // {
        try setNextToken(expects: .leftBrace)
        
        // x + y;
        let consequence = try parseBlockStatement()
        
        let alternative: BlockStatement?
        if isPeekToken(equalTo: .else) {
            // else
            setNextToken()
            // (
            try setNextToken(expects: .leftParen)
            
            // y + z;
            alternative = try parseBlockStatement()
        } else {
            alternative = nil
        }
        
        return IfExpression(token: ifToken, condition: condition, consequence: consequence, alternative: alternative)
    }
    
    private mutating func parseCallExpression(with function: Expression) throws -> CallExpression {
        let arguments = try parseCallArguments()
        return CallExpression(token: currentToken, function: function, arguments: arguments)
    }
    
    private mutating func parseCallArguments() throws -> [Expression] {
        var arguments: [Expression] = []

        // (
        guard !isPeekToken(equalTo: .rightParen) else {
            setNextToken()
            return arguments
        }
        
        // x
        setNextToken()
        
        guard let argument = try parseExpression() else {
            throw ParserError.expressionParsingFailed(token: currentToken)
        }
        arguments.append(argument)
        
        while isPeekToken(equalTo: .comma) {
            // ,
            setNextToken()
            // y
            setNextToken()
            
            if let argument = try parseExpression() {
                arguments.append(argument)
            }
        }
        
        try setNextToken(expects: .rightParen)
        
        return arguments
    }
    
    private mutating func parsePrefixOperator() throws -> Expression? {
        switch currentToken.type {
        case .identifier: return parseIdentifier()
        case .int: return parseIntegerLiteral()
        case .true, .false: return parseBoolean()
        case .bang, .minus: return try parsePrefixExpression()
        case .leftParen: return try parseGroupedExpression()
        case .if: return try parseIfExpression()
        case .function: return try parseFunctionLiteral()
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
        case .leftParen:
            setNextToken()
            return try parseCallExpression(with: left)
        default: return nil
        }
    }
    
    private func parseIdentifier() -> Expression {
        return Identifier(token: currentToken)
    }
    
    private mutating func parseFunctionLiteral() throws -> Expression {
        let functionToken = currentToken
        
        // fn
        try setNextToken(expects: .leftParen)
        
        // (...)
        let parameters = try parseFunctionParameters()
        
        try setNextToken(expects: .leftBrace)
        
        let body = try parseBlockStatement()
        
        return FunctionLiteral(token: functionToken, parameters: parameters, body: body)
    }
    
    private mutating func parseFunctionParameters() throws -> [Identifier] {
        // (
        guard !isPeekToken(equalTo: .rightParen) else {
            setNextToken()
            return []
        }
        
        // x
        setNextToken()
        
        var identifiers: [Identifier] = []
        identifiers.append(Identifier(token: currentToken))
        
        while isPeekToken(equalTo: .comma) {
            // ,
            setNextToken()
            // y
            setNextToken()
            identifiers.append(Identifier(token: currentToken))
        }
        
        // )
        try setNextToken(expects: .rightParen)
        
        return identifiers
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
