//
//  AlternativeParser.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Парсит одну альтернативу правила:
/// Последовательность элементов и опциональный блок действий
struct AlternativeParser: Parser {
    
    // MARK: - Internal Properties
    
    /// Нетерминалы грамматики по именам
    let nonterms: HashMap<String, Nonterm>
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, Alternative> {
        Parse {
            /// Последовательность элементов правой части, хотя бы один элемент
            ElementListParser(nonterms: nonterms)
            
            /// Пробелы, комментарии перед опциональным блоком
            Skipper(comments: true)
            
            /// Опциональный семантический блок
            Optionally { SemanticBlock() }
        }
        .map { elements, actions in
            Alternative(elements: elements, actions: actions)
        }
    }
}
