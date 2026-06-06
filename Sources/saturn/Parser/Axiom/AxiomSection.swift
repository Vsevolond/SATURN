//
//  AxiomSection.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

/// Парсит секцию `%axiom` — единственный идентификатор стартового нетерминала
struct AxiomSection: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, String> {
        Parse {
            /// Заголовок секции
            "%axiom"
            
            /// Пробелы и комментарии между заголовком и именем
            Skipper(comments: true)
            
            /// Имя стартового нетерминала
            NontermIdent()
        }
    }
}
