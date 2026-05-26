//
//  First-Follow.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 25.05.2026.
//

import Foundation

extension NumberedGrammar {
    
    // MARK: - Public Properties
    
    /// FOLLOW для всех нетерминалов по неподвижной точке
    ///
    /// В FOLLOW аксиомы входит конец входа `$`
    /// Для продукции `A → a B b` в FOLLOW(B) добавляется FIRST(b)
    /// Если `b` пуст, добавляется FOLLOW(A)
    public var follow: [String: Set<GrammarSymbol>] {
        var follow: [String: Set<GrammarSymbol>] = [:]
        
        /// Предзаполняем пустыми множествами
        for name in nonterminals { follow[name] = [] }
        
        /// Аксиому может сопровождать только конец входа
        follow[axiom] = [.end]
        
        /// Повторяем проходы, пока хоть одно множество растет
        var changed = true
        
        while changed {
            changed = false
            
            for production in productions {
                for (offset, symbol) in production.rhs.enumerated() {
                    /// FOLLOW определяется только для нетерминалов
                    guard case .nonterminal(let name) = symbol else { continue }
                    
                    /// Часть правой части правее текущего нетерминала
                    let tail = Array(production.rhs[(offset + 1)...])
                    
                    var addition: Set<GrammarSymbol> = []
                    
                    if let next = tail.first {
                        /// Хвост непуст: добавляем FIRST символа сразу за нетерминалом
                        var visited: Set<String> = []
                        addition = first(of: next, visited: &visited)
                        
                    } else {
                        /// Нетерминал в конце правой части: наследует FOLLOW левой части
                        addition = follow[production.lhs] ?? []
                    }
                    
                    /// Проверка роста множества
                    let before = follow[name].count ?? 0
                    follow[name].formUnion(addition)
                    
                    if follow[name].count != before { changed = true }
                }
            }
        }
        
        return follow
    }
    
    // MARK: - Public Methods
    
    /// FIRST одного символа в ε-свободной грамматике
    /// - Для терминала и конца входа — он сам
    /// - Для нетерминала — объединение FIRST первых символов всех его продукций
    public func first(
        of symbol: GrammarSymbol,
        visited: inout Set<String>
    ) -> Set<GrammarSymbol> {
        switch symbol {
        case .terminal, .end:
            return [symbol]
            
        case .nonterminal(let name):
            /// Защита от левой рекурсии: повторно в тот же нетерминал не входим
            guard visited.insert(name).inserted else { return [] }
            
            var result: Set<GrammarSymbol> = []
            
            for production in productionsByLeft[name] ?? [] {
                /// Грамматика ε-свободна — правая часть непуста, берем первый символ
                if let head = production.rhs.first {
                    let first = first(of: head, visited: &visited)
                    
                    result.formUnion(first)
                }
            }
            
            return result
        }
    }
}
