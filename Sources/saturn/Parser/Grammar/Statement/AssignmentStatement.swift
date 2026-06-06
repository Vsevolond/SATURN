//
//  AssignmentStatement.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Парсит присваивание атрибуту: `$N.attr = expr;`
struct AssignmentStatement: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, Statement> {
        Parse {
            /// Левая часть — ссылка на атрибут
            AttributeReference()
            
            /// Пробелы перед знаком равенства
            Skipper(.horizontal)
            
            /// Знак присваивания
            "="
            
            /// Пробелы после знака равенства
            Skipper(.horizontal)
            
            /// Правая часть — выражение
            ExpressionParser()
            
            /// Пробелы перед `;`
            Skipper(.horizontal)
            
            /// Завершающая точка с запятой
            ";"
        }
        .map { reference, value in
            Statement.assignment(reference: reference, value: value)
        }
    }
}
