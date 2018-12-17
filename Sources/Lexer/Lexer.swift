//
//  Lexter.swift
//  Lexer
//
//  Created by Yusuke Kita on 11/15/18.
//

import Syntax

typealias Position = Int

public final class Lexer {
    private let input: String
    private var currentPosition: Position = 0 // current position in input
    private var readPosition: Position = 0 // current read position in input
    private var character: Character?
    
    public init(input: String) {
        self.input = input
        
        setNextCharacter()
    }
    
    public func nextToken() -> Token {
        let tokenType: TokenType
        
        skipWhitespace()
        
        switch character {
        case "=" where peekCharacter() == "=":
            setNextCharacter()
            tokenType = .equal
        case "=":
            tokenType = .assign
        case "+":
            tokenType = .plus
        case "-":
            tokenType = .minus
        case "!" where peekCharacter() == "=":
            setNextCharacter()
            tokenType = .notEqual
        case "!":
            tokenType = .bang
        case "*":
            tokenType = .asterisk
        case "/":
            tokenType = .slash
        case ",":
            tokenType = .comma
        case ";":
            tokenType = .semicolon
        case "<":
            tokenType = .lessThan
        case ">":
            tokenType = .greaterThan
        case "(":
            tokenType = .leftParen
        case ")":
            tokenType = .rightParen
        case "{":
            tokenType = .leftBrace
        case "}":
            tokenType = .rightBrace
        case "\"":
            return .makeString(string: readString())
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
    
    private func setNextCharacter() {
        if readPosition < input.count {
            let index = input.index(input.startIndex, offsetBy: readPosition)
            character = input[index]
        } else {
            character = nil
        }
        currentPosition = readPosition
        readPosition += 1
    }
    
    private func readCharacter(while condition: ((Character) -> Bool)) -> String {
        let position = currentPosition

        while let character = self.character, condition(character) {
            setNextCharacter()
        }
        let startIndex = input.index(input.startIndex, offsetBy: position)
        let endIndex = input.index(startIndex, offsetBy: currentPosition - position)
        return String(input[startIndex..<endIndex])
    }
    
    private func readIdentifier() -> String {
        return readCharacter(while: isLetter)
    }
    
    private func readString() -> String {
        // "
        setNextCharacter()
        // x
        let string = readCharacter(while: isString)
        // "
        setNextCharacter()
        return string
    }
    
    private func readNumber() -> String {
        return readCharacter(while: isDigit)
    }
    
    private func peekCharacter() -> Character? {
        guard readPosition <= input.count else {
            return nil
        }
        let index = input.index(input.startIndex, offsetBy: readPosition)
        return input[index]
    }
    
    private func skipWhitespace() {
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
    
    private func isString(_ character: Character) -> Bool {
        return character != "\""
    }
    
    private func isDigit(_ character: Character) -> Bool {
        return ("0"..."9").contains(character)
    }
}
