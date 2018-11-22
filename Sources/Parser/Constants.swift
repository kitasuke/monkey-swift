//
//  Constants.swift
//  Constants
//
//  Created by Yusuke Kita on 11/15/18.
//

import Token

enum PrecedenceKind: UInt {
    case lowest
    case equals
    case lessOrGreater
    case sum
    case product
    case prefix
    case call
}

extension PrecedenceKind {
    static func precedence(for tokenType: TokenType) -> PrecedenceKind {
        switch tokenType {
        case .equal, .notEqual: return .equals
        case .lessThan, .greaterThan: return .lessOrGreater
        case .plus, .minus: return .sum
        case .slash, .asterisk: return .product
        default: return .lowest
        }
    }
}
