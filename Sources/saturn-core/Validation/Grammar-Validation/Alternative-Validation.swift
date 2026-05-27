//
//  Alternative-Validation.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 21.05.2026.
//

import Foundation

extension Specification {
    
    // MARK: - Type Entities
    
    /// Вид обертки группировки
    enum Wrapper {
        case array /// repeat(...)
        case optional /// optional[...] или хвост repeat[...]
    }

    /// Символ альтернативы в плоской нумерации
    struct FlatSymbol {
        let name: String /// имя токена или нетерминала
        let wrappers: [Wrapper] /// обертки изнутри наружу
        let isToken: Bool /// токен или нетерминал
    }

    /// Контекст одной альтернативы
    struct Context {
        let nonterm: Nonterm /// левая часть, $0
        let symbols: [FlatSymbol] /// правая часть, $1..n
    }
    
    // MARK: - Internal Methods
    
    /// Альтернатива: валидация выражений и полнота
    func validateAlternative(_ alternative: Alternative, of nonterm: Nonterm) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        let symbols = flatten(alternative.elements)
        let context = Context(nonterm: nonterm, symbols: symbols)
        
        for statement in alternative.actions {
            errors += validateStatement(statement, in: context)
        }
        
        return errors
    }
    
    // MARK: - Private Methods
    
    /// Разворачивает элементы альтернативы в плоский список с обертками
    func flatten(_ productions: [Production], wrappers: [Wrapper] = []) -> [FlatSymbol] {
        var result: [FlatSymbol] = []
        
        for production in productions {
            switch production {
            case .term(let name):
                let symbol = FlatSymbol(name: name, wrappers: wrappers, isToken: true)
                result.append(symbol)
                
            case .nonterm(let nonterm):
                let symbol = FlatSymbol(name: nonterm.name, wrappers: wrappers, isToken: false)
                result.append(symbol)
                
            case let .repeat(nested, optional):
                /// repeat(...) -> array, repeat[...] -> optional + array
                var inner: [Wrapper] = [.array]
                if optional { inner = inner + [.optional] }
                
                result += flatten(nested, wrappers: inner + wrappers)
                
            case .optional(let nested):
                /// optional — внешняя относительно nested,
                /// но внутренняя относительно уже накопленных wrappers
                result += flatten(nested, wrappers: [.optional] + wrappers)
            }
        }
        
        return result
    }
}
