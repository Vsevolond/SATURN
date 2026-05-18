//
//  Property.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.03.2026.
//

/// A named, typed field of a grammar symbol attribute
public struct Property {
    
    // MARK: - Type Entities
    
    public indirect enum Kind {
        
        // MARK: - Cases
        
        /// Built-in integer type
        case int
        
        /// Built-in floating-point type
        case float
        
        /// Built-in boolean type
        case bool
        
        /// Built-in string type
        case string
        
        /// A user-defined type declared in `%types`
        case custom(String)
        
        /// An array of another kind
        case array(Kind)
    }
    
    // MARK: - Public Properties
    
    /// Attribute name as declared
    public let name: String
    
    /// The type of this property
    public let type: Kind
    
    // MARK: - Initializers
    
    public init(name: String, type: Kind) {
        self.name = name
        self.type = type
    }
}
