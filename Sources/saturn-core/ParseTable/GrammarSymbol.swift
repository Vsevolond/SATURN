//
//  GrammarSymbol.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 25.05.2026.
//

import Foundation

/// Символ грамматики в терминах построения LR-таблиц
public enum GrammarSymbol: Hashable {
    
    // MARK: - Cases
    
    /// Терминал с именем токена из секции токенов
    case terminal(String)
    
    /// Нетерминал с именем правила
    case nonterminal(String)
    
    /// Правый концевой маркер конца входа
    case end
}
