//
//  ParseTable.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 25.05.2026.
//

import Foundation

/// Таблица управления LR-анализатором для GLR
///
/// Заполнение по правилам SLR(1):
/// - перенос — для терминала после точки
/// - свертка по `A → a` — для каждого терминала из FOLLOW(A) на завершенном пункте
/// - прием — на завершенном пункте продукции аксиомы при конце входа
///
/// Ячейка ACTION хранит список действий: конфликты не отбрасываются, их параллельно обрабатывает GLR
public struct ParseTable {
    
    // MARK: - Public Properties
    
    /// ACTION: (состояние, терминал или конец входа) → список действий
    public let action: [Int: [GrammarSymbol: [LRAction]]]
    
    /// GOTO: (состояние, нетерминал) → состояние
    public let goto: [Int: [String: Int]]
    
    /// Продукции грамматики
    public let productions: [NumberedProduction]
    
    /// Принимает ли язык пустую цепочку
    public let acceptsEmpty: Bool
    
    // MARK: - Initializers
    
    /// Строит таблицу по ε-свободной грамматике
    public init(_ grammar: ExpandedGrammar, acceptsEmpty: Bool) throws {
        /// Нумеруем продукции, строим автомат и множества FOLLOW
        let numbered = try NumberedGrammar(grammar)
        let automaton = LRAutomaton(numbered)
        let follow = numbered.follow
        
        var action: [Int: [GrammarSymbol: [LRAction]]] = [:]
        var goto: [Int: [String: Int]] = [:]
        
        /// Переходы: терминал → перенос в ACTION, нетерминал → запись в GOTO
        for transition in automaton.transitions {
            switch transition.symbol {
            case .terminal, .end:
                append(
                    .shift(transition.to),
                    to: &action,
                    state: transition.from,
                    on: transition.symbol
                )
                
            case .nonterminal(let name):
                goto[transition.from, default: [:]][name] = transition.to
            }
        }
        
        /// Завершенные пункты: свертки по FOLLOW и прием для аксиомы
        for (state, items) in automaton.states.enumerated() {
            for item in items {
                let production = numbered.productions[item.production]
                
                /// Незавершенный пункт свертки не дает
                guard item.position == production.rhs.count else { continue }
                
                /// Завершенный пункт продукции аксиомы (номер 0) — прием по концу входа
                if production.id == 0 {
                    append(
                        .accept,
                        to: &action,
                        state: state,
                        on: .end
                    )
                    
                    continue
                }
                
                /// Свертка по этой продукции для каждого терминала из FOLLOW левой части
                for symbol in follow[production.lhs] ?? [] {
                    append(
                        .reduce(production.id),
                        to: &action,
                        state: state,
                        on: symbol
                    )
                }
            }
        }
        
        self.action = action
        self.goto = goto
        self.productions = numbered.productions
        self.acceptsEmpty = acceptsEmpty
    }
    
    // MARK: - Public Methods
    
    /// Список действий для состояния и символа; пустой, если ячейка пуста
    public func actions(state: Int, symbol: GrammarSymbol) -> [LRAction] {
        guard let actions = action[state] else { return [] }
        return actions[symbol] ?? []
    }
    
    /// Целевое состояние перехода по нетерминалу или `nil`
    public func nextState(state: Int, nonterminal: String) -> Int? {
        guard let states = goto[state] else { return nil }
        return states[nonterminal]
    }
}

// MARK: - Private Methods

/// Добавляет действие в ячейку без отбора, не допуская дублей
///
/// Дубль возникает, когда одно действие попадает в ячейку по нескольким путям
/// конфликт же — разные действия — сохраняется целиком для GLR
private func append(
    _ action: LRAction,
    to table: inout [Int: [GrammarSymbol: [LRAction]]],
    state: Int,
    on symbol: GrammarSymbol
) {
    var cell = table[state].flatMap { $0[symbol] } ?? []
    
    guard !cell.contains(action) else { return }
    
    cell.append(action)
    table[state, default: [:]][symbol] = cell
}
