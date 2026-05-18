//
//  Attribute.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.03.2026.
//

/// A typed attribute declaration bound to a grammar symbol
public struct Attribute {
    
    // MARK: - Type Entities
    
    public enum Kind {
        
        // MARK: - Cases
        
        /// Attribute is computed from children
        case synthesized
        
        /// Attribute is passed down from parent
        case inherited
    }
    
    // MARK: - Public Properties
    
    /// The property (name + type) this attribute describes
    public let property: Property
    
    /// Name of the symbol this attribute belongs to
    public let target: String
    
    /// The type of the attribute
    public let type: Kind
    
    // MARK: - Initializers
    
    public init(
        property: Property,
        target: String,
        type: Kind = .synthesized
    ) {
        self.property = property
        self.target = target
        self.type = type
    }
}
