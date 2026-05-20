//
//  MethodCall.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Парсит вызов метода вида `name(arg1, arg2, ...)`
struct MethodCall: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, (String, [Expression])> {
        Parse {
            /// Имя метода
            BaseIdent(form: .mixed)
            
            /// Пробелы перед открывающей скобкой
            Skipper(.horizontal)
            
            /// Открывающая скобка
            "("
            
            /// Пробелы внутри скобок
            Skipper()
            
            /// Список аргументов через запятую, может быть пустым
            Many {
                ExpressionParser()
                
            } separator: {
                Skipper(.horizontal)
                ","
                Skipper()
            }
            
            /// Пробелы перед закрывающей скобкой
            Skipper()
            
            /// Закрывающая скобка
            ")"
        }
    }
}
