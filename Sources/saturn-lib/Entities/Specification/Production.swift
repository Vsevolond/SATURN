//
//  Production.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 29.03.2026.
//

/// An element on the right-hand side of a grammar rule alternative
public indirect enum Production {
    
    // MARK: - Cases
    
    /// A terminal `Term` or nonterminal `Nonterm` symbol
    case symbol(any Symbol)
    
    /// Zero or more repetition: `%rep ( ... )`
    case `repeat`(productions: [Production])
    
    /// Optional group: `[ ... ]`
    case optional(productions: [Production])
}
