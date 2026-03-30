//
//  Nonterm.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.03.2026.
//

/// A nonterminal symbol with its production alternatives
public final class Nonterm: Symbol {
    
    // MARK: - Public Properties
    
    public let name: String
    
    public var isTerm: Bool { false }
    
    // MARK: - Internal Properties
    
    /// All production alternatives for this nonterminal in declaration order
    private(set) var disclosures: [Alternative] = []
    
    /// Nonterminals that reference this one in their productions
    private(set) var parents: Set<Nonterm> = []
    
    // MARK: - Initializers
    
    public init(name: String = "") { self.name = name }
}
