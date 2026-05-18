//
//  Nonterm.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.03.2026.
//

/// A nonterminal symbol with its production alternatives
public final class Nonterm {
    
    // MARK: - Public Properties
    
    /// Name this nonterminal refers to
    public let name: String
    
    // MARK: - Internal Properties
    
    /// All production alternatives for this nonterminal in declaration order
    private(set) var disclosures: [Alternative] = []
    
    // MARK: - Initializers
    
    public init(name: String) { self.name = name }
}

// MARK: - Extensions

extension Nonterm {
    
    // MARK: - Internal Methods
    
    /// Appends new alternative to all nonterminal disclosures
    func add(_ alternative: Alternative) {
        disclosures.append(alternative)
    }
}
