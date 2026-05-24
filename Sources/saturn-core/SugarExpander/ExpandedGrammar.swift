//
//  ExpandedGrammar.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 24.05.2026.
//

import Foundation

/// Грамматика без синтаксического сахара
public struct ExpandedGrammar {
    
    // MARK: - Public Properties
    
    /// Начальный нетерминал развернутой грамматики
    public let axiom: Nonterm
    
    /// Все нетерминалы грамматики:
    /// - сначала пользовательские в порядке первого достижения от аксиомы
    /// - затем служебные в порядке порождения
    public let nonterms: [Nonterm]
    
    /// Словарь имя → нетерминал для быстрого доступа
    public let nontermsByName: [String : Nonterm]
    
    // MARK: - Initializers
    
    init(axiom: Nonterm, nonterms: [Nonterm]) {
        self.axiom = axiom
        self.nonterms = nonterms
        
        self.nontermsByName = Dictionary(
            nonterms.map { ($0.name, $0) },
            uniquingKeysWith: { first, _ in first }
        )
    }
    
    // MARK: - Public Methods
    
    /// Возвращает нетерминал по имени или `nil`, если такого нет
    public subscript(name: String) -> Nonterm? { nontermsByName[name] }
}
