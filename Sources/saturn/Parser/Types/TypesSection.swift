//
//  TypesSection.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

/// Парсит секцию `%types` и собирает имена объявленных пользовательских типов
struct TypesSection: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, Set<String>> {
        Parse {
            /// Заголовок секции
            "%types"
            
            /// Пробелы и комментарии после заголовка
            Skipper(comments: true)
            
            /// Последовательность имён типов, разделённых пробелами и комментариями
            Many(1...) { TypeIdent() } separator: { Skipper(comments: true) }
        }
        .map { Set($0) }
    }
}
