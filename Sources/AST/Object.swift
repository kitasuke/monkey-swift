//
//  Object.swift
//  AST
//
//  Created by Yusuke Kita on 12/04/18.
//

import Sema

public protocol Object: CustomStringConvertible {
    var type: ObjectType { get }
}

public struct Integer {
    public let value: Int64
    
    public init(value: Int64) {
        self.value = value
    }
}

extension Integer: Object {
    public var type: ObjectType {
        return .integer
    }
    
    public var description: String {
        return "\(value)"
    }
}

public struct Boolean {
    public let value: Bool
    
    public init(value: Bool) {
        self.value = value
    }
}

extension Boolean: Object {
    public var type: ObjectType {
        return .boolean
    }
    
    public var description: String {
        return "\(value)"
    }
}

public struct StringObject {
    public let value: String
    
    public init(value: String) {
        self.value = value
    }
}

extension StringObject: Object {
    public var type: ObjectType {
        return .string
    }
    
    public var description: String {
        return "\(value)"
    }
}

public struct Null {}

extension Null: Object {
    public var type: ObjectType {
        return .null
    }
    
    public var description: String {
        return type.rawValue
    }
}

public struct ReturnValue {
    public let value: Object
    
    public init(value: Object) {
        self.value = value
    }
}

extension ReturnValue: Object {
    public var type: ObjectType {
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

extension Function: Object {
    public var type: ObjectType {
        return .function
    }
    
    public var description: String {
        let params = parameters.map { $0.description }.joined(separator: ", ")
        return "fn(\(params)) {\n\(body.description)\n}"
    }
}
