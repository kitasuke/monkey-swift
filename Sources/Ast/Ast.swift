//
//  Ast.swift
//  Ast
//
//  Created by Yusuke Kita on 11/15/18.
//

import Token

public protocol Node {
    var tokenLiteral: String { get }
}

public protocol Statement: Node {
    func statementNode()
}

public protocol Expression: Node {
    func expressionNode()
}

public struct Program {
    public let statements: [Statement]
    
    public init(statements: [Statement]) {
        self.statements = statements
    }
}

extension Program: Node {
    public var tokenLiteral: String {
        if statements.isEmpty {
            return ""
        } else {
            return statements[0].tokenLiteral
        }
    }
}

public struct LetStatement {
    public let tokenType: TokenType
    public let name: Identifier
    
    public init(tokenType: TokenType, name: Identifier) {
        self.tokenType = tokenType
        self.name = name
    }
}

extension LetStatement: Statement {
    public func statementNode() {}

    public var tokenLiteral: String {
        return tokenType.literal
    }
}

public struct Identifier {
    public let tokenType: TokenType
    public var value: String {
        return tokenType.literal
    }
    
    public init(tokenType: TokenType) {
        self.tokenType = tokenType
    }
}

extension Identifier: Expression {
    public func expressionNode() {}
    
    public var tokenLiteral: String {
        return tokenType.literal
    }
}

public struct ReturnStatement {
    public let tokenType: TokenType
    
    public init(tokenType: TokenType) {
        self.tokenType = tokenType
    }
}

extension ReturnStatement: Statement {
    public func statementNode() {}
    
    public var tokenLiteral: String {
        return tokenType.literal
    }
}
