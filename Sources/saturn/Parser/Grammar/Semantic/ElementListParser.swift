//
//  ElementListParser.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Парсит последовательность элементов через пробелы
struct ElementListParser: Parser {
    
    // MARK: - Internal Properties
    
    /// Нетерминалы грамматики по именам
    let nonterms: HashMap<String, Nonterm>
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, [Production]> {
        Many(1...) {
            ElementParser(nonterms: nonterms)
            
        } separator: {
            Skipper(.horizontal)
        }
    }
}
