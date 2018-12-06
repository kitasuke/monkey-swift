//
//  Evaluator.swift
//  AST
//
//  Created by Yusuke Kita on 12/04/18.
//

import Sema

public struct Evaluator {
    
    public init() {}
    
    public func evaluate(with astNode: Node) throws -> Object {
        switch astNode {
        case let node as IntegerLiteral:
            return Integer(value: node.value)
        default:
            throw EvaluatorError.unknownObject
        }
    }
}
