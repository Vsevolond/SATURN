//
//  Term.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.03.2026.
//

/// A terminal symbol corresponding to a declared token
public struct Term: Symbol {
    
    // MARK: - Public Properties
    
    /// Token name this terminal refers to
    public let name: String
    
    /// Indicates that the instance is a terminal
    public var isTerm: Bool { true }
    
    // MARK: - Initializers
    
    public init(name: String = "") { self.name = name }
}
