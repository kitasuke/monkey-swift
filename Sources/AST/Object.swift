//
//  Object.swift
//  AST
//
//  Created by Yusuke Kita on 12/04/18.
//

public protocol Object {
    var type: ObjectType { get }
    func inspect() -> String
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
    
    public func inspect() -> String {
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
    
    public func inspect() -> String {
        return "\(value)"
    }
}

public struct Null {}

extension Null: Object {
    public var type: ObjectType {
        return .null
    }
    
    public func inspect() -> String {
        return type.rawValue
    }
}
