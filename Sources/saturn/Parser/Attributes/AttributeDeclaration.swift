//
//  AttributeDeclaration.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Парсит объявление атрибута:
/// `Symbol.attr : Type;` или `Symbol.attr : Type (inherited);`
struct AttributeDeclaration: Parser {
    
    // MARK: - Internal Methods
    
    func parse(_ input: inout Substring) throws -> Attribute {
        /// Имя символа-владельца атрибута
        let symbol = try BaseIdent(form: .mixed).parse(&input)
        
        /// Разделитель имени символа и имени атрибута
        try ".".parse(&input)
        
        /// Имя самого атрибута
        let attribute = try BaseIdent(form: .mixed).parse(&input)
        
        /// Пробелы перед двоеточием
        try Skipper(.horizontal).parse(&input)
        
        /// Разделитель имени и типа
        try ":".parse(&input)
        
        /// Пробелы перед типом
        try Skipper(.horizontal).parse(&input)
        
        /// Тип атрибута
        let type = try AttributeType().parse(&input)
        
        /// Пробелы перед опциональным видом
        try Skipper(.horizontal).parse(&input)
        
        /// Необязательное уточнение вида: `(synthesized)` или `(inherited)`
        let kind = try kind(&input)
        
        /// Пробелы перед `;`
        try Skipper(.horizontal).parse(&input)
        
        /// Завершающая точка с запятой
        try ";".parse(&input)
        
        return Attribute(
            property: Property(name: attribute, type: type),
            target: symbol,
            type: kind
        )
    }
    
    // MARK: - Private Methods
    
    /// Разбирает опциональное `(synthesized)` или `(inherited)`
    /// Возвращает `.synthesized` по умолчанию
    private func kind(_ input: inout Substring) throws -> Attribute.Kind {
        /// Без открывающей скобки берём значение по умолчанию
        guard input.first == "(" else { return .synthesized }
        
        input.removeFirst()
        try Skipper(.horizontal).parse(&input)
        
        let kind = try OneOf {
            Parse { "synthesized" }.map { Attribute.Kind.synthesized }
            Parse { "inherited" }.map { Attribute.Kind.inherited }
        }.parse(&input)
        
        try Skipper(.horizontal).parse(&input)
        try ")".parse(&input)
        
        return kind
    }
}
