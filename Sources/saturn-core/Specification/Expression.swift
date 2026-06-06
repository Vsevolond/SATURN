//
//  Expression.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 30.03.2026.
//

/// Выражение, вычисляющее значение, внутри семантического действия
public indirect enum Expression: Equatable {
    
    // MARK: - Cases
    
    /// Целочисленный литерал
    case int(Int)
    
    /// Вещественный литерал
    case float(Double)
    
    /// Строковый литерал
    case string(String)
    
    /// Булевый литерал
    case bool(Bool)
    
    /// Ссылка на атрибут
    case attribute(reference: Reference)
    
    /// Бинарное арифметическое выражение
    case binary(left: Expression, operation: Operator, right: Expression)
    
    /// Вызов метода с возвращаемым значением
    case call(method: String, arguments: [Expression])
}
