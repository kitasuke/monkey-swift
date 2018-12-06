//
//  EvaluatorError.swift
//  AST
//
//  Created by Yusuke Kita on 11/15/18.
//

import Foundation
import Sema

public enum EvaluatorError: Error, CustomStringConvertible {
    case unknownNode(Node)
    case noValidExpression([Statement])
    case typeMissMatch(left: ObjectType, operator: String, right: ObjectType)
    case unknownOperator(left: ObjectType, operator: String, right: ObjectType)

    public var description: String {
        switch self {
        case .unknownNode(let node):
            return "unknown node: \(node.description)"
        case .noValidExpression(let statements):
            return "no valid expression from \(statements.map { $0.description })"
        case .typeMissMatch(let left, let `operator`, let right):
            return "type missmatch: \(left) \(`operator`) \(right)"
        case .unknownOperator(let left, let `operator`, let right):
            return "unknown operator: \(left) \(`operator`) \(right)"
        }
    }
}
