//
//  Symbol.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.03.2026.
//

/// A named element of a grammar — either a terminal or a nonterminal
public protocol Symbol: Hashable {
    
    // MARK: - Properties
    
    /// The name of the symbol as it appears in the grammar
    var name: String { get }
    
    /// `true` for terminals, `false` for nonterminals
    var isTerm: Bool { get }
    
    /// `true` when the symbol represents an empty symbol
    var isEmpty: Bool { get }
}

// MARK: - Extensions

public extension Symbol {
    
    // MARK: - Public Properties
    
    /// `true` when the symbol has no name
    var isEmpty: Bool { name.isEmpty }
    
    /// `true` for nonterminals, inverse of `isTerm`
    var isNonterm: Bool { !isTerm }
}

public extension Symbol {
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name
    }
}
