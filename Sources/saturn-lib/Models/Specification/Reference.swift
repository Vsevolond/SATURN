//
//  Reference.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 30.03.2026.
//

/// A reference to a symbol attribute inside a semantic action
public struct Reference {
    
    // MARK: - Public Properties
    
    /// Symbol position in the rule (`$0`, `$1`, ...)
    public let target: Int
    
    /// Attribute name referenced to
    public let attribute: String
    
    /// Index chain when the attribute is an array: `.<attribute>[i][j]...`
    /// Empty for non-array attributes
    public let subscripts: [Expression]
    
    // MARK: - Initializers
    
    public init(
        target: Int,
        attribute: String,
        subscripts: [Expression] = []
    ) {
        self.target = target
        self.attribute = attribute
        self.subscripts = subscripts
    }
}
