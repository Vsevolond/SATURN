//
//  Nonterm.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.03.2026.
//

/// Нетерминальный символ со своими альтернативами вывода
public final class Nonterm: Equatable {
    
    // MARK: - Public Properties
    
    /// Имя нетерминала
    public let name: String
    
    /// Все альтернативы вывода нетерминала в порядке объявления
    public var disclosures: [Alternative] { _disclosures }
    
    // MARK: - Internal Properties
    
    /// Все альтернативы вывода нетерминала в порядке объявления (изменяемое)
    private(set) var _disclosures: [Alternative] = []
    
    // MARK: - Initializers
    
    public init(name: String) { self.name = name }
    
    // MARK: - Type Methods
    
    /// Нетерминалы сравниваются по имени
    public static func == (lhs: Nonterm, rhs: Nonterm) -> Bool {
        lhs.name == rhs.name
    }
}

// MARK: - Extensions

extension Nonterm {
    
    // MARK: - Internal Methods
    
    /// Добавляет новую альтернативу к списку альтернатив нетерминала
    public func add(_ alternative: Alternative) {
        guard !disclosures.contains(alternative) else { return }
        
        _disclosures.append(alternative)
    }
    
    /// Добавляет список альтернатив к текущим альтернативам нетерминала
    public func add(_ alternatives: [Alternative]) {
        alternatives.forEach { add($0) }
    }
}
