//
//  EvaluatorError.swift
//  AST
//
//  Created by Yusuke Kita on 11/15/18.
//

import Foundation

public enum EvaluatorError: Error, CustomStringConvertible {
    case unknownObject

    public var description: String {
        switch self {
        case .unknownObject:
            return "unknown object"
        }
    }
}
