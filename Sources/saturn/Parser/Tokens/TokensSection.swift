//
//  TokensSection.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Парсит секцию `%tokens` и собирает все объявленные токены в словарь по имени
struct TokensSection: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, [Token]> {
        Parse {
            /// Заголовок секции
            "%tokens"
            
            /// Пробелы и комментарии после заголовка
            Skipper(comments: true)
            
            /// Последовательность объявлений токенов, разделённых пробелами и комментариями
            Many(1...) { TokenDefinition() } separator: { Skipper(comments: true) }
        }
    }
}
