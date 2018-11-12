public struct Token {
    let type: TokenType
    let literal: String
}

public enum TokenType: String {
    case illegal = "Illegal"
    case eof = "EOF"

    // Identifiers + literals
    case identifier = "Identifier" // add, foobar, x, y, ...
    case int = "Int" // 123456789
    
    // Operators
    case assign = "="
    case plus = "+"
    case comma = ","
    case semicolon = ";"
    
    case leftParen = "("
    case rightParen = ")"
    case leftBrace = "{"
    case rightBrace = "}"
    
    // Keywords
    case function = "Function"
    case `let` = "Let"
}
