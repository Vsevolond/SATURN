//
//  AttributeReference.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Парсит ссылку на атрибут: `$N.attr` или `$N.attr[expr][expr]...`
struct AttributeReference: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, Reference> {
        Parse {
            /// Префикс позиционной ссылки
            "$"
            
            /// Номер позиции символа в правиле
            UInt.parser()
            
            /// Точка-разделитель позиции и имени атрибута
            "."
            
            /// Имя атрибута
            BaseIdent(form: .mixed)
            
            /// Цепочка индексов для массивов: `[expr][expr]...`
            Many {
                Parse {
                    "["
                    Skipper()
                    ExpressionParser()
                    Skipper()
                    "]"
                }
            }
        }
        .map { position, attribute, subscripts in
            Reference(target: position, attribute: attribute, subscripts: subscripts)
        }
    }
}
