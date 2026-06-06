//
//  ExpressionParser.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Парсит арифметическое выражение с приоритетом операторов:
/// `*` и `/` связаны сильнее, чем `+` и `-`, ассоциативность левая
struct ExpressionParser: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, Expression> {
        AdditiveParser()
    }
}
