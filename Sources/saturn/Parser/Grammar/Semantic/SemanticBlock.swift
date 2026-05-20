//
//  SemanticBlock.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Парсит блок семантических действий в скобках: `{ stmt; stmt; ... }`
struct SemanticBlock: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, [Statement]> {
        Parse {
            /// Открывающая фигурная скобка
            "{"
            
            /// Пробелы и комментарии после `{`
            Skipper(comments: true)
            
            /// Последовательность операторов, разделённых пробелами и комментариями
            Many { StatementParser() } separator: { Skipper(comments: true) }
            
            /// Пробелы и комментарии перед `}`
            Skipper(comments: true)
            
            /// Закрывающая фигурная скобка
            "}"
        }
    }
}
