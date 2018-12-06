//
//  Evaluator.swift
//  AST
//
//  Created by Yusuke Kita on 12/04/18.
//

import Syntax
import Sema

public struct Evaluator {
    
    let `true` = Boolean(value: true)
    let `false` = Boolean(value: false)
    let null = Null()
    
    public init() {}
    
    public func evaluate(astNode: Node) throws -> Object {
        switch astNode {
        case let node as Program:
            return try evaluateStatements(node.statements)
        case let node as ExpressionStatement:
            return try evaluate(astNode: node.expression)
        case let node as PrefixExpression:
            let right = try evaluate(astNode: node.right)
            return evaluatePrefixExpression(operator: node.operator, object: right)
        case let node as IntegerLiteral:
            return Integer(value: node.value)
        case let node as Sema.Boolean:
            return toBooleanObject(from: node.value)
        default:
            throw EvaluatorError.unknownNode(astNode)
        }
    }
    
    private func evaluateStatements(_ statements: [Statement]) throws -> Object {
        guard let object = try statements.map({ try evaluate(astNode: $0) }).last else {
            throw EvaluatorError.noValidExpression(statements)
        }
        return object
    }
    
    private func evaluatePrefixExpression(operator: String, object: Object) -> Object {
        switch `operator` {
        case String(TokenSymbol.bang.rawValue):
            return evaluateBangPrefixOperatorExpression(object)
        case String(TokenSymbol.minus.rawValue):
            return evaluateMinusPrefixOperatorExpression(object)
        default:
            return null
        }
    }
    
    private func evaluateBangPrefixOperatorExpression(_ object: Object) -> Object {
        switch object {
        case let boolean as Boolean where boolean.value:
            return `false`
        case let boolean as Boolean where !boolean.value:
            return `true`
        case _ as Null:
            return `true`
        default:
            return `false`
        }
    }
    
    private func evaluateMinusPrefixOperatorExpression(_ object: Object) -> Object {
        guard object.type == .integer,
            let integer = object as? Integer else {
            return null
        }
        
        return Integer(value: -integer.value)
    }
    
    private func toBooleanObject(from bool: Bool) -> Boolean {
        if bool {
            return `true`
        } else {
            return `false`
        }
    }
}
