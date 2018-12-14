//
//  Evaluator.swift
//  AST
//
//  Created by Yusuke Kita on 12/04/18.
//

import Syntax
import Sema

public class Evaluator {
    
    private let `true` = Boolean(value: true)
    private let `false` = Boolean(value: false)
    private let null = Null()
    
    public init() {}
    
    public func evaluate(astNode: Node, with environment: EnvironmentType) throws -> Object {
        switch astNode {
        case let node as Program:
            return try evaluateProgram(node, with: environment)
        case let node as ExpressionStatement:
            return try evaluate(astNode: node.expression, with: environment)
        case let node as BlockStatement:
            return try evaluateBlockStatement(node, with: environment)
        case let node as ReturnStatement:
            let value = try evaluate(astNode: node.value, with: environment)
            return ReturnValue(value: value)
        case let node as LetStatement:
            let value = try evaluate(astNode: node.value, with: environment)
            environment.set(value, for: node.name)
            return value
        case let node as PrefixExpression:
            let right = try evaluate(astNode: node.right, with: environment)
            return try evaluatePrefixExpression(operator: node.operator, right: right)
        case let node as InfixExpression:
            let left = try evaluate(astNode: node.left, with: environment)
            let right = try evaluate(astNode: node.right, with: environment)
            return try evaluateInfixExpression(operator: node.operator, left: left, right: right)
        case let node as IfExpression:
            return try evaluateIfExpression(node, with: environment)
        case let node as CallExpression:
            let function = try evaluate(astNode: node.function, with: environment)
            let arguments = try evaluateExpressions(node.arguments, with: environment)
            return try applyFunction(function, arguments: arguments)
        case let node as Identifier:
            return try evaluateIdentifier(node, with: environment)
        case let node as FunctionLiteral:
            return Function(parameters: node.parameters, body: node.body, environment: environment)
        case let node as IntegerLiteral:
            return Integer(value: node.value)
        case let node as Sema.Boolean:
            return toBooleanObject(from: node.value)
        default:
            throw EvaluatorError.unknownNode(astNode)
        }
    }
    
    private func evaluateProgram(_ program: Program, with environment: EnvironmentType) throws -> Object {
        var object: Object?
        for statement in program.statements {
            object = try evaluate(astNode: statement, with: environment)
            
            if let returnValue = object as? ReturnValue {
                return returnValue.value
            }
        }
        
        guard let result = object else {
            throw EvaluatorError.noValidExpression(program.statements)
        }
        return result
    }
    
    private func evaluateBlockStatement(_ statement: BlockStatement, with environment: EnvironmentType) throws -> Object {
        var object: Object?
        for statement in statement.statements {
            object = try evaluate(astNode: statement, with: environment)
            
            if let returnValue = object as? ReturnValue {
                return returnValue
            }
        }
        
        guard let result = object else {
            throw EvaluatorError.noValidExpression(statement.statements)
        }
        return result
    }
    
    private func evaluatePrefixExpression(operator: String, right: Object) throws -> Object {
        switch `operator` {
        case Token(type: .bang).literal:
            return evaluateBangPrefixOperatorExpression(right)
        case Token(type: .minus).literal:
            return try evaluateMinusPrefixOperatorExpression(right)
        default:
            throw EvaluatorError.unknownOperator(left: nil, operator: `operator`, right: right.type)
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
    
    private func evaluateMinusPrefixOperatorExpression(_ object: Object) throws -> Object {
        guard object.type == .integer,
            let integer = object as? Integer else {
            throw EvaluatorError.unknownOperator(left: nil, operator: Token(type: .minus).literal, right: object.type)
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
    
    private func evaluateIfExpression(_ expression: IfExpression, with environment: EnvironmentType) throws -> Object {
        let condition = try evaluate(astNode: expression.condition, with: environment)
        
        let isTruthy: (Object) -> Bool = { object in
            switch object {
            case _ where object.type == .null: return false
            case let boolean as Boolean where boolean.value: return true
            case let boolean as Boolean where !boolean.value: return false
            default: return true
            }
        }
        
        if isTruthy(condition) {
            return try evaluate(astNode: expression.consequence, with: environment)
        } else if let alternative = expression.alternative {
            return try evaluate(astNode: alternative, with: environment)
        } else {
            return null
        }
    }
    
    private func evaluateExpressions(_ expressions: [Expression], with environment: EnvironmentType) throws -> [Object] {
        return try expressions.map { try evaluate(astNode: $0, with: environment) }
    }
    
    private func evaluateIdentifier(_ identifier: Identifier, with environment: EnvironmentType) throws -> Object {
        guard let value = environment.object(for: identifier) else {
            throw EvaluatorError.unknownNode(identifier)
        }
        
        return value
    }
    
    private func applyFunction(_ object: Object, arguments: [Object]) throws -> Object {
        guard let function = object as? Function else {
            throw EvaluatorError.notFunction(object: object)
        }
        
        let extendedEnvironment = extendedFunctionEnvironment(function, arguments: arguments)
        let value = try evaluate(astNode: function.body, with: extendedEnvironment)
        return unwrapReturnValue(value)
    }
    
    private func extendedFunctionEnvironment(_ function: Function, arguments: [Object]) -> EnvironmentType {
        let environment = Environment(outer: function.environment)
        
        for (index, parameter) in function.parameters.enumerated() {
            environment.set(arguments[index], for: parameter)
        }
        return environment
    }
    
    private func unwrapReturnValue(_ object: Object) -> Object {
        guard let returnValue = object as? ReturnValue else {
            return object
        }
        return returnValue.value
    }
    
    private func toBooleanObject(from bool: Bool) -> Boolean {
        if bool {
            return `true`
        } else {
            return `false`
        }
    }
}
