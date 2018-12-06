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

    public var description: String {
        switch self {
        case .unknownNode(let node):
            return "unknown node: \(node.description)"
        case .noValidExpression(let statements):
            return "no valid expression from \(statements.map { $0.description })"
        }
    }
}
