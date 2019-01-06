//
//  Evaluator.swift
//  AST
//
//  Created by Yusuke Kita on 12/04/18.
//

import Syntax
import Sema

public final class Evaluator {
    
    public init() {}
    
    public func evaluate(node: NodeType, with environment: EnvironmentType) throws -> ObjectType {
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
            guard let hashIndex = index as? AnyHashableObject else {
                throw EvaluatorError.notHashableIndex(index)
            }
            return try evaluate(indexExpression: hashIndex, left: left)
        case let identifier as Identifier:
            return try evaluate(identifier: identifier, with: environment)
        case let functionLiteral as FunctionLiteral:
            return Function(parameters: functionLiteral.parameters, body: functionLiteral.body, environment: environment)
        case let integerLiteral as IntegerLiteral:
            return (integerLiteral.value)
                .map(IntegerObject.init)
                .map(AnyHashableObject.init)
        case let boolean as Boolean:
            return boolean.value
                .map(BooleanObject.init)
                .map(AnyHashableObject.init)
        case let stringLiteral as StringLiteral:
            return stringLiteral.value
                .map(StringObject.init)
                .map(AnyHashableObject.init)
        case let arrayLiteral as ArrayLiteral:
            let elements = try arrayLiteral.elements.map { try evaluate(node: $0, with: environment) }
            return ArrayObject(elements: elements)
        case let hashLiteral as HashLiteral:
            let pairs = try hashLiteral.pairs.map { pair -> HashPair in
                let key = try evaluate(node: pair.key, with: environment)
                guard let hashKey = key as? AnyHashableObject else {
                    throw EvaluatorError.notHashableIndex(key)
                }
                return HashPair(
                    key: hashKey,
                    value: try evaluate(node: pair.value, with: environment)
                )
            }
            return HashObject(pairs: pairs)
        default:
            throw EvaluatorError.unknownNode(node)
        }
    }
    
    private func evaluate(program: Program, with environment: EnvironmentType) throws -> ObjectType {
        var object: ObjectType?
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
    
    private func evaluate(blockStatement: BlockStatement, with environment: EnvironmentType) throws -> ObjectType {
        var object: ObjectType?
        for statement in blockStatement.statements {
            object = (try evaluate(node: statement, with: environment)).unwrapHashableObject()
            
            if let returnValue = object as? ReturnValue {
                return returnValue
            }
        }
        
        guard let result = object else {
            throw EvaluatorError.noValidExpression(blockStatement.statements)
        }
        return result
    }
    
    private func evaluatePrefixExpression(operator: String, right: ObjectType) throws -> ObjectType {
        let object = right.unwrapHashableObject()
        
        switch `operator` {
        case Token(type: .bang).literal:
            return evaluate(bangPrefixOperatorExpression: object)
        case Token(type: .minus).literal:
            return try evaluate(minusPrefixOperatorExpression: object)
        default:
            throw EvaluatorError.unknownOperator(left: nil, operator: `operator`, right: object.kind)
        }
    }
    
    private func evaluate(bangPrefixOperatorExpression object: ObjectType) -> ObjectType {
        let value: Bool
        switch object {
        case let boolean as BooleanObject where boolean.value:
            value = false
        case let boolean as BooleanObject where !boolean.value:
            value = true
        case _ as Null:
            value = true
        default:
            value = false
        }
        return BooleanObject(value: value)
    }
    
    private func evaluate(minusPrefixOperatorExpression object: ObjectType) throws -> ObjectType {
        switch object {
        case let integer as IntegerObject:
            return (-integer.value)
                .map(IntegerObject.init)
                .map(AnyHashableObject.init)
        default:
            throw EvaluatorError.unknownOperator(left: nil, operator: Token(type: .minus).literal, right: object.kind)

        }
    }
    
    private func evaluateInfixExpression(operator: String, left: ObjectType, right: ObjectType) throws -> ObjectType {
        let leftObject = left.unwrapHashableObject()
        let rightObject = right.unwrapHashableObject()

        switch (leftObject, rightObject) {
        case (let leftInteger as IntegerObject, let rightInteger as IntegerObject):
            return try evaluateIntegerInfixExpression(left: leftInteger, operator: `operator`, right: rightInteger)
        case (let leftBoolean as BooleanObject, let rightBoolean as BooleanObject) where `operator` == Token(type: .equal).literal:
            return (leftBoolean.value == rightBoolean.value)
                .map(BooleanObject.init)
                .map(AnyHashableObject.init)
        case (let leftBoolean as BooleanObject, let rightBoolean as BooleanObject) where `operator` == Token(type: .notEqual).literal:
            return (leftBoolean.value != rightBoolean.value)
                .map(BooleanObject.init)
                .map(AnyHashableObject.init)
        case (let leftString as StringObject, let rightString as StringObject):
            return try evaluateStringInfixExpression(left: leftString, operator: `operator`, right: rightString)
        case _ where left.kind != right.kind:
            throw EvaluatorError.typeMissMatch(left: left.kind, operator: `operator`, right: right.kind)
        default:
            throw EvaluatorError.unknownOperator(left: left.kind, operator: `operator`, right: right.kind)
        }
    }
    
    private func evaluateIntegerInfixExpression(left: IntegerObject, operator: String, right: IntegerObject) throws -> ObjectType {
        let mapInt: (Int64) -> AnyHashableObject = {
            $0.map(IntegerObject.init).map(AnyHashableObject.init)
        }
        let mapBool: (Bool) -> AnyHashableObject = {
            $0.map(BooleanObject.init).map(AnyHashableObject.init)
        }
        switch `operator` {
        case Token(type: .plus).literal:
            return mapInt(left.value + right.value)
        case Token(type: .minus).literal:
            return mapInt(left.value - right.value)
        case Token(type: .asterisk).literal:
            return mapInt(left.value * right.value)
        case Token(type: .slash).literal:
            return mapInt(left.value / right.value)
        case Token(type: .lessThan).literal:
            return mapBool(left.value < right.value)
        case Token(type: .greaterThan).literal:
            return mapBool(left.value > right.value)
        case Token(type: .equal).literal:
            return mapBool(left.value == right.value)
        case Token(type: .notEqual).literal:
            return mapBool(left.value != right.value)
        default:
            throw EvaluatorError.unknownOperator(left: left.kind, operator: `operator`, right: right.kind)
        }
    }
    
    private func evaluateStringInfixExpression(left: StringObject, operator: String, right: StringObject) throws -> ObjectType {
        switch `operator` {
        case Token(type: .plus).literal:
            return (left.value + right.value)
                .map(StringObject.init)
                .map(AnyHashableObject.init)
        default:
            throw EvaluatorError.unknownOperator(left: left.kind, operator: `operator`, right: right.kind)
        }
    }
    
    private func evaluate(ifExpression: IfExpression, with environment: EnvironmentType) throws -> ObjectType {
        let condition = (try evaluate(node: ifExpression.condition, with: environment)).unwrapHashableObject()
        
        let isTruthy: (ObjectType) -> Bool = { object in
            switch object {
            case _ where object.kind == .null: return false
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
            return Null()
        }
    }
    
    private func evaluate(expressions: [ExpressionType], with environment: EnvironmentType) throws -> [ObjectType] {
        return try expressions.map { try evaluate(node: $0, with: environment) }
    }
    
    private func evaluate(indexExpression index: AnyHashableObject, left: ObjectType) throws -> ObjectType {
        switch (left, index.base) {
        case (let array as ArrayObject, let integer as IntegerObject):
            return evaluate(arrayIndex: integer, left: array)
        case (let hash as HashObject, _):
            return evaluate(hashIndex: index, left: hash)
        default:
            throw EvaluatorError.unsupportedIndexOperator(index: index.base, left: left)
        }
    }
    
    private func evaluate(arrayIndex index: IntegerObject, left: ArrayObject) -> ObjectType {
        guard index.value >= 0 && index.value < left.elements.count else {
            return Null()
        }
        
        return left.elements[Int(index.value)]
    }
    
    private func evaluate(hashIndex index: AnyHashableObject, left: HashObject) -> ObjectType {
        guard let pair = left.pairs.last(where: { $0.key.hashableBase == index.hashableBase }) else {
            return Null()
        }
        return pair.value
    }
    
    private func evaluate(identifier: Identifier, with environment: EnvironmentType) throws -> ObjectType {
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
    
    private func evaluateLen(argument: ObjectType) throws -> ObjectType {
        let int: Int64
        switch argument {
        case let string as StringObject:
            int = Int64(string.value.count)
        case let array as ArrayObject:
            int = Int64(array.elements.count)
        default:
            throw EvaluatorError.unsupportedArgument(for: .len, argument: argument)
        }
        return int
            .map(IntegerObject.init)
            .map(AnyHashableObject.init)
    }
    
    private func evaluateFirst(argument: ObjectType) throws -> ObjectType {
        switch argument {
        case let array as ArrayObject:
            return array.elements.isEmpty ? Null() : array.elements[0]
        default:
            throw EvaluatorError.unsupportedArgument(for: .first, argument: argument)
        }
    }
    
    private func evaluateLast(argument: ObjectType) throws -> ObjectType {
        switch argument {
        case let array as ArrayObject:
            return array.elements.isEmpty ? Null() : array.elements.last!
        default:
            throw EvaluatorError.unsupportedArgument(for: .last, argument: argument)
        }
    }
    
    private func evaluateRest(argument: ObjectType) throws -> ObjectType {
        switch argument {
        case let array as ArrayObject:
            return array.elements.isEmpty ? Null() : ArrayObject(elements: Array(array.elements.dropFirst()))
        default:
            throw EvaluatorError.unsupportedArgument(for: .rest, argument: argument)
        }
    }
    
    private func evaluatePush(arguments: [ObjectType]) throws -> ObjectType {
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
    
    private func apply(function object: ObjectType, arguments: [ObjectType]) throws -> ObjectType {
        switch object {
        case let function as Function:
            let environment = extendedEnvironment(from: function, arguments: arguments)
            let value = try evaluate(node: function.body, with: environment)
            return value.unwrapReturnValue()
        case let function as AnyBuiltinFunction<ObjectType>:
            guard arguments.count == 1 else {
                throw EvaluatorError.wrongNumberArguments(count: arguments.count)
            }
            let argument = arguments[0].unwrapHashableObject()
            return try function.builtinFunction(argument)
        case let function as AnyBuiltinFunction<[ObjectType]>:
            let arguments = arguments.map { $0.unwrapHashableObject() }
            return try function.builtinFunction(arguments)
        default:
            throw EvaluatorError.notFunction(object: object)
        }
    }
    
    private func extendedEnvironment(from function: Function, arguments: [ObjectType]) -> EnvironmentType {
        let environment = Environment(outer: function.environment)
        
        for (index, parameter) in function.parameters.enumerated() {
            environment.set(arguments[index], for: parameter)
        }
        return environment
    }
}

extension ObjectType {
    func unwrapReturnValue() -> ObjectType {
        guard let object = self as? ReturnValue else {
            return self
        }
        return object.value
    }
    
    func unwrapHashableObject() -> ObjectType {
        var object: ObjectType = self
        while let hashableObject = object as? AnyHashableObject {
            object = hashableObject.unwrap()
        }
        return object
    }
}
