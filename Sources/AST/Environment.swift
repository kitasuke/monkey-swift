//
//  Environment.swift
//  AST
//
//  Created by Yusuke Kita on 12/04/18.
//

import Sema

public protocol EnvironmentType {
    var outer: EnvironmentType? { get }
    var storedObjects: [Identifier: ObjectType] { get }
    
    func object(for identifier: Identifier) -> ObjectType?
    func set(_ object: ObjectType, for identifier: Identifier)
}

public final class Environment: EnvironmentType {
    
    public let outer: EnvironmentType?
    public internal(set) var storedObjects: [Identifier: ObjectType]
    
    public init() {
        outer = nil
        storedObjects = [:]
    }
    
    public init(outer: EnvironmentType) {
        self.outer = outer
        storedObjects = [:]
    }
    
    public func object(for identifier: Identifier) -> ObjectType? {
        guard let object = storedObjects[identifier] else {
            return outer?.object(for: identifier)
        }
        return object
    }
    
    public func set(_ object: ObjectType, for identifier: Identifier) {
        storedObjects[identifier] = object
    }
}
