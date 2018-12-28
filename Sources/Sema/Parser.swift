//
//  Parser.swift
//  Sema
//
//  Created by Yusuke Kita on 11/15/18.
//

import Foundation
import Syntax
import Lexer

public final class Parser {
    private var lexer: Lexer
    private var currentToken = Token(type: .unknown)
    private var peekToken = Token(type: .unknown)
    
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
    
    public func parse() throws -> Program {
        var statements: [StatementType] = []
        
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
    
    private func parseStatement() throws -> StatementType? {
        switch currentToken.type {
        case .let: return try parseLetStatement()
        case .return: return try parseReturnStatement()
        case .illegal: throw ParserError.expressionParsingFailed(token: currentToken)
        default: return try parseExpressionStatement()
        }
    }
    
    private func parseLetStatement() throws -> LetStatement {
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
            throw ParserError.expressionParsingFailed(token: currentToken)
        }
        
        if isPeekToken(equalTo: .semicolon) {
            setNextToken()
        }
        
        return LetStatement(token: letToken, name: name, value: value)
    }
    
    private func parseReturnStatement() throws -> ReturnStatement {
        // return
        let returnToken = currentToken
        
        // x or 5
        setNextToken()
        guard let value = try parseExpression() else {
            throw ParserError.expressionParsingFailed(token: currentToken)
        }
        
        if isPeekToken(equalTo: .semicolon) {
            setNextToken()
        }
        
        return ReturnStatement(token: returnToken, value: value)
    }
    
    private func parseExpressionStatement() throws -> ExpressionStatement? {
        let expressionToken = currentToken
        
        guard let expression = try parseExpression() else {
            return nil
        }
        
        if isPeekToken(equalTo: .semicolon) {
            setNextToken()
        }
        
        return ExpressionStatement(token: expressionToken, expression: expression)
    }
    
    private func parseBlockStatement() throws -> BlockStatement {
        // x; x = y;...
        let blockToken = currentToken
        setNextToken()
        
        var statements = [StatementType]()
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
    
    private func parseExpression(for precedence: PrecedenceKind = .lowest) throws -> ExpressionType? {
        var expression: ExpressionType
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
    
    private func parsePrefixExpression() throws -> PrefixExpression {
        // !
        let prefixToken = currentToken
        setNextToken()
        
        // x
        guard let right = try parseExpression(for: .prefix) else {
            throw ParserError.expressionParsingFailed(token: currentToken)
        }
        return PrefixExpression(token: currentToken, operator: prefixToken.literal, right: right)
    }
    
    private func parseGroupedExpression() throws -> ExpressionType {
        // (
        setNextToken()
        
        // x
        guard let expression = try parseExpression() else {
            throw ParserError.expressionParsingFailed(token: currentToken)
        }
        
        // )
        try setNextToken(expects: .rightParen)
        
        return expression
    }
    
    private func parseIfExpression() throws -> IfExpression {
        // if
        let ifToken = currentToken
        
        // (
        try setNextToken(expects: .leftParen)
        setNextToken()
        
        // x == y
        guard let condition = try parseExpression() else {
            throw ParserError.expressionParsingFailed(token: currentToken)
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
            // {
            try setNextToken(expects: .leftBrace)
            
            // y + z;
            alternative = try parseBlockStatement()
        } else {
            alternative = nil
        }
        
        return IfExpression(token: ifToken, condition: condition, consequence: consequence, alternative: alternative)
    }
    
    private func parseCallExpression(with function: ExpressionType) throws -> CallExpression {
        let arguments = try parseExpressionList(until: .rightParen)
        return CallExpression(token: currentToken, function: function, arguments: arguments)
    }
    
    private func parseIndexExpression(with left: ExpressionType) throws -> IndexExpression {
        let indexToken = currentToken
        
        // [
        setNextToken()
        
        // x
        guard let index = try parseExpression() else {
            throw ParserError.expressionParsingFailed(token: currentToken)
        }
        
        // ]
        try setNextToken(expects: .rightBracket)
        
        return IndexExpression(token: indexToken, left: left, index: index)
    }
    
    private func parseExpressionList(until end: TokenType) throws -> [ExpressionType] {
        var list: [ExpressionType] = []

        // (
        guard !isPeekToken(equalTo: end) else {
            setNextToken()
            return list
        }
        
        // x
        setNextToken()
        
        guard let element = try parseExpression() else {
            throw ParserError.expressionParsingFailed(token: currentToken)
        }
        list.append(element)
        
        while isPeekToken(equalTo: .comma) {
            // ,
            setNextToken()
            // y
            setNextToken()
            
            guard let element = try parseExpression() else {
                throw ParserError.expressionParsingFailed(token: currentToken)
            }
            list.append(element)
        }
        
        try setNextToken(expects: end)
        
        return list
    }
    
    private func parsePrefixOperator() throws -> ExpressionType? {
        switch currentToken.type {
        case .identifier: return parseIdentifier()
        case .int: return parseIntegerLiteral()
        case .string: return parseStringLiteral()
        case .true, .false: return parseBoolean()
        case .bang, .minus: return try parsePrefixExpression()
        case .leftParen: return try parseGroupedExpression()
        case .if: return try parseIfExpression()
        case .function: return try parseFunctionLiteral()
        case .leftBracket: return try parseArrayLiteral()
        case .leftBrace: return try parseDictionaryLiteral()
        default: return nil
        }
    }
    
    private func parseInfixExpression(with left: ExpressionType) throws -> InfixExpression {
        // +
        let infixToken = currentToken
        
        // y
        let precedence = currentPrecedence
        setNextToken()
        guard let right = try parseExpression(for: precedence) else {
            throw ParserError.expressionParsingFailed(token: currentToken)
        }
        
        return InfixExpression(token: infixToken, left: left, right: right)
    }
    
    private func parseInfixOperator(with left: ExpressionType) throws -> ExpressionType? {
        switch peekToken.type {
        case .plus, .minus, .slash, .asterisk, .equal, .notEqual, .lessThan, .greaterThan:
            setNextToken()
            return try parseInfixExpression(with: left)
        case .leftParen:
            setNextToken()
            return try parseCallExpression(with: left)
        case .leftBracket:
            setNextToken()
            return try parseIndexExpression(with: left)
        default: return nil
        }
    }
    
    private func parseIdentifier() -> Identifier {
        return Identifier(token: currentToken)
    }
    
    private func parseFunctionLiteral() throws -> FunctionLiteral {
        let functionToken = currentToken
        
        // fn
        try setNextToken(expects: .leftParen)
        
        // (...)
        let parameters = try parseFunctionParameters()
        
        try setNextToken(expects: .leftBrace)
        
        let body = try parseBlockStatement()
        
        return FunctionLiteral(token: functionToken, parameters: parameters, body: body)
    }
    
    private func parseFunctionParameters() throws -> [Identifier] {
        var identifiers: [Identifier] = []

        // (
        guard !isPeekToken(equalTo: .rightParen) else {
            setNextToken()
            return identifiers
        }
        
        // x
        setNextToken()
        
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
    
    private func parseIntegerLiteral() -> IntegerLiteral {
        return IntegerLiteral(token: .makeNumber(number: currentToken.literal))
    }
    
    private func parseBoolean() -> Boolean {
        return Boolean(token: currentToken)
    }
    
    private func parseStringLiteral() -> StringLiteral {
        return StringLiteral(token: .makeString(string: currentToken.literal))
    }
    
    private func parseArrayLiteral() throws -> ArrayLiteral {
        let arrayToken = currentToken
        let elements = try parseExpressionList(until: .rightBracket)
        return ArrayLiteral(token: arrayToken, elements:elements)
    }
    
    private func parseDictionaryLiteral() throws -> HashLiteral {
        let dictionaryToken = currentToken
        var pairs: [HashLiteral.HashPair] = []
        while !isPeekToken(equalTo: .rightBrace) {
            // {
            setNextToken()
            
            // foo
            guard let key = try parseExpression() else {
                throw ParserError.expressionParsingFailed(token: currentToken)
            }
            
            // :
            try setNextToken(expects: .colon)
            
            // bar
            setNextToken()
            guard let value = try parseExpression() else {
                throw ParserError.expressionParsingFailed(token: currentToken)
            }
            pairs.append(HashLiteral.HashPair(key: key, value: value))
            
            if !isPeekToken(equalTo: .rightBrace) {
                // ,
                try setNextToken(expects: .comma)
            }
        }
        
        // }
        try setNextToken(expects: .rightBrace)
        
        return HashLiteral(token: dictionaryToken, pairs: pairs)
    }

    private func setNextToken() {
        currentToken = peekToken
        peekToken = lexer.nextToken()
    }
    
    private func setNextToken(expects tokenType: TokenType) throws {
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
