//
//  Scanner-Tests.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 24.05.2026.
//

import Testing
import Foundation

@testable import saturn_core

struct ScannerTests {
    
    // MARK: - Tests
    
    /// Жадность: `==` поглощается целиком, а не как два `=`
    @Test func testMaximalMunchPrefersLongerLiteral() throws {
        let scanner = Scanner(
            tokens: [
                Token(name: "ASSIGN", value: .literal("=")),
                Token(name: "EQ", value: .literal("==")),
            ]
        )
        
        let lexemes = try scanner.scan("==")
        
        #expect(lexemes.map(\.name) == ["EQ"])
        #expect(lexemes.first?.text == "==")
    }
    
    /// При равной длине совпадения побеждает правило, объявленное раньше
    @Test func testEqualLengthFavorsEarlierRule() throws {
        let scanner = try Scanner(
            tokens: [
                Token(name: "IF", value: .literal("if")),
                Token(name: "IDENT", value: regex("[a-z]+")),
            ]
        )
        
        let lexemes = try scanner.scan("if")
        
        #expect(lexemes.map(\.name) == ["IF"])
    }
    
    /// Идентификатор длиннее ключевого слова — побеждает по длине,
    /// несмотря на более поздний порядок объявления
    @Test func testLongerRegexBeatsEarlierShorterLiteral() throws {
        let scanner = try Scanner(
            tokens: [
                Token(name: "IF", value: .literal("if")),
                Token(name: "IDENT", value: regex("[a-z]+")),
            ]
        )
        
        let lexemes = try scanner.scan("iffy")
        
        #expect(lexemes.map(\.name) == ["IDENT"])
        #expect(lexemes.first?.text == "iffy")
    }
    
    /// Позиции ведутся по строкам и столбцам через переводы строк,
    /// пробелы между лексемами пропускаются
    @Test func testPositionTrackingAcrossNewlines() throws {
        let scanner = try Scanner(
            tokens: [
                Token(name: "IDENT", value: regex("[a-z]+")),
            ]
        )
        
        let lexemes = try scanner.scan("ab\n  cd")
        
        #expect(lexemes.count == 2)
        #expect(lexemes[0].position == Position(line: 1, column: 1, offset: 0))
        #expect(lexemes[1].position == Position(line: 2, column: 3, offset: 5))
    }
    
    /// Из позиции, где не срабатывает ни одно правило, сканер бросает
    /// ошибку с корректной позицией проблемной кодовой точки
    @Test func testUnexpectedCharacterReportsPosition() throws {
        let scanner = try Scanner(
            tokens: [
                Token(name: "IDENT", value: regex("[a-z]+")),
            ]
        )
        
        #expect(
            throws: LexicalError.unexpectedCharacter(
                "#",
                at: Position(line: 1, column: 3, offset: 2)
            )
        ) {
            try scanner.scan("ab#")
        }
    }
    
    /// Пустой вход дает пустую последовательность лексем
    @Test func testEmptyInputYieldsNoLexemes() throws {
        let scanner = try Scanner(
            tokens: [
                Token(name: "IDENT", value: regex("[a-z]+")),
            ]
        )
        
        let lexemes = try scanner.scan("")
        
        #expect(lexemes.isEmpty)
    }
    
    /// Вход из одних пробелов также дает пустую последовательность
    @Test func testWhitespaceOnlyInputYieldsNoLexemes() throws {
        let scanner = try Scanner(
            tokens: [
                Token(name: "IDENT", value: regex("[a-z]+")),
            ]
        )
        
        let lexemes = try scanner.scan("")
        
        #expect(lexemes.isEmpty)
    }
    
    /// Регулярное выражение применяется правильно
    @Test func testRegexIsAnchoredToCurrentPosition() throws {
        let scanner = try Scanner(
            tokens: [
                Token(name: "NUMBER", value: regex("[0-9]+")),
                Token(name: "PLUS", value: .literal("+")),
            ]
        )
        
        let lexemes = try scanner.scan("12+34")
        
        #expect(lexemes.map(\.name) == ["NUMBER", "PLUS", "NUMBER"])
        #expect(lexemes.map(\.text) == ["12", "+", "34"])
    }
    
    /// Литералы-операторы, ключевое слово, числа,
    /// идентификаторы — проверка имен и позиций в одном потоке
    @Test func testRealisticTokenStream() throws {
        let scanner = try Scanner(
            tokens: [
                Token(name: "LET", value: .literal("let")),
                Token(name: "IDENT", value: regex("[a-zA-Z_][a-zA-Z0-9_]*")),
                Token(name: "NUMBER", value: regex("[0-9]+")),
                Token(name: "ASSIGN", value: .literal("=")),
                Token(name: "PLUS", value: .literal("+")),
            ]
        )
        
        let lexemes = try scanner.scan("let x = 1 + 20")
        
        #expect(lexemes.map(\.name) == ["LET", "IDENT", "ASSIGN", "NUMBER", "PLUS", "NUMBER"])
        #expect(lexemes.map(\.text) == ["let", "x", "=", "1", "+", "20"])
    }
    
    // MARK: - Private Methods
    
    /// Строит регулярное выражение
    private func regex(_ pattern: String) throws -> Token.Value {
        let regex = try NSRegularExpression(pattern: pattern)
        return .regex(regex)
    }
}
