//
//  LexterTests.swift
//  LexerTests
//
//  Created by Yusuke Kita on 11/15/18.
//

import XCTest
import Token
import Lexer

final class LexerTests: XCTestCase {
    func test_nextToken() {
        let input = """
            let five = 5;
            let ten = 10;

            let add = fn(x, y) {
                x + y;
            };

            let result = add(five, ten);
            !-/*5;
            5 < 10 > 5;

            if (5 < 10) {
                return true;
            } else {
                return false;
            }

            10 == 10;
            10 != 9;
        """
        
        let expectedTokenTypes: [TokenType] = [
            .let, .identifier(type: .value(name: "five")), .assign, .int(value: 5), .semicolon,
            .let, .identifier(type: .value(name: "ten")), .assign, .int(value: 10), .semicolon,
            .let, .identifier(type: .value(name: "add")), .assign, .function, .leftParen, .identifier(type: .value(name: "x")), .comma, .identifier(type: .value(name: "y")), .rightParen, .leftBrace,
            .identifier(type: .value(name: "x")), .plus, .identifier(type: .value(name: "y")), .semicolon,
            .rightBrace, .semicolon,
            .let, .identifier(type: .value(name: "result")), .assign, .identifier(type: .value(name: "add")), .leftParen, .identifier(type: .value(name: "five")), .comma, .identifier(type: .value(name: "ten")), .rightParen, .semicolon,
            .bang, .minus, .slash, .asterisk, .int(value: 5), .semicolon,
            .int(value: 5), .lessThan, .int(value: 10), .greaterThan, .int(value: 5), .semicolon
        ]
        
        var lexer = Lexer(input: input)
        expectedTokenTypes.forEach { expectedTokenType in
            let tokenType = lexer.nextTokenType()
            
            if tokenType != expectedTokenType {
                XCTFail(String(format: "tokenType wrong. expected=%@, got=%@",
                               expectedTokenType.literal, tokenType.literal) )
            }
        }
    }
}
