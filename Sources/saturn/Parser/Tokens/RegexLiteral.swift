//
//  RegexLiteral.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

/// Парсит литерал регулярного выражения: `/.../`
/// Внутри `\/` экранирует символ `/`, остальное передается в шаблон как есть
struct RegexLiteral: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, String> {
        Parse {
            /// Открывающая косая черта
            "/"
            
            /// Тело шаблона: экранированные `/` + обычные куски
            Many(into: "") { (result: inout String, output: String) in
                result += output
                
            } element: {
                OneOf {
                    /// Экранированная косая → литеральная `/` в шаблоне
                    Parse { "\\/" }.map { "/" }
                    
                    /// Обычный фрагмент без некэшированной `/`
                    Prefix(1...) { $0 != "/" }.map(String.init)
                }
            }
            
            /// Закрывающая косая черта
            "/"
        }
    }
}
