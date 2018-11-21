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

typealias PrefixParseFunc = ((Token) -> Expression)
typealias InfixParseFunc = ((Expression) -> Expression)

public struct Parser {
    var lexer: Lexer
    var currentToken = Token(type: .unknown)
    var peekToken = Token(type: .unknown)
    var prefixParseFuncs: [TokenType: PrefixParseFunc] = [:]
    var infixParseFuncs: [TokenType: InfixParseFunc] = [:]

    public init(lexer: Lexer) {
        self.lexer = lexer
        
        register(prefixParseFunc: parseIdentifier, for: .identifier)
        register(prefixParseFunc: parseIntegerLiteral, for: .int)
        
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
        guard let value = parseExpression(from: currentToken) as? Identifier else {
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
        
        guard let value = parseExpression(from: currentToken) as? Identifier else {
            throw ParserError.expressionParsingFailed(token: peekToken)
        }
        
        while !isPeekToken(equalTo: .semicolon) {
            setNextToken()
        }
        
        return .init(token: returnToken, value: value)
    }
    
    mutating func parseExpressionStatement() -> ExpressionStatement? {
        let expressionToken = currentToken
        
        guard let expression = parseExpression(from: currentToken) else {
            return nil
        }
        
        if isPeekToken(equalTo: .semicolon) {
            setNextToken()
        }
        
        return .init(token: expressionToken, expression: expression)
    }
    
    func parseExpression(from token: Token, for precedence: Precedence = .lowest) -> Expression? {
        guard let prefix = prefixParseFuncs[currentToken.type] else {
            return nil
        }
        return prefix(token)
    }
    
    func parseIdentifier(from token: Token) -> Expression {
        return Identifier(token: token)
    }
    
    func parseIntegerLiteral(from token: Token) -> Expression {
        return Identifier(token: .makeNumber(number: token.literal))
    }
    
    mutating func register(prefixParseFunc: @escaping PrefixParseFunc, for tokenType: TokenType) {
        prefixParseFuncs[tokenType] = prefixParseFunc
    }
    
    mutating func register(infixParseFunc: @escaping InfixParseFunc, for tokenType: TokenType) {
        infixParseFuncs[tokenType] = infixParseFunc
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
