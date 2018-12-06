//
//  Evaluator.swift
//  AST
//
//  Created by Yusuke Kita on 12/04/18.
//

import Syntax
import Sema

public struct Evaluator {
    
    private let `true` = Boolean(value: true)
    private let `false` = Boolean(value: false)
    private let null = Null()
    
    public init() {}
    
    public func evaluate(astNode: Node) throws -> Object {
        switch astNode {
        case let node as Program:
            return try evaluateStatements(node.statements)
        case let node as ExpressionStatement:
            return try evaluate(astNode: node.expression)
        case let node as PrefixExpression:
            let right = try evaluate(astNode: node.right)
            return evaluatePrefixExpression(operator: node.operator, right: right)
        case let node as InfixExpression:
            let left = try evaluate(astNode: node.left)
            let right = try evaluate(astNode: node.right)
            return try evaluateInfixExpression(operator: node.operator, left: left, right: right)
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
    
    private func evaluatePrefixExpression(operator: String, right: Object) -> Object {
        switch `operator` {
        case Token(type: .bang).literal:
            return evaluateBangPrefixOperatorExpression(right)
        case Token(type: .minus).literal:
            return evaluateMinusPrefixOperatorExpression(right)
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
    
    private func evaluateInfixExpression(operator: String, left: Object, right: Object) throws -> Object {
        switch (left, right) {
        case (let leftInteger as Integer, let rightInteger as Integer):
            return try evaluateIntegerInfixExpression(left: leftInteger, operator: `operator`, right: rightInteger)
        case (let leftBoolean as Boolean, let rightBoolean as Boolean) where `operator` == Token(type: .equal).literal:
            return toBooleanObject(from: leftBoolean.value == rightBoolean.value)
        case (let leftBoolean as Boolean, let rightBoolean as Boolean) where `operator` == Token(type: .notEqual).literal:
            return toBooleanObject(from: leftBoolean.value != rightBoolean.value)
        case _ where left.type != right.type:
            throw EvaluatorError.typeMissMatch(left: left.type, operator: `operator`, right: right.type)
        default:
            throw EvaluatorError.unknownOperator(left: left.type, operator: `operator`, right: right.type)
        }
    }
    
    private func evaluateIntegerInfixExpression(left: Integer, operator: String, right: Integer) throws -> Object {
        switch `operator` {
        case Token(type: .plus).literal:
            return Integer(value: left.value + right.value)
        case Token(type: .minus).literal:
            return Integer(value: left.value - right.value)
        case Token(type: .asterisk).literal:
            return Integer(value: left.value * right.value)
        case Token(type: .slash).literal:
            return Integer(value: left.value / right.value)
        case Token(type: .lessThan).literal:
            return toBooleanObject(from: left.value < right.value)
        case Token(type: .greaterThan).literal:
            return toBooleanObject(from: left.value > right.value)
        case Token(type: .equal).literal:
            return toBooleanObject(from: left.value == right.value)
        case Token(type: .notEqual).literal:
            return toBooleanObject(from: left.value != right.value)
        default:
            throw EvaluatorError.unknownOperator(left: left.type, operator: `operator`, right: right.type)
        }
    }
    
    private func toBooleanObject(from bool: Bool) -> Boolean {
        if bool {
            return `true`
        } else {
            return `false`
        }
    }
}
