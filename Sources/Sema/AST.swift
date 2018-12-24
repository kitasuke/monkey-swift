//
//  Ast.swift
//  Sema
//
//  Created by Yusuke Kita on 11/15/18.
//

import Syntax

public protocol NodeType: CustomStringConvertible {
    var tokenLiteral: String { get }
    var token: Token { get }
}

extension NodeType {
    public var tokenLiteral: String {
        return token.literal
    }
}

public protocol StatementType: NodeType {}
public protocol ExpressionType: StatementType {}

public struct Program: NodeType {
    public let token: Token
    public let statements: [StatementType]
    
    public init(statements: [StatementType]) {
        self.token = .init(type: .unknown)
        self.statements = statements
    }
}

extension Program {
    public var description: String {
        return statements.reduce("") { result, statement in
            result + statement.description
        }
    }
}

public struct BlockStatement {
    public let token: Token
    public let statements: [StatementType]
    
    public init(token: Token, statements: [StatementType]) {
        self.token = token
        self.statements = statements
    }
}

extension BlockStatement: StatementType {
    public var description: String {
        return statements.reduce("") { result, statement in
            result + statement.description
        }
    }
}

public struct LetStatement {
    public let token: Token
    public let name: Identifier
    public let value: ExpressionType
    
    public init(token: Token, name: Identifier, value: ExpressionType) {
        self.token = token
        self.name = name
        self.value = value
    }
}

extension LetStatement: StatementType {
    public var description: String {
        return "\(tokenLiteral) \(name.value) = \(value.description);"
    }
}

public struct ReturnStatement {
    public let token: Token
    public let value: ExpressionType
    
    public init(token: Token, value: ExpressionType) {
        self.token = token
        self.value = value
    }
}

extension ReturnStatement: StatementType {
    public var description: String {
        return "\(tokenLiteral) \(value.description);"
    }
}

public struct ExpressionStatement {
    public let token: Token
    public let expression: ExpressionType
    
    public init(token: Token, expression: ExpressionType) {
        self.token = token
        self.expression = expression
    }
}

extension ExpressionStatement: StatementType {
    public var description: String {
        return expression.description
    }
}

public struct PrefixExpression {
    public let token: Token
    public let `operator`: String // TODO enum
    public let right: ExpressionType
    
    public init(token: Token, operator: String, right: ExpressionType) {
        self.token = token
        self.operator = `operator`
        self.right = right
    }
}

extension PrefixExpression: ExpressionType {
    public var description: String {
        return "(\(`operator`)\(right.description))"
    }
}

public struct InfixExpression {
    public let token: Token
    public let left: ExpressionType
    public let `operator`: String
    public let right: ExpressionType
    
    public init(token: Token, left: ExpressionType, right: ExpressionType) {
        self.token = token
        self.left = left
        self.operator = token.literal
        self.right = right
    }
}

extension InfixExpression: ExpressionType {
    public var description: String {
        return "(\(left.description) \(`operator`) \(right.description))"
    }
}

public struct IfExpression {
    public let token: Token
    public let condition: ExpressionType
    public let consequence: BlockStatement
    public let alternative: BlockStatement?
    
    public init(token: Token, condition: ExpressionType, consequence: BlockStatement, alternative: BlockStatement?) {
        self.token = token
        self.condition = condition
        self.consequence = consequence
        self.alternative = alternative
    }
}

extension IfExpression: ExpressionType {
    public var description: String {
        var string = "if \(condition.description) \(consequence.description)"
        alternative.flatMap { string = string + "else \($0.description)" }
        return string
    }
}

public struct CallExpression {
    public let token: Token
    public let function: ExpressionType
    public let arguments: [ExpressionType]
    
    public init(token: Token, function: ExpressionType, arguments: [ExpressionType]) {
        self.token = token
        self.function = function
        self.arguments = arguments
    }
}

extension CallExpression: ExpressionType {
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

extension Identifier: ExpressionType {
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

extension FunctionLiteral: ExpressionType {
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

extension IntegerLiteral: ExpressionType {
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

extension Boolean: ExpressionType {
    public var description: String {
        return token.literal
    }
}

public struct StringLiteral {
    public let token: Token
    public let value: String
    
    public init(token: Token) {
        self.token = token
        self.value = token.literal
    }
}

extension StringLiteral: ExpressionType {
    public var description: String {
        return tokenLiteral
    }
}

public struct ArrayLiteral {
    public let token: Token
    public let elements: [ExpressionType]
    
    public init(token: Token, elements: [ExpressionType]) {
        self.token = token
        self.elements = elements
    }
}

extension ArrayLiteral: ExpressionType {
    public var description: String {
        return "[\(elements.map { $0.description }.joined(separator: ", "))]"
    }
}

public struct IndexExpression {
    public let token: Token
    public let left: ExpressionType
    public let index: ExpressionType
    
    public init(token: Token, left: ExpressionType, index: ExpressionType) {
        self.token = token
        self.left = left
        self.index = index
    }
}

extension IndexExpression: ExpressionType {
    public var description: String {
        return "(\(left.description)[\(index.description)])"
    }
}
