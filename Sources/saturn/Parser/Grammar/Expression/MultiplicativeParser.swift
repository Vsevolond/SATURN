//
//  MultiplicativeParser.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Умножение и деление — внутренний уровень приоритета
struct MultiplicativeParser: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, Expression> {
        Parse {
            /// Левый операнд — атом
            TermParser()
            
            /// Хвост — пары «оператор + правый операнд», возможно пустой
            Many {
                Parse {
                    Skipper()
                    
                    OneOf {
                        "*".map { Operator.mul }
                        "/".map { Operator.div }
                    }
                    
                    Skipper()
                    
                    TermParser()
                }
            }
        }
        .map { head, tail in
            /// Сворачиваем хвост слева направо для левой ассоциативности
            tail.reduce(head) { lhs, pair in
                .binary(left: lhs, operation: pair.0, right: pair.1)
            }
        }
    }
}
