//
//  Property.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.03.2026.
//

/// Именованное типизированное поле атрибута символа грамматики
public struct Property {
    
    // MARK: - Type Entities
    
    public indirect enum Kind {
        
        // MARK: - Cases
        
        /// Встроенный целочисленный тип
        case int
        
        /// Встроенный вещественный тип
        case float
        
        /// Встроенный булевый тип
        case bool
        
        /// Встроенный строковый тип
        case string
        
        /// Пользовательский тип, объявленный в `%types`
        case custom(String)
        
        /// Массив другого типа
        case array(Kind)
    }
    
    // MARK: - Public Properties
    
    /// Имя атрибута в том виде, как оно объявлено
    public let name: String
    
    /// Тип свойства
    public let type: Kind
    
    // MARK: - Initializers
    
    public init(name: String, type: Kind) {
        self.name = name
        self.type = type
    }
}
