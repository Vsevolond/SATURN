//
//  LRAutomaton.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 25.05.2026.
//

import Foundation

/// Канонический набор LR(0)-состояний и переходов между ними
public struct LRAutomaton {
    
    // MARK: - Public Properties
    
    /// Состояния в порядке построения, нулевое — стартовое
    public let states: [Set<LRItem>]
    
    /// Переходы между состояниями
    public let transitions: [LRTransition]
    
    // MARK: - Private Properties
    
    private let grammar: NumberedGrammar
    
    // MARK: - Initializers
    
    init(_ grammar: NumberedGrammar) {
        self.grammar = grammar
        
        let (states, transitions) = grammar.build()
        
        self.states = states
        self.transitions = transitions
    }
}

// MARK: - Private Extensions

private extension NumberedGrammar {
    
    // MARK: - Internal Methods
    
    /// Строит канонический набор состояний и переходов обходом в ширину
    func build() -> (states: [Set<LRItem>], transitions: [LRTransition]) {
        /// Стартовое состояние — замыкание пункта продукции аксиомы (номер 0)
        let item = LRItem(production: 0, position: 0)
        let start = closure([item])
        
        var states = [start]
        var index = [start : 0]
        
        var transitions: [LRTransition] = []
        var queue = [start]
        
        /// Пока есть необработанные состояния — раскрываем их переходы
        while !queue.isEmpty {
            let items = queue.removeFirst()
            
            guard let from = index[items] else { continue }
            
            /// Для каждого символа после точки строим целевое состояние
            for symbol in symbolsAfterDot(items) {
                let next = goto(items, symbol)
                
                guard !next.isEmpty else { continue }
                
                /// Ранее не встречавшееся состояние получает новый номер
                if index[next] == nil {
                    index[next] = states.count
                    
                    states.append(next)
                    queue.append(next)
                }
                
                if let to = index[next] {
                    let transition = LRTransition(
                        from: from,
                        symbol: symbol,
                        to: to
                    )
                    
                    transitions.append(transition)
                }
            }
        }
        
        return (states, transitions)
    }
    
    // MARK: - Private Methods
    
    /// Замыкание множества пунктов
    ///
    /// Если точка стоит перед нетерминалом `B`, в множество добавляются
    /// пункты `[B → ·v]` для всех продукций `B`, и так до насыщения
    private func closure(_ items: Set<LRItem>) -> Set<LRItem> {
        var result = items
        var changed = true
        
        /// Повторяем, пока добавляются новые пункты
        while changed {
            changed = false
            
            for item in result {
                let rhs = productions[item.production].rhs
                
                /// Точка должна стоять перед нетерминалом
                guard item.position < rhs.count,
                      case .nonterminal(let name) = rhs[item.position]
                else {
                    continue
                }
                
                /// Добавляем начальные пункты всех продукций этого нетерминала
                for production in productionsByLeft[name] ?? [] {
                    let fresh = LRItem(production: production.id, position: 0)
                    
                    if result.insert(fresh).inserted { changed = true }
                }
            }
        }
        
        return result
    }
    
    /// Переход: сдвиг точки через символ во всех подходящих пунктах и замыкание
    private func goto(_ items: Set<LRItem>, _ symbol: GrammarSymbol) -> Set<LRItem> {
        var moved: Set<LRItem> = []
        
        for item in items {
            let rhs = productions[item.production].rhs
            
            /// Точка перед нужным символом — сдвигаем ее на один
            if item.position < rhs.count, rhs[item.position] == symbol {
                let item = LRItem(
                    production: item.production,
                    position: item.position + 1
                )
                
                moved.insert(item)
            }
        }
        
        return moved.isEmpty ? [] : closure(moved)
    }
    
    /// Символы, стоящие сразу после точки хотя бы в одном пункте состояния, в порядке их первого появления
    private func symbolsAfterDot(_ items: Set<LRItem>) -> [GrammarSymbol] {
        var result: [GrammarSymbol] = []
        var seen: Set<GrammarSymbol> = []
        
        /// Сортировка фиксирует порядок символов и делает построение детерминированным
        for item in items.sorted(
            by: { ($0.production, $0.position) < ($1.production, $1.position) }
        ) {
            let rhs = productions[item.production].rhs
            
            if item.position < rhs.count {
                let symbol = rhs[item.position]
                
                /// Каждый символ берем один раз
                if seen.insert(symbol).inserted { result.append(symbol) }
            }
        }
        
        return result
    }
}
