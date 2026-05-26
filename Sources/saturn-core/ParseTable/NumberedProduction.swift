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
}
