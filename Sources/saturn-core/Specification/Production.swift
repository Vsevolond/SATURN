//
//  Production.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 29.03.2026.
//

/// Элемент правой части альтернативы правила грамматики
public indirect enum Production: Equatable{
    
    // MARK: - Cases
    
    /// Терминальный символ
    case term(String)
    
    /// Нетерминальный символ
    case nonterm(Nonterm)
    
    /// Повторение один/ноль и более раз: `%rep ( ... )`, `%rep [ ... ]`
    case `repeat`(productions: [Production], optional: Bool)
    
    /// Опциональная группа: `[ ... ]`
    case optional(productions: [Production])
}
