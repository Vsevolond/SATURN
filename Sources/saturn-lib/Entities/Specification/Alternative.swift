//
//  Alternative.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 29.03.2026.
//

/// One production alternative of a grammar rule with an optional semantic action
public struct Alternative {
    
    // MARK: - Public Properties
    
    /// The sequence of grammar elements on the right side of the rule
    public let elements: [Production]
    
    /// Optional semantic action
    public let action: Action?
    
    // MARK: - Initializers
    
    public init(
        elements: [Production] = [],
        action: Action? = nil
    ) {
        self.elements = elements
        self.action = action
    }
}
