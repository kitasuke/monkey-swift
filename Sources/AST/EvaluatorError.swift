//
//  EvaluatorError.swift
//  AST
//
//  Created by Yusuke Kita on 11/15/18.
//

import Foundation
import Sema

public enum EvaluatorError: Error {
    case unknownNode(Node)
    case noValidExpression([Statement])
    case typeMissMatch(left: ObjectType, operator: String, right: ObjectType)
    case unknownOperator(left: ObjectType?, operator: String, right: ObjectType)
    case notFunction(object: Object)
    case unsupportedArgument(for: BuiltinIdentifier, argument: Object)
    case unsupportedIndexOperator(index: Object, left: Object)
}

extension EvaluatorError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknownNode(let node):
            return "unknown node: \(node.description)"
        case .noValidExpression(let statements):
            return "no valid expression from \(statements.map { $0.description })"
        case .typeMissMatch(let left, let `operator`, let right):
            return "type missmatch: \(left) \(`operator`) \(right)"
        case .unknownOperator(let left?, let `operator`, let right):
            return "unknown operator: \(left) \(`operator`) \(right)"
        case .unknownOperator(_, let `operator`, let right):
            return "unknown operator: \(`operator`)\(right)"
        case .notFunction(let object):
            return "not a function: \(object.type)"
        case .unsupportedArgument(let builtinIdentifier, let argument):
            return "argument \(type(of: argument)) to \(builtinIdentifier.rawValue) not supported"
        case .unsupportedIndexOperator(let index, let left):
            return "index operator \(index.type) not supported \(left.type)"
        }
    }
}
