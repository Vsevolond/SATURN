//
//  Action.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 29.03.2026.
//

/// A semantic action attached to one alternative of a grammar rule
public enum Action {
    
    // MARK: - Cases
    
    /// `/ <method name>`
    /// Arguments are taken implicitly from typed elements of the alternative in order
    case call(method: String)
    
    /// `{ <statement>; ... }`
    /// An explicit list of statements executed when alternative is matched
    case block(statements: [Statement])
}
