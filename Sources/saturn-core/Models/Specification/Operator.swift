//
//  Operator.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 30.03.2026.
//

/// Бинарный арифметический оператор, используемый в выражениях
public enum Operator: Equatable {
    
    // MARK: - Cases
    
    /// Сложение: `+`
    case add
    
    /// Вычитание: `-`
    case sub
    
    /// Умножение: `*`
    case mul
    
    /// Деление: `/`
    case div
}
