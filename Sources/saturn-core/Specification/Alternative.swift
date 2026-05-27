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
    
    /// Позиции выпавших обнуляемых символов в исходной правой части
    /// По этим меткам свертка дерева восстанавливает исходную нумерацию символов правила
    public let dropped: [DroppedSymbol]
    
    // MARK: - Initializers
    
    public init(
        elements: [Production] = [],
        actions: [Statement] = [],
        dropped: [DroppedSymbol] = []
    ) {
        self.elements = elements
        self.actions = actions
        self.dropped = dropped
    }
    
    public init(
        elements: [Production] = [],
        actions: [Statement]? = nil,
        dropped: [DroppedSymbol] = []
    ) {
        self.elements = elements
        self.actions = actions ?? []
        self.dropped = dropped
    }
}

// MARK: - Extensions

extension Alternative {
    
    // MARK: - Type Entities
    
    /// Выпавший при устранении ε обнуляемый символ правой части
    public struct DroppedSymbol: Equatable {
        
        // MARK: - Public Properties
        
        /// Исходный индекс символа в правой части до удаления
        public let position: Int
        
        /// Имя символа — для сахара это ключ в карте развертки
        public let name: String
        
        /// Служебный ли это нетерминал развертки сахара
        public let isSugar: Bool
    }
}
