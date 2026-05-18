//
//  Method.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.03.2026.
//

/// A method declaration available for use in semantic actions
public struct Method {
    
    // MARK: - Public Properties
    
    /// Name of the method as it appears in semantic actions
    public let name: String
    
    /// Return type of the method, `nil` for `void`
    public let returnType: Property.Kind?
    
    /// Ordered list of parameter types
    public let arguments: [Property.Kind]
    
    // MARK: - Initializers
    
    public init(
        name: String,
        returnType: Property.Kind? = nil,
        arguments: [Property.Kind] = []
    ) {
        self.name = name
        self.returnType = returnType
        self.arguments = arguments
    }
}
