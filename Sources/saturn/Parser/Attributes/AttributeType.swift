//
//  AttributeType.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Парсит обозначение типа: `int`, `string[]`, `SomeType[][]` и т. п.
struct AttributeType: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, Property.Kind> {
        Parse {
            /// Базовый тип — один из встроенных или пользовательский идентификатор
            OneOf {
                "int".map { Property.Kind.int }
                "float".map { Property.Kind.float }
                "bool".map { Property.Kind.bool }
                "string".map { Property.Kind.string }
                
                /// Пользовательский тип
                TypeIdent().map { Property.Kind.custom($0) }
            }
            
            /// Опционал базового типа
            Optionally { "?" }
            
            /// Хвост — произвольное число пар `[]`, у каждой свой опциональный `?`
            Many {
                Parse {
                    "[]"
                    Optionally { "?" }
                }
            }
        }
        .map { base, optional, dimensions in
            /// Базовый тип, при необходимости обёрнутый в опционал
            let base = optional == nil ? base : .optional(base)
            
            /// Каждая пара `[]` оборачивает текущий тип в массив,
            /// затем — в опционал, если за этой парой стоял `?`
            return dimensions.reduce(base) { type, dimension in
                let array = Property.Kind.array(type)
                
                return dimension == nil ? array : .optional(array)
            }
        }
    }
}
