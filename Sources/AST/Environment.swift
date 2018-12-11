//
//  Environment.swift
//  AST
//
//  Created by Yusuke Kita on 12/04/18.
//

import Sema

public protocol EnvironmentType {
    var storedObjects: [Identifier: Object] { get }
    
    func object(for identifier: Identifier) -> Object?
    func set(_ object: Object, for identifier: Identifier)
}

public class Environment: EnvironmentType {
    
    public var storedObjects: [Identifier: Object]
    
    public init() {
        storedObjects = [:]
    }
    
    public func object(for identifier: Identifier) -> Object? {
        return storedObjects[identifier]
    }
    
    public func set(_ object: Object, for identifier: Identifier) {
        storedObjects[identifier] = object
    }
}
