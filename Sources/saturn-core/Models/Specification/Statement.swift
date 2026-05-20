//
//  Statement.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 30.03.2026.
//

/// Одиночный исполняемый оператор внутри блока семантического действия
public enum Statement: Equatable {
    
    // MARK: - Cases
    
    /// Самостоятельный вызов метода, возвращаемое значение игнорируется
    case call(method: String, arguments: [Expression])
    
    /// Присваивание атрибуту
    case assignment(reference: Reference, value: Expression)
}
