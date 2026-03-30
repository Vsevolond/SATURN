//
//  Expression.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 30.03.2026.
//

/// A value expression used inside semantic action statements
public indirect enum Expression {
    
    // MARK: - Cases
    
    /// An integer literal
    case int(Int)
    
    /// A floating-point literal
    case float(Double)
    
    /// A string literal
    case string(String)
    
    /// A boolean literal
    case bool(Bool)
    
    /// An attribute reference
    case attribute(reference: Reference)
    
    /// A binary arithmetic expression
    case binary(left: Expression, operation: Operator, right: Expression)
    
    /// A method call with return value
    case call(method: String, arguments: [Expression])
}
