//
//  Evaluator.swift
//  AST
//
//  Created by Yusuke Kita on 12/04/18.
//

import Syntax
import Sema

public final class Evaluator {
    
    private let `true` = BooleanObject(value: true)
    private let `false` = BooleanObject(value: false)
    private let null = Null()
    
    public init() {}
    
    public func evaluate(node: NodeType, with environment: EnvironmentType) throws -> Object {
        switch node {
        case let program as Program:
            return try evaluate(program: program, with: environment)
        case let expressionStatement as ExpressionStatement:
            return try evaluate(node: expressionStatement.expression, with: environment)
        case let blockStatement as BlockStatement:
            return try evaluate(blockStatement: blockStatement, with: environment)
        case let returnStatement as ReturnStatement:
            let value = try evaluate(node: returnStatement.value, with: environment)
            return ReturnValue(value: value)
        case let letStatement as LetStatement:
            let value = try evaluate(node: letStatement.value, with: environment)
            environment.set(value, for: letStatement.name)
            return value
        case let prefixExpression as PrefixExpression:
            let right = try evaluate(node: prefixExpression.right, with: environment)
            return try evaluatePrefixExpression(operator: prefixExpression.operator, right: right)
        case let infixExpression as InfixExpression:
            let left = try evaluate(node: infixExpression.left, with: environment)
            let right = try evaluate(node: infixExpression.right, with: environment)
            return try evaluateInfixExpression(operator: infixExpression.operator, left: left, right: right)
        case let ifExpression as IfExpression:
            return try evaluate(ifExpression: ifExpression, with: environment)
        case let callExpression as CallExpression:
            let function = try evaluate(node: callExpression.function, with: environment)
            let arguments = try evaluate(expressions: callExpression.arguments, with: environment)
            return try apply(function: function, arguments: arguments)
        case let indexExpression as IndexExpression:
            let left = try evaluate(node: indexExpression.left, with: environment)
            let index = try evaluate(node: indexExpression.index, with: environment)
            return try evaluate(indexExpression: index, left: left)
        case let identifier as Identifier:
            return try evaluate(identifier: identifier, with: environment)
        case let functionLiteral as FunctionLiteral:
            return Function(parameters: functionLiteral.parameters, body: functionLiteral.body, environment: environment)
        case let integerLiteral as IntegerLiteral:
            return IntegerObject(value: integerLiteral.value)
        case let boolean as Sema.Boolean:
            return toBooleanObject(from: boolean.value)
        case let stringLiteral as StringLiteral:
            return StringObject(value: stringLiteral.value)
        case let arrayLiteral as ArrayLiteral:
            let elements = try arrayLiteral.elements.map { try evaluate(node: $0, with: environment) }
            return ArrayObject(elements: elements)
        default:
            throw EvaluatorError.unknownNode(node)
        }
    }
    
    private func evaluate(program: Program, with environment: EnvironmentType) throws -> Object {
        var object: Object?
        for statement in program.statements {
            object = try evaluate(node: statement, with: environment)
            
            if let returnValue = object as? ReturnValue {
                return returnValue.value
            }
        }
        
        guard let result = object else {
            throw EvaluatorError.noValidExpression(program.statements)
        }
        return result
    }
    
    private func evaluate(blockStatement: BlockStatement, with environment: EnvironmentType) throws -> Object {
        var object: Object?
        for statement in blockStatement.statements {
            object = try evaluate(node: statement, with: environment)
            
            if let returnValue = object as? ReturnValue {
                return returnValue
            }
        }
        
        guard let result = object else {
            throw EvaluatorError.noValidExpression(blockStatement.statements)
        }
        return result
    }
    
    private func evaluatePrefixExpression(operator: String, right: Object) throws -> Object {
        switch `operator` {
        case Token(type: .bang).literal:
            return evaluate(bangPrefixOperatorExpression: right)
        case Token(type: .minus).literal:
            return try evaluate(minusPrefixOperatorExpression: right)
        default:
            throw EvaluatorError.unknownOperator(left: nil, operator: `operator`, right: right.type)
        }
    }
    
    private func evaluate(bangPrefixOperatorExpression object: Object) -> Object {
        switch object {
        case let boolean as BooleanObject where boolean.value:
            return `false`
        case let boolean as BooleanObject where !boolean.value:
            return `true`
        case _ as Null:
            return `true`
        default:
            return `false`
        }
    }
    
    private func evaluate(minusPrefixOperatorExpression object: Object) throws -> Object {
        guard object.type == .integer,
            let integer = object as? IntegerObject else {
            throw EvaluatorError.unknownOperator(left: nil, operator: Token(type: .minus).literal, right: object.type)
        }
        
        return IntegerObject(value: -integer.value)
    }
    
    private func evaluateInfixExpression(operator: String, left: Object, right: Object) throws -> Object {
        switch (left, right) {
        case (let leftInteger as IntegerObject, let rightInteger as IntegerObject):
            return try evaluateIntegerInfixExpression(left: leftInteger, operator: `operator`, right: rightInteger)
        case (let leftBoolean as BooleanObject, let rightBoolean as BooleanObject) where `operator` == Token(type: .equal).literal:
            return toBooleanObject(from: leftBoolean.value == rightBoolean.value)
        case (let leftBoolean as BooleanObject, let rightBoolean as BooleanObject) where `operator` == Token(type: .notEqual).literal:
            return toBooleanObject(from: leftBoolean.value != rightBoolean.value)
        case (let leftString as StringObject, let rightString as StringObject):
            return try evaluateStringInfixExpression(left: leftString, operator: `operator`, right: rightString)
        case _ where left.type != right.type:
            throw EvaluatorError.typeMissMatch(left: left.type, operator: `operator`, right: right.type)
        default:
            throw EvaluatorError.unknownOperator(left: left.type, operator: `operator`, right: right.type)
        }
    }
    
    private func evaluateIntegerInfixExpression(left: IntegerObject, operator: String, right: IntegerObject) throws -> Object {
        switch `operator` {
        case Token(type: .plus).literal:
            return IntegerObject(value: left.value + right.value)
        case Token(type: .minus).literal:
            return IntegerObject(value: left.value - right.value)
        case Token(type: .asterisk).literal:
            return IntegerObject(value: left.value * right.value)
        case Token(type: .slash).literal:
            return IntegerObject(value: left.value / right.value)
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
    
    private func evaluateStringInfixExpression(left: StringObject, operator: String, right: StringObject) throws -> Object {
        switch `operator` {
        case Token(type: .plus).literal:
            return StringObject(value: left.value + right.value)
        default:
            throw EvaluatorError.unknownOperator(left: left.type, operator: `operator`, right: right.type)
        }
    }
    
    private func evaluate(ifExpression: IfExpression, with environment: EnvironmentType) throws -> Object {
        let condition = try evaluate(node: ifExpression.condition, with: environment)
        
        let isTruthy: (Object) -> Bool = { object in
            switch object {
            case _ where object.type == .null: return false
            case let boolean as BooleanObject where boolean.value: return true
            case let boolean as BooleanObject where !boolean.value: return false
            default: return true
            }
        }
        
        if isTruthy(condition) {
            return try evaluate(node: ifExpression.consequence, with: environment)
        } else if let alternative = ifExpression.alternative {
            return try evaluate(node: alternative, with: environment)
        } else {
            return null
        }
    }
    
    private func evaluate(expressions: [ExpressionType], with environment: EnvironmentType) throws -> [Object] {
        return try expressions.map { try evaluate(node: $0, with: environment) }
    }
    
    private func evaluate(indexExpression index: Object, left: Object) throws -> Object {
        switch (left, index) {
        case (let array as ArrayObject, let integer as IntegerObject):
            return evaluate(arrayIndexExpression: integer, left: array)
        default:
            throw EvaluatorError.unsupportedIndexOperator(index: index, left: left)
        }
    }
    
    private func evaluate(arrayIndexExpression index: IntegerObject, left: ArrayObject) -> Object {
        guard index.value >= 0 && index.value < left.elements.count else {
            return null
        }
        
        return left.elements[Int(index.value)]
    }
    
    private func evaluate(identifier: Identifier, with environment: EnvironmentType) throws -> Object {
        if let value = environment.object(for: identifier) {
            return value
        }
        
        switch BuiltinIdentifier(rawValue: identifier.value) {
        case .len?:
            let builtinFunction = SingleArgumentBuiltinFunction(builtinFunction: evaluateLen(argument:))
            return AnyBuiltinFunction(builtinFunction)
        case .first?:
            let builtinFunction = SingleArgumentBuiltinFunction(builtinFunction: evaluateFirst(argument:))
            return AnyBuiltinFunction(builtinFunction)
        case .last?:
            let builtinFunction = SingleArgumentBuiltinFunction(builtinFunction: evaluateLast(argument:))
            return AnyBuiltinFunction(builtinFunction)
        case .rest?:
            let builtinFunction = SingleArgumentBuiltinFunction(builtinFunction: evaluateRest(argument:))
            return AnyBuiltinFunction(builtinFunction)
        case .push?:
            let builtinFunction = MultipleArgumentsBuiltinFunction(builtinFunction: evaluatePush(arguments:))
            return AnyBuiltinFunction(builtinFunction)
        default:
            throw EvaluatorError.unknownNode(identifier)
        }
    }
    
    private func evaluateLen(argument: Object) throws -> IntegerObject {
        switch argument {
        case let string as StringObject:
            return IntegerObject(value: Int64(string.value.count))
        case let array as ArrayObject:
            return IntegerObject(value: Int64(array.elements.count))
        default:
            throw EvaluatorError.unsupportedArgument(for: .len, argument: argument)
        }
    }
    
    private func evaluateFirst(argument: Object) throws -> Object {
        switch argument {
        case let array as ArrayObject:
            return array.elements.isEmpty ? null : array.elements[0]
        default:
            throw EvaluatorError.unsupportedArgument(for: .first, argument: argument)
        }
    }
    
    private func evaluateLast(argument: Object) throws -> Object {
        switch argument {
        case let array as ArrayObject:
            return array.elements.isEmpty ? null : array.elements.last!
        default:
            throw EvaluatorError.unsupportedArgument(for: .last, argument: argument)
        }
    }
    
    private func evaluateRest(argument: Object) throws -> Object {
        switch argument {
        case let array as ArrayObject:
            return array.elements.isEmpty ? null : ArrayObject(elements: Array(array.elements.dropFirst()))
        default:
            throw EvaluatorError.unsupportedArgument(for: .rest, argument: argument)
        }
    }
    
    private func evaluatePush(arguments: [Object]) throws -> Object {
        guard arguments.count == 2 else {
            throw EvaluatorError.wrongNumberArguments(count: arguments.count)
        }
        
        switch arguments[0] {
        case let array as ArrayObject:
            return ArrayObject(elements: array.elements + [arguments[1]])
        default:
            throw EvaluatorError.unsupportedArgument(for: .push, argument: arguments[0])
        }
    }
    
    private func apply(function object: Object, arguments: [Object]) throws -> Object {
        switch object {
        case let function as Function:
            let environment = extendedEnvironment(from: function, arguments: arguments)
            let value = try evaluate(node: function.body, with: environment)
            return unwrap(returnValue: value)
        case let function as AnyBuiltinFunction<Object>:
            guard arguments.count == 1 else {
                throw EvaluatorError.wrongNumberArguments(count: arguments.count)
            }
            return try function.builtinFunction(arguments[0])
        case let function as AnyBuiltinFunction<[Object]>:
            return try function.builtinFunction(arguments)
        default:
            throw EvaluatorError.notFunction(object: object)
        }
    }
    
    private func extendedEnvironment(from function: Function, arguments: [Object]) -> EnvironmentType {
        let environment = Environment(outer: function.environment)
        
        for (index, parameter) in function.parameters.enumerated() {
            environment.set(arguments[index], for: parameter)
        }
        return environment
    }
    
    private func unwrap(returnValue object: Object) -> Object {
        guard let returnValue = object as? ReturnValue else {
            return object
        }
        return returnValue.value
    }
    
    private func toBooleanObject(from bool: Bool) -> BooleanObject {
        if bool {
            return `true`
        } else {
            return `false`
        }
    }
}
