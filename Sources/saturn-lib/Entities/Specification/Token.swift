//
//  Token.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.03.2026.
//

import Foundation

/// A lexical token declaration with its matching rule
public struct Token {
    
    // MARK: - Type Entities
    
    public enum Value {
        
        // MARK: - Cases
        
        /// A fixed string the lexer matches literally `"..."`
        case literal(String)
        
        /// A regular expression the lexer uses to match a token
        case regex(NSRegularExpression)
    }
    
    // MARK: - Public Properties
    
    /// Token name as declared in `%tokens`
    public let name: String
    
    /// The matching rule that represents the token value
    public let value: Value
    
    // MARK: - Initializers
    
    public init(name: String, value: Value) {
        self.name = name
        self.value = value
    }
}
