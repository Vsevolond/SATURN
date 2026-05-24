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
