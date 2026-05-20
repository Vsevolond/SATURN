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
            
            /// Хвост — произвольное число пар `[]`
            Many { "[]" }
        }
        .map { base, dimensions in
            /// Заворачиваем базовый тип в `.array` столько раз, сколько было `[]`
            dimensions.reduce(base) { type, _ in Property.Kind.array(type) }
        }
    }
}
