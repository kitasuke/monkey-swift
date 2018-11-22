//
//  Lexter.swift
//  Lexer
//
//  Created by Yusuke Kita on 11/15/18.
//

import Token

typealias Position = Int

public struct Lexer {
    let input: String
    var currentPosition: Position = 0 // current position in input
    var readPosition: Position = 0 // current read position in input
    var character: Character?
    
    public init(input: String) {
        self.input = input
        
        setNextCharacter()
    }
    
    public mutating func nextToken() -> Token {
        let tokenType: TokenType
        
        skipWhitespace()
        
        switch character {
        case TokenSymbol.equal.rawValue where peekCharacter() == TokenSymbol.equal.rawValue:
            setNextCharacter()
            tokenType = .equal
        case TokenSymbol.equal.rawValue:
            tokenType = .assign
        case TokenSymbol.plus.rawValue:
            tokenType = .plus
        case TokenSymbol.minus.rawValue:
            tokenType = .minus
        case TokenSymbol.bang.rawValue where peekCharacter() == TokenSymbol.equal.rawValue:
            setNextCharacter()
            tokenType = .notEqual
        case TokenSymbol.bang.rawValue:
            tokenType = .bang
        case TokenSymbol.asterisk.rawValue:
            tokenType = .asterisk
        case TokenSymbol.slash.rawValue:
            tokenType = .slash
        case TokenSymbol.comma.rawValue:
            tokenType = .comma
        case TokenSymbol.semicolon.rawValue:
            tokenType = .semicolon
        case TokenSymbol.lessThan.rawValue:
            tokenType = .lessThan
        case TokenSymbol.greaterThan.rawValue:
            tokenType = .greaterThan
        case TokenSymbol.leftParen.rawValue:
            tokenType = .leftParen
        case TokenSymbol.rightParen.rawValue:
            tokenType = .rightParen
        case TokenSymbol.leftBrace.rawValue:
            tokenType = .leftBrace
        case TokenSymbol.rightBrace.rawValue:
            tokenType = .rightBrace
        case let character? where isLetter(character):
            return .makeIdentifier(identifier: readIdentifier())
        case let character? where isDigit(character):
            return .makeNumber(number: readNumber())
        case nil:
            return .init(type: .eof)
        default:
            return .init(type: .illegal)
        }
        
        setNextCharacter()
        return .init(type: tokenType)
    }
    
    private mutating func setNextCharacter() {
        if readPosition < input.count {
            let index = input.index(input.startIndex, offsetBy: readPosition)
            character = input[index]
        } else {
            character = nil
        }
        currentPosition = readPosition
        readPosition += 1
    }
    
    private mutating func readCharacter(while condition: ((Character) -> Bool)) -> String {
        let position = currentPosition

        while let character = self.character, condition(character) {
            setNextCharacter()
        }
        let startIndex = input.index(input.startIndex, offsetBy: position)
        let endIndex = input.index(startIndex, offsetBy: currentPosition - position)
        return String(input[startIndex..<endIndex])
    }
    
    private mutating func readIdentifier() -> String {
        return readCharacter(while: isLetter)
    }
    
    private mutating func readNumber() -> String {
        return readCharacter(while: isDigit)
    }
    
    private func peekCharacter() -> Character? {
        guard readPosition <= input.count else {
            return nil
        }
        let index = input.index(input.startIndex, offsetBy: readPosition)
        return input[index]
    }
    
    private mutating func skipWhitespace() {
        while character == " " ||
            character == "\t" ||
            character == "\n" ||
            character == "\r" {
            setNextCharacter()
        }
    }
    
    private func isLetter(_ character: Character) -> Bool {
        return ("a"..."z").contains(character) ||
            ("A" ... "Z").contains(character) ||
            character == "_"
    }
    
    private func isDigit(_ character: Character) -> Bool {
        return ("0"..."9").contains(character)
    }
}
