//
//  Alternative.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 29.03.2026.
//

/// Одна альтернатива правила грамматики с семантическими действиями
public struct Alternative: Equatable {
    
    // MARK: - Public Properties
    
    /// Последовательность элементов правой части правила
    public let elements: [Production]
    
    /// Последовательность семантических действий
    public let actions: [Statement]
    
    // MARK: - Initializers
    
    public init(
        elements: [Production] = [],
        actions: [Statement] = []
    ) {
        self.elements = elements
        self.actions = actions
    }
    
    public init(
        elements: [Production] = [],
        actions: [Statement]? = nil
    ) {
        self.elements = elements
        self.actions = actions ?? []
    }
}
