//
//  NumberedProduction.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 25.05.2026.
//

import Foundation

/// Продукция грамматики с присвоенным номером — глобальным индексом правила
public struct NumberedProduction: Equatable {
    
    // MARK: - Public Properties
    
    /// Глобальный номер продукции
    public let id: Int
    
    /// Левая часть — имя нетерминала
    public let lhs: String
    
    /// Правая часть — последовательность символов грамматики
    public let rhs: [GrammarSymbol]
    
    /// Позиции выпавших обнуляемых символов
    public let dropped: [Alternative.DroppedSymbol]
    
    // MARK: - Initializers
    
    init(
        id: Int,
        lhs: String,
        rhs: [GrammarSymbol],
        dropped: [Alternative.DroppedSymbol] = []
    ) {
        self.id = id
        self.lhs = lhs
        self.rhs = rhs
        self.dropped = dropped
    }
}
