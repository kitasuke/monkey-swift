//
//  Environment.swift
//  AST
//
//  Created by Yusuke Kita on 12/04/18.
//

import Sema

public protocol EnvironmentType {
    var outer: EnvironmentType? { get }
    var storedObjects: [Identifier: Object] { get }
    
    func object(for identifier: Identifier) -> Object?
    func set(_ object: Object, for identifier: Identifier)
}

public class Environment: EnvironmentType {
    
    public let outer: EnvironmentType?
    public internal(set) var storedObjects: [Identifier: Object]
    
    public init() {
        outer = nil
        storedObjects = [:]
    }
    
    public init(outer: EnvironmentType) {
        self.outer = outer
        storedObjects = [:]
    }
    
    public func object(for identifier: Identifier) -> Object? {
        guard let object = storedObjects[identifier] else {
            return outer?.object(for: identifier)
        }
        return object
    }
    
    public func set(_ object: Object, for identifier: Identifier) {
        storedObjects[identifier] = object
    }
}
