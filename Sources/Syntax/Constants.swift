//
//  Constants.swift
//  Syntax
//
//  Created by Yusuke Kita on 11/15/18.
//

public enum TokenSymbol: Character {
    case equal = "="
    case plus = "+"
    case minus = "-"
    case bang = "!"
    case asterisk = "*"
    case slash = "/"
    case comma = ","
    case semicolon = ";"
    case leftParen = "("
    case rightParen = ")"
    case leftBrace = "{"
    case rightBrace = "}"
    case lessThan = "<"
    case greaterThan = ">"
}

public enum TokenKeyword: String {
    case fn = "fn"
    case `let` = "let"
    case `true` = "true"
    case `false` = "false"
    case `if` = "if"
    case `else` = "else"
    case `return` = "return"
}
