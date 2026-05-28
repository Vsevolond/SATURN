//
//  LexicalError.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 24.05.2026.
//

import Foundation

/// Ошибка лексического анализа
public enum LexicalError: Error, Equatable {
    
    // MARK: - Cases
    
    /// Ни одно правило из секции токенов не сработало в указанной позиции
    case unexpectedCharacter(Character, at: Position)
}

// MARK: - Extensions

extension LexicalError: CustomStringConvertible {
    
    // MARK: - Public Properties
    
    /// Описание лексической ошибки
    public var description: String {
        switch self {
        case .unexpectedCharacter(let character, let position):
            return "Неожиданный символ «\(character)» в строке \(position.line), позиция \(position.column)"
        }
    }
}
