//
//  Lexeme.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 24.05.2026.
//

import Foundation

/// Распознанная единица входного текста
/// Конкретное вхождение токена в текст: имя сработавшего правила, поглощенная подстрока и позиция ее начала
public struct Lexeme: Equatable, Sendable {
    
    // MARK: - Public Properties
    
    /// Имя сработавшего правила из секции токенов
    public let name: String
    
    /// Подстрока входа, поглощенная правилом
    public let text: String
    
    /// Позиция первой кодовой  точки лексемы во входном тексте
    public let position: Position
    
    // MARK: - Initializers
    
    public init(name: String, text: String, position: Position) {
        self.name = name
        self.text = text
        self.position = position
    }
}
