//
//  AttributesSection.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Парсит секцию `%attributes` и группирует атрибуты по имени символа-владельца
struct AttributesSection: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, [String: [Attribute]]> {
        Parse {
            /// Заголовок секции
            "%attributes"
            
            /// Пробелы и комментарии после заголовка
            Skipper(comments: true)
            
            /// Последовательность объявлений атрибутов
            Many(1...) { AttributeDeclaration() } separator: { Skipper(comments: true) }
        }
        .map { attributes in
            /// Группируем по имени символа-владельца
            Dictionary(grouping: attributes) { $0.target }
        }
    }
}
