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
        """
        
        let expectedTokens: [Token] = [
            .init(type: .let), .makeIdentifier(identifier: "five"), .init(type: .assign), .makeNumber(number: "5"), .init(type: .semicolon),
            .init(type: .let), .makeIdentifier(identifier: "ten"), .init(type: .assign), .makeNumber(number: "10"), .init(type: .semicolon),
            .init(type: .let), .makeIdentifier(identifier: "add"), .init(type: .assign), .init(type: .function), .init(type: .leftParen), .makeIdentifier(identifier: "x"), .init(type: .comma), .makeIdentifier(identifier: "y"), .init(type: .rightParen), .init(type: .leftBrace), .makeIdentifier(identifier: "x"), .init(type: .plus), .makeIdentifier(identifier: "y"), .init(type: .semicolon), .init(type: .rightBrace), .init(type: .semicolon),
            .init(type: .let), .makeIdentifier(identifier: "result"), .init(type: .assign), .makeIdentifier(identifier: "add"), .init(type: .leftParen), .makeIdentifier(identifier: "five"), .init(type: .comma), .makeIdentifier(identifier: "ten"), .init(type: .rightParen), .init(type: .semicolon),
            .init(type: .bang), .init(type: .minus), .init(type: .slash), .init(type: .asterisk), .makeNumber(number: "5"), .init(type: .semicolon),
            .makeNumber(number: "5"), .init(type: .lessThan), .makeNumber(number: "10"), .init(type: .greaterThan), .makeNumber(number: "5"), .init(type: .semicolon)
        ]

        var lexer = Lexer(input: input)
        expectedTokens.forEach { expectedToken in
            let token = lexer.nextToken()
            XCTAssertTrue(token == expectedToken, "tokenType wrong. expected=\(expectedToken), got=\(token)")
        }
    }
}
