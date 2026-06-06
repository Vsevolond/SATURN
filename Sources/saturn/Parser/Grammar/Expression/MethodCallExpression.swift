//
//  MethodCallExpression.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Вызов метода в позиции выражения
struct MethodCallExpression: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, Expression> {
        MethodCall().map { name, arguments in
            Expression.call(method: name, arguments: arguments)
        }
    }
}
