//
//  Production.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 29.03.2026.
//

/// An element on the right-hand side of a grammar rule alternative
public indirect enum Production {
    
    // MARK: - Cases
    
    /// A terminal `Term` symbol
    case term(Term)
    
    /// A nonterminal `Nonterm` symbol
    case nonterm(Nonterm)
    
    /// One/zero or more repetition: `%rep ( ... )`, `%rep [ ... ]`
    case `repeat`(productions: [Production], optional: Bool)
    
    /// Optional group: `[ ... ]`
    case optional(productions: [Production])
}
