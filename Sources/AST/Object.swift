//
//  Object.swift
//  AST
//
//  Created by Yusuke Kita on 12/04/18.
//

import Sema

public protocol ObjectType: CustomStringConvertible {
    var kind: ObjectKind { get }
}

public struct IntegerObject {
    public let value: Int64
    
    public init(value: Int64) {
        self.value = value
    }
}

extension IntegerObject: ObjectType {
    public var kind: ObjectKind {
        return .integer
    }
    
    public var description: String {
        return "\(value)"
    }
}

extension IntegerObject: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(kind)
        hasher.combine(value)
    }
}

public struct BooleanObject {
    public let value: Bool
    
    public init(value: Bool) {
        self.value = value
    }
}

extension BooleanObject: ObjectType {
    public var kind: ObjectKind {
        return .boolean
    }
    
    public var description: String {
        return "\(value)"
    }
}

extension BooleanObject: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(kind)
        hasher.combine(value)
    }
}

public struct StringObject {
    public let value: String
    
    public init(value: String) {
        self.value = value
    }
}

extension StringObject: ObjectType {
    public var kind: ObjectKind {
        return .string
    }
    
    public var description: String {
        return "\(value)"
    }
}

extension StringObject: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(kind)
        hasher.combine(value)
    }
}

public struct Null {}

extension Null: ObjectType {
    public var kind: ObjectKind {
        return .null
    }
    
    public var description: String {
        return kind.rawValue
    }
}

public struct ReturnValue {
    public let value: ObjectType
    
    public init(value: ObjectType) {
        self.value = value
    }
}

extension ReturnValue: ObjectType {
    public var kind: ObjectKind {
        return .return
    }
    
    public var description: String {
        return value.description
    }
}

public struct Function {
    public let parameters: [Identifier]
    public let body: BlockStatement
    public let environment: EnvironmentType
    
    public init(parameters: [Identifier], body: BlockStatement, environment: EnvironmentType) {
        self.parameters = parameters
        self.body = body
        self.environment = environment
    }
}

extension Function: ObjectType {
    public var kind: ObjectKind {
        return .function
    }
    
    public var description: String {
        let params = parameters.map { $0.description }.joined(separator: ", ")
        return "fn(\(params)) {\n\(body.description)\n}"
    }
}

public protocol BuiltinFunctionType {
    associatedtype Argument
    typealias BuiltinFunction = (Argument) throws -> ObjectType
    
    var builtinFunction: BuiltinFunction { get }
}

public struct SingleArgumentBuiltinFunction: BuiltinFunctionType {
    
    public typealias Argument = ObjectType
    
    public let builtinFunction: BuiltinFunction
    
    public init(builtinFunction: @escaping BuiltinFunction) {
        self.builtinFunction = builtinFunction
    }
}

public struct MultipleArgumentsBuiltinFunction: BuiltinFunctionType {
    public typealias Argument = [ObjectType]
    
    public let builtinFunction: BuiltinFunction
    
    public init(builtinFunction: @escaping BuiltinFunction) {
        self.builtinFunction = builtinFunction
    }
}

public struct AnyBuiltinFunction<T>: BuiltinFunctionType {
    public typealias Argument = T
    
    private let _builtinFunction: () -> BuiltinFunction
    
    init<U: BuiltinFunctionType>(_ builtinType: U) where U.Argument == T {
        _builtinFunction = { builtinType.builtinFunction }
    }
    
    public var builtinFunction: BuiltinFunction {
        return _builtinFunction()
    }
}

extension AnyBuiltinFunction: ObjectType {
    public var kind: ObjectKind {
        return .builtin
    }
    
    public var description: String {
        return "builtin function"
    }
}

public struct ArrayObject {
    public let elements: [ObjectType]
    
    public init(elements: [ObjectType]) {
        self.elements = elements
    }
}

extension ArrayObject: ObjectType {
    public var kind: ObjectKind {
        return .array
    }
    
    public var description: String {
        let elementsString = elements.map { $0.description }.joined(separator: ", ")
        return "[\(elementsString)]"
    }
}

public struct HashPair {
    public let key: ObjectType
    public let value: ObjectType
    
    public init(key: ObjectType, value: ObjectType) {
        self.key = key
        self.value = value
    }
}

public struct HashObject {
    public let pairs: [HashPair]
    
    public init(pairs: [HashPair]) {
        self.pairs = pairs
    }
}

extension HashObject: ObjectType {
    public var kind: ObjectKind {
        return .hash
    }
    
    public var description: String {
        let pairsString = pairs.map { "\($0.key.description): \($0.value.description)" }.joined(separator: ", ")
        return "[\(pairsString)]"
    }
}
