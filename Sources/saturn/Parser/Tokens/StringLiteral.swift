//
//  StringLiteral.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

/// Парсит строковый литерал в двойных кавычках: `"..."`
/// Поддерживает экранирование `\"` и `\\`
struct StringLiteral: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, String> {
        Parse {
            /// Открывающая кавычка
            "\""
            
            /// Содержимое строки: чередование экранированных и обычных фрагментов
            Many(into: "") { (result: inout String, output: String) in
                result += output
                
            } element: {
                OneOf {
                    /// Экранированная кавычка → литеральная `"`
                    Parse { "\\\"" }.map { "\"" }
                    
                    /// Экранированный обратный слэш → литеральный `\`
                    Parse { "\\\\" }.map { "\\" }
                    
                    /// Обычный фрагмент без кавычек и слэшей
                    Prefix(1...) { $0 != "\"" && $0 != "\\" }
                        .map { String($0) }
                }
            }
            
            /// Закрывающая кавычка
            "\""
        }
    }
}
