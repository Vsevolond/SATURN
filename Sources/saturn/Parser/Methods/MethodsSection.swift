//
//  MethodsSection.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Парсит секцию `%methods` и собирает методы в словарь по имени
struct MethodsSection: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, [String: Method]> {
        Parse {
            /// Заголовок секции
            "%methods"
            
            /// Пробелы и комментарии после заголовка
            Skipper(comments: true)
            
            /// Последовательность объявлений методов
            Many(1...) { MethodDeclaration() } separator: { Skipper(comments: true) }
        }
        .map { methods in
            /// Собираем объявления методов в словаь по их именам
            methods.reduce(
                into: [String: Method]()
            ) { result, method in
                result[method.name] = method
            }
        }
    }
}
