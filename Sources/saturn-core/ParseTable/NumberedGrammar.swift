//
//  NumberedGrammar.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 25.05.2026.
//

import Foundation

/// Грамматика с занумерованными продукциями, готовая для построения автомата
public struct NumberedGrammar {
    
    // MARK: - Public Properties
    
    /// Все продукции в порядке нумерации, продукция аксиомы имеет номер 0
    public let productions: [NumberedProduction]
    
    /// Имя аксиомы
    public let axiom: String
    
    /// Имена всех нетерминалов
    public let nonterminals: Set<String>
    
    /// Имена всех терминалов
    public let terminals: Set<String>
    
    /// Продукции, сгруппированные по левой части, для замыкания пунктов
    public let productionsByLeft: [String: [NumberedProduction]]
    
    // MARK: - Initializers
    
    /// Нумерует продукции грамматики, ставя аксиому первой
    public init(_ grammar: ExpandedGrammar) throws {
        var productions: [NumberedProduction] = []
        var nonterminals: Set<String> = []
        var terminals: Set<String> = []
        
        let names = Set(grammar.nonterms.map(\.name))
                
        /// Свежая аксиома `S' → axiom` с номером 0 — единственная точка приема
        let start = startName(taken: names)
        nonterminals.insert(start)
        
        let production = NumberedProduction(
            id: 0,
            lhs: start,
            rhs: [.nonterminal(grammar.axiom.name)]
        )
        productions.append(production)
        
        /// Аксиома обрабатывается первой — ее продукции получают младшие номера
        /// Продукция 0 стартовая
        let ordered = [grammar.axiom] + grammar.nonterms.filter { $0.name != grammar.axiom.name }
        
        for nonterm in ordered {
            nonterminals.insert(nonterm.name)
            
            for alternative in nonterm.disclosures {
                /// Переводим элементы правой части в символы грамматики
                let rhs = try alternative.elements.map { try $0.symbol }
                
                /// Собираем терминалы из правых частей
                for case let .terminal(name) in rhs { terminals.insert(name) }
                
                /// Номер продукции — ее текущая позиция в общем списке
                let production = NumberedProduction(
                    id: productions.count,
                    lhs: nonterm.name,
                    rhs: rhs
                )
                
                productions.append(production)
            }
        }
        
        self.axiom = start
        self.productions = productions
        self.nonterminals = nonterminals
        self.terminals = terminals
        
        /// Индекс по левой части — для замыкания пунктов в автомате
        self.productionsByLeft = Dictionary(
            grouping: productions,
            by: { $0.lhs }
        )
    }
}

// MARK: - Private Methods

/// Свободное имя для свежей стартовой аксиомы, не совпадающее с существующими
private func startName(taken nonterms: Set<String>) -> String {
    var name = "_Axiom"
    var index = 0
    
    while nonterms.contains(name) {
        name = "_Axiom_\(index)"
        index += 1
    }
    
    return name
}

// MARK: - Private Extensions

private extension Production {
    
    // MARK: - Internal Properties
    
    /// Переводит элемент правой части в символ грамматики
    var symbol: GrammarSymbol {
        get throws(EpsilonEliminateError) {
            switch self {
            case .term(let name):
                return .terminal(name)
                
            case .nonterm(let nonterm):
                return .nonterminal(nonterm.name)
                
            case .repeat, .optional:
                throw .sugarNotExpanded
            }
        }
    }
}
