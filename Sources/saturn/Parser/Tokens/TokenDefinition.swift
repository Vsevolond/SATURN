//
//  TokenDefinition.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing
import Foundation

import saturn_core

/// Парсит одно объявление токена секции `%tokens`:
/// `NAME = "literal"` или `NAME = /regex/`.
struct TokenDefinition: Parser {
    
    // MARK: - Internal Methods
    
    func parse(_ input: inout Substring) throws -> Token {
        /// Имя токена в виде идентификатора `[A-Z][A-Z0-9_]*`
        let name = try TokenIdent().parse(&input)
        
        /// Пробелы перед `=`
        try Skipper(.horizontal).parse(&input)
        
        /// Разделитель имени и значения
        try "=".parse(&input)
        
        /// Пробелы после `=`
        try Skipper(.horizontal).parse(&input)
        
        /// Значение токена: строковый литерал или регулярное выражение
        let value = try value(&input)
        
        return Token(name: name, value: value)
    }
    
    // MARK: - Private Methods
    
    private func value(_ input: inout Substring) throws -> Token.Value {
        /// Литеральная форма начинается с `"`
        if input.first == "\"" {
            let literal = try StringLiteral().parse(&input)
            return .literal(literal)
            
        /// Иначе ожидаем форму регулярного выражения `/.../`
        } else {
            let pattern = try RegexLiteral().parse(&input)
            
            /// Компилируем шаблон
            do {
                let regex = try NSRegularExpression(pattern: pattern)
                return .regex(regex)
                
            } catch {
                throw Specification.ParseError
                    .invalidRegex(pattern: pattern, underlying: error)
            }
        }
    }
}
