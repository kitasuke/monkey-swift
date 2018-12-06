//
//  Evaluator.swift
//  AST
//
//  Created by Yusuke Kita on 12/04/18.
//

import Sema

public struct Evaluator {
    
    public init() {}
    
    public func evaluate(astNode: Node) throws -> Object {
        switch astNode {
        case let node as Program:
            return try evaluateStatements(node.statements)
        case let node as ExpressionStatement:
            return try evaluate(astNode: node.expression)
        case let node as IntegerLiteral:
            return Integer(value: node.value)
        default:
            throw EvaluatorError.unknownNode(astNode)
        }
    }
    
    private func evaluateStatements(_ statements: [Statement]) throws -> Object {
        guard let object = try statements.map({ try evaluate(astNode: $0) }).last else {
            throw EvaluatorError.noValidExpression(statements)
        }
        return object
    }
}
