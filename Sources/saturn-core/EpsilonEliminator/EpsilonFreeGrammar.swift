//
//  EpsilonFreeGrammar.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 25.05.2026.
//

import Foundation

/// Результат устранения ε-правил
public struct EpsilonFreeGrammar {
    
    // MARK: - Public Properties
    
    /// Грамматика без ε-правил
    public let value: ExpandedGrammar
    
    /// Принимает ли язык пустую цепочку
    public let acceptsEmpty: Bool
}
