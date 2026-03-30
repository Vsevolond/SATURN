//
//  Statement.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 30.03.2026.
//

/// A single executable statement inside a semantic action block
public enum Statement {
    
    // MARK: - Cases
    
    /// A standalone method call, return value discarded
    case call(method: String, arguments: [Expression])
    
    /// An assignment to an attribute
    case assignment(reference: Reference, value: Expression)
}
