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
    public let token: Token
    public let name: Identifier
    
    public init(token: Token, name: Identifier) {
        self.token = token
        self.name = name
    }
}

extension LetStatement: Statement {
    public func statementNode() {}

    public var tokenLiteral: String {
        return token.literal
    }
}

public struct Identifier {
    public let token: Token
    public var value: String {
        return token.literal
    }
    
    public init(token: Token) {
        self.token = token
    }
}

extension Identifier: Expression {
    public func expressionNode() {}
    
    public var tokenLiteral: String {
        return token.literal
    }
}

public struct ReturnStatement {
    public let token: Token
    
    public init(token: Token) {
        self.token = token
    }
}

extension ReturnStatement: Statement {
    public func statementNode() {}
    
    public var tokenLiteral: String {
        return token.literal
    }
}
