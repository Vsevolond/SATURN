//
//  Lexeme.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 24.05.2026.
//

import Foundation

/// Распознанная единица входного текста
/// Конкретное вхождение токена в текст: имя сработавшего правила, поглощенная подстрока и позиция её начала
public struct Lexeme: Equatable {
    
    // MARK: - Public Properties
    
    /// Имя сработавшего правила из секции токенов
    public let name: String
    
    /// Подстрока входа, поглощенная правилом
    public let text: String
    
    /// Позиция первой кодовой  точки лексемы во входном тексте
    public let position: Position
}
