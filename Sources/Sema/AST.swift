//
//  Ast.swift
//  Sema
//
//  Created by Yusuke Kita on 11/15/18.
//

import Syntax

public protocol Node: CustomStringConvertible {
    var tokenLiteral: String { get }
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

public struct BlockStatement {
    public let token: Token
    public let statements: [Statement]
    
    public init(token: Token, statements: [Statement]) {
        self.token = token
        self.statements = statements
    }
}

extension BlockStatement: Statement {
    public var tokenLiteral: String {
        return token.literal
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
    public let value: Expression
    
    public init(token: Token, name: Identifier, value: Expression) {
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

public struct ReturnStatement {
    public let token: Token
    public let value: Expression
    
    public init(token: Token, value: Expression) {
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

public struct PrefixExpression {
    public let token: Token
    public let `operator`: String // TODO enum
    public let right: Expression
    
    public init(token: Token, operator: String, right: Expression) {
        self.token = token
        self.operator = `operator`
        self.right = right
    }
}

extension PrefixExpression: Expression {
    public var tokenLiteral: String {
        return token.literal
    }
    
    public var description: String {
        return "(\(`operator`)\(right.description))"
    }
}

public struct InfixExpression {
    public let token: Token
    public let left: Expression
    public let `operator`: String
    public let right: Expression
    
    public init(token: Token, left: Expression, right: Expression) {
        self.token = token
        self.left = left
        self.operator = token.literal
        self.right = right
    }
}

extension InfixExpression: Expression {
    public var tokenLiteral: String {
        return token.literal
    }
    
    public var description: String {
        return "(\(left.description) \(`operator`) \(right.description))"
    }
}

public struct IfExpression {
    public let token: Token
    public let condition: Expression
    public let consequence: BlockStatement
    public let alternative: BlockStatement?
    
    public init(token: Token, condition: Expression, consequence: BlockStatement, alternative: BlockStatement?) {
        self.token = token
        self.condition = condition
        self.consequence = consequence
        self.alternative = alternative
    }
}

extension IfExpression: Expression {
    public var tokenLiteral: String {
        return token.literal
    }
    
    public var description: String {
        var string = "if \(condition.description) \(consequence.description)"
        alternative.flatMap { string = string + "else \($0.description)" }
        return string
    }
}

public struct CallExpression {
    public let token: Token
    public let function: Expression
    public let arguments: [Expression]
    
    public init(token: Token, function: Expression, arguments: [Expression]) {
        self.token = token
        self.function = function
        self.arguments = arguments
    }
}

extension CallExpression: Expression {
    public var tokenLiteral: String {
        return token.literal
    }
    
    public var description: String {
        let arguments = self.arguments.map { $0.description }.joined(separator: ", ")
        return "\(function.description)(\(arguments))"
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

extension Identifier: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(token)
        hasher.combine(value)
    }
}

public struct FunctionLiteral {
    public let token: Token
    public let parameters: [Identifier]
    public let body: BlockStatement
    
    public init(token: Token, parameters: [Identifier], body: BlockStatement) {
        self.token = token
        self.parameters = parameters
        self.body = body
    }
}

extension FunctionLiteral: Expression {
    public var tokenLiteral: String {
        return token.literal
    }
    
    public var description: String {
        let params = parameters.map { $0.description }.joined(separator: ", ")
        return "\(tokenLiteral)(\(params))\(body.description)"
    }
}

public struct IntegerLiteral {
    public let token: Token
    public let value: Int64
    
    public init(token: Token) {
        self.token = token
        self.value = Int64(token.literal) ?? 0
    }
}

extension IntegerLiteral: Expression {
    public var tokenLiteral: String {
        return token.literal
    }
    
    public var description: String {
        return token.literal
    }
}

public struct Boolean {
    public let token: Token
    public let value: Bool
    
    public init(token: Token) {
        self.token = token
        self.value = Bool(token.literal) ?? false
    }
}

extension Boolean: Expression {
    public var tokenLiteral: String {
        return token.literal
    }
    
    public var description: String {
        return token.literal
    }
}

public struct StringLigeral {
    public let token: Token
    public let value: String
    
    public init(token: Token) {
        self.token = token
        self.value = token.literal
    }
}

extension StringLigeral: Expression {
    public var tokenLiteral: String {
        return token.literal
    }
    
    public var description: String {
        return tokenLiteral
    }
}
