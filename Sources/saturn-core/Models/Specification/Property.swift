//
//  Property.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.03.2026.
//

/// Именованное типизированное поле атрибута символа грамматики
public struct Property {
    
    // MARK: - Type Entities
    
    public indirect enum Kind: Equatable {
        
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
        
        /// Опциональный тип
        case optional(Kind)
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

// MARK: - Extensions

extension Property.Kind {
    
    // MARK: - Internal Properties
    
    /// Идентификатор представление типа
    var identifier: String {
        switch self {
        case .int: "int"
        case .float: "float"
        case .bool: "bool"
        case .string: "string"
        case .custom(let type): type
        case .array(let kind): "array<\(kind.identifier)>"
        case .optional(let kind): "optional<\(kind.identifier)>"
        }
    }
    
    /// Является ли тип опциональным
    var isOptional: Bool {
        guard case .optional = self else {
            return false
        }
        
        return true
    }
    
    /// Является ли тип числовым
    var isNumeric: Bool {
        if case .int = self { return true }
        if case .float = self { return true }
        
        return false
    }
    
    /// Является ли тип вещественным
    var isFloat: Bool {
        guard case .float = self else {
            return false
        }
        
        return true
    }
    
    // MARK: - Internal Methods
    
    /// Проверка совместимости типов при присваивании: self → type
    func assignable(to type: Property.Kind) -> Bool {
        /// Проверка равенства типов
        guard self != type else { return true }
        
        /// int/float → float ✔, float → int — нельзя
        if type.isFloat && isNumeric { return true }
        
        /// optional/non-optional → optional ✔, optional → non-optional — нельзя
        if case .optional(let nested) = type {
            /// optional  → optional
            if case .optional(let selfNested) = self {
                return selfNested.assignable(to: nested)
            
            /// non-optional → optional
            } else {
                return assignable(to: nested)
            }
        }
        
        return false
    }
}
