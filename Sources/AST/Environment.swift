//
//  Environment.swift
//  AST
//
//  Created by Yusuke Kita on 12/04/18.
//

import Sema

protocol EnvironmentType {
    var storedObjects: [Identifier: Object] { get set }
    
    func object(of identifier: Identifier) -> Object?
    func set(_ object: Object, with identifier: Identifier)
}

public class Environment: EnvironmentType {
    
    var storedObjects: [Identifier: Object]
    
    public init() {
        storedObjects = [:]
    }
    
    public func object(of identifier: Identifier) -> Object? {
        return storedObjects[identifier]
    }
    
    public func set(_ object: Object, with identifier: Identifier) {
        storedObjects[identifier] = object
    }
}
