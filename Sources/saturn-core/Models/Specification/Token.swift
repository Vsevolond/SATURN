//
//  Token.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.03.2026.
//

import Foundation

/// Объявление лексического токена с правилом его распознавания
public struct Token {
    
    // MARK: - Type Entities
    
    public enum Value {
        
        // MARK: - Cases
        
        /// Фиксированная строка, которую лексер сопоставляет буквально: `"..."`
        case literal(String)
        
        /// Регулярное выражение, по которому лексер распознаёт токен: `/.../`
        case regex(NSRegularExpression)
    }
    
    // MARK: - Public Properties
    
    /// Имя токена в том виде, как оно объявлено в `%tokens`
    public let name: String
    
    /// Правило сопоставления, представляющее значение токена
    public let value: Value
    
    // MARK: - Initializers
    
    public init(name: String, value: Value) {
        self.name = name
        self.value = value
    }
}

// MARK: - Extensions

extension Token.Value: Equatable {
    
    // MARK: - Type Methods
    
    public static func == (lhs: Token.Value, rhs: Token.Value) -> Bool {
        switch (lhs, rhs) {
        case let (.literal(l), .literal(r)):
            return l == r
            
        case let (.regex(l), .regex(r)):
            return l.pattern == r.pattern
            
        default:
            return false
        }
    }
}
