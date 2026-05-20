//
//  TermParser.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Атом выражения: литерал, ссылка на атрибут, вызов метода или скобки
struct TermParser: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, Expression> {
        Lazy {
            OneOf {
                /// Скобки — рекурсивный спуск к корневому выражению
                Parse {
                    "("
                    Skipper()
                    
                    ExpressionParser()
                    
                    Skipper()
                    ")"
                }
                
                /// Булевы литералы
                "true".map { Expression.bool(true) }
                "false".map { Expression.bool(false) }
                
                /// Ссылка на атрибут
                AttributeReference().map { Expression.attribute(reference: $0) }
                
                /// Числовой литерал — целое или вещественное
                Double.parser().map {
                    guard let value = Int(exactly: $0) else {
                        return Expression.float($0)
                    }
                    
                    return Expression.int(value)
                }
                
                /// Строковый литерал
                StringLiteral().map { Expression.string($0) }
                
                /// Вызов метода: `name(arg1, arg2, ...)`
                MethodCallExpression()
            }
        }
    }
}
