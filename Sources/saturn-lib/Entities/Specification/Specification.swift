//
//  Specification.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.03.2026.
//

/// A complete grammar specification parsed from a `.spec` source file
public struct Specification {
    
    // MARK: - Public Properties
    
    /// All declared tokens in `%tokens` keyed by token name
    public var tokens: [String : Token]
    
    /// User-defined type names declared in `%types`
    public var types: Set<String>
    
    /// Attribute definitions in `%attributes` grouped by symbol name
    public var attributes: [String : [Attribute]]
    
    /// All declared methods in `%methods` keyed by mehod name
    public var methods: [String : Method]
    
    /// The start nonterminal of the grammar
    public var axiome: Nonterm
    
    // MARK: - Initializers
    
    public init(
        tokens: [String : Token] = [:],
        types: Set<String> = [],
        attributes: [String : [Attribute]] = [:],
        methods: [String : Method] = [:],
        axiome: Nonterm
    ) {
        self.tokens = tokens
        self.types = types
        self.attributes = attributes
        self.methods = methods
        self.axiome = axiome
    }
}
