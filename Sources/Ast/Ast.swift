//
//  Ast.swift
//  Ast
//
//  Created by Yusuke Kita on 11/15/18.
//

import Token

public protocol Node {
    var tokenLiteral: String { get }
    var description: String { get }
}

public protocol Statement: Node {}

public protocol Expression: Node {}

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
    
    public var description: String {
        return statements.reduce("") { result, statement in
            result + statement.description
        }
    }
}

public struct LetStatement {
    public let token: Token
    public let name: Identifier
    public let value: Identifier
    
    public init(token: Token, name: Identifier, value: Identifier) {
        self.token = token
        self.name = name
        self.value = value
    }
}

extension LetStatement: Statement {
    public var tokenLiteral: String {
        return token.literal
    }
    
    public var description: String {
        return "\(tokenLiteral) \(name.value) \(TokenSymbol.equal.rawValue) \(value.description)\(TokenSymbol.semicolon.rawValue)"
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
    public var tokenLiteral: String {
        return token.literal
    }
    
    public var description: String {
        return value
    }
}

public struct ReturnStatement {
    public let token: Token
    public let value: Identifier
    
    public init(token: Token, value: Identifier) {
        self.token = token
        self.value = value
    }
}

extension ReturnStatement: Statement {
    public var tokenLiteral: String {
        return token.literal
    }
    
    public var description: String {
        return "\(tokenLiteral) \(value.description)\(TokenSymbol.semicolon.rawValue)"
    }
}

public struct ExpressionStatement {
    public let token: Token
    public let expression: Expression
    
    public init(token: Token, expression: Expression) {
        self.token = token
        self.expression = expression
    }
}

extension ExpressionStatement: Statement {
    public var tokenLiteral: String {
        return token.literal
    }
    
    public var description: String {
        return expression.description
    }
}
