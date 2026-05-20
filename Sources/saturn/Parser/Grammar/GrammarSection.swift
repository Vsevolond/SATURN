//
//  GrammarSection.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Парсит секцию `%grammar` и собирает все правила в словарь по имени нетерминала
struct GrammarSection: Parser {
    
    // MARK: - Internal Properties
    
    let nonterms: HashMap<String, Nonterm>
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, Void> {
        Parse {
            /// Заголовок секции
            "%grammar"
            
            /// Пробелы и комментарии после заголовка
            Skipper(comments: true)
            
            /// Последовательность правил
            Many(1...) {
                RuleParser(nonterms: nonterms)
                
            } separator: {
                Skipper(comments: true)
            }
        }
        .map { _ in () }
    }
}
