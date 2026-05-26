//
//  Attribute.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.03.2026.
//

/// Типизированное объявление атрибута, привязанного к символу грамматики
public struct Attribute {
    
    // MARK: - Type Entities
    
    public enum Kind {
        
        // MARK: - Cases
        
        /// Атрибут вычисляется по дочерним символам
        case synthesized
        
        /// Атрибут передается от родительского символа
        case inherited
    }
    
    // MARK: - Public Properties
    
    /// Свойство (имя + тип), которое описывает атрибут
    public let property: Property
    
    /// Имя символа, которому принадлежит атрибут
    public let target: String
    
    /// Вид атрибута
    public let type: Kind
    
    // MARK: - Initializers
    
    public init(
        property: Property,
        target: String,
        type: Kind = .synthesized
    ) {
        self.property = property
        self.target = target
        self.type = type
    }
}
