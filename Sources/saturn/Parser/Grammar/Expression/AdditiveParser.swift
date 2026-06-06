//
//  AdditiveParser.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Сложение и вычитание — внешний уровень приоритета
struct AdditiveParser: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, Expression> {
        Parse {
            /// Левый операнд — выражение более высокого приоритета
            MultiplicativeParser()
            
            /// Хвост — пары «оператор + правый операнд», возможно пустой
            Many {
                Parse {
                    Skipper()
                    
                    OneOf {
                        "+".map { Operator.add }
                        "-".map { Operator.sub }
                    }
                    
                    Skipper()
                    
                    MultiplicativeParser()
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
