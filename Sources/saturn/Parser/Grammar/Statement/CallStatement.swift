//
//  CallStatement.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Парсит вызов метода: `name(args);`
struct CallStatement: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, Statement> {
        Parse {
            /// Сам вызов метода
            MethodCall()
            
            /// Пробелы перед `;`
            Skipper(.horizontal)
            
            /// Завершающая точка с запятой
            ";"
        }
        .map { name, arguments in
            Statement.call(method: name, arguments: arguments)
        }
    }
}
