//
//  StatementParser.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Парсит один оператор внутри семантического блока:
/// присваивание `$N.attr = expr;` или вызов метода `name(...);`
struct StatementParser: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, Statement> {
        OneOf {
            /// Присваивание начинается с `$`
            AssignmentStatement()
            
            /// Иначе — вызов метода
            CallStatement()
        }
    }
}
