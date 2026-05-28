//
//  Scanner.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 24.05.2026.
//

import Foundation

/// Динамический лексический анализатор, построенный по секции токенов
///
/// Работает по принципу максимального жадного совпадения:
/// - из текущей позиции выбирается правило, поглощающее самый длинный префикс
/// - при равной длине побеждает правило, объявленное раньше
/// - между лексемами пропускаются пробельные символы
public struct Scanner {
    
    // MARK: - Private Properties
    
    /// Правила распознавания в порядке объявления
    private let tokens: [Token]
    
    // MARK: - Initializers
    
    public init(tokens: [Token]) { self.tokens = tokens }
    
    // MARK: - Public Methods
    
    /// Разбивает входной текст на последовательность лексем
    public func scan(_ text: String) throws(LexicalError) -> [Lexeme] {
        let characters = Array(text)
        var lexemes: [Lexeme] = []
        
        var offset = 0
        var line = 1
        var column = 1
        
        while offset < characters.count {
            let character = characters[offset]
            /// Пропуск пробельных символов с ведением позиции
            if character.isWhitespace {
                /// Если перевод строки
                if character.isNewline {
                    line += 1
                    column = 1
                
                /// Иначе — просто пробел
                } else {
                    column += 1
                }
                
                offset += 1
                
                continue
            }
            
            let position = Position(line: line, column: column, offset: offset)
            
            /// Самое длинное совпадение, при равенстве — раннее правило
            guard let match = longestMatch(in: characters, from: offset) else {
                throw LexicalError.unexpectedCharacter(character, at: position)
            }
            
            /// Получаем текст лексемы
            let text = String(characters[offset..<(offset + match.length)])
            let lexeme = Lexeme(name: match.name, text: text, position: position)
            
            lexemes.append(lexeme)
            
            /// Продвижение позиции на длину поглощенного префикса
            offset += match.length
            column += match.length
        }
        
        return lexemes
    }
    
    // MARK: - Private Methods
    
    /// Находит самое длинное совпадение среди всех правил из текущей позиции
    private func longestMatch(
        in characters: [Character],
        from offset: Int
    ) -> (name: String, length: Int)? {
        var best: (name: String, length: Int)? = nil
        
        for token in tokens {
            /// Получаем длину совпадения входа со значением выбранного токена
            let length = matchLength(of: token.value, in: characters, from: offset)
            
            /// Длина должна быть больше нуля
            guard length > 0 else { continue }
            
            /// Сравнение с лучшим результатом
            if let (_, bestLength) = best, length > bestLength {
                best = (token.name, length)
            
            /// Или запись, если лучшего результата еще нет
            } else if best == nil {
                best = (token.name, length)
            }
        }
        
        return best
    }
    
    /// Возвращает длину префикса, поглощаемого правилом из текущей позиции
    private func matchLength(
        of value: Token.Value,
        in characters: [Character],
        from offset: Int
    ) -> Int {
        switch value {
        case .literal(let literal):
            return literalLength(literal, in: characters, from: offset)
            
        case .regex(let regex):
            return regexLength(regex, in: characters, from: offset)
        }
    }
    
    /// Длина точного сопадения литерала с префиксом входа
    private func literalLength(
        _ literal: String,
        in characters: [Character],
        from offset: Int
    ) -> Int {
        let pattern = Array(literal)
        
        /// Литерал не должен быть пустым + его длина не должна выходить за границу
        guard !pattern.isEmpty, offset + pattern.count <= characters.count else {
            return 0
        }
        
        /// Если встретились несовпадающие символы, то возвращаем нулевую длину
        for index in 0..<pattern.count where characters[offset + index] != pattern[index] {
            return 0
        }
        
        return pattern.count
    }
    
    /// Длина совпадения регулярного выражения с префиксом входа
    private func regexLength(
        _ regex: NSRegularExpression,
        in characters: [Character],
        from offset: Int
    ) -> Int {
        let tail = String(characters[offset...])
        let range = NSRange(tail.startIndex..., in: tail)
        
        /// Получаем префикс совпадения
        guard let match = regex.firstMatch(in: tail, options: .anchored, range: range),
              match.range.location == 0,
              let matched = Range(match.range, in: tail)
        else {
            return 0
        }
        
        /// Длина в кодовых точках
        return tail.distance(from: matched.lowerBound, to: matched.upperBound)
    }
}
