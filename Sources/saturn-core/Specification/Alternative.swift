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
    
    /// Позиции выпавшего обнуляемого сахара в исходной правой части
    ///
    /// По этим меткам свёртка дерева восстанавливает пустой узел-повторение,
    /// сохраняя позиционную адресацию символов правила
    public let dropped: [DroppedSugar]
    
    // MARK: - Initializers
    
    public init(
        elements: [Production] = [],
        actions: [Statement] = [],
        dropped: [DroppedSugar] = []
    ) {
        self.elements = elements
        self.actions = actions
        self.dropped = dropped
    }
    
    public init(
        elements: [Production] = [],
        actions: [Statement]? = nil,
        dropped: [DroppedSugar] = []
    ) {
        self.elements = elements
        self.actions = actions ?? []
        self.dropped = dropped
    }
}

// MARK: - Extensions

extension Alternative {
    
    // MARK: - Type Entities
    
    /// Выпавший при устранении ε обнуляемый служебный нетерминал сахара
    public struct DroppedSugar: Equatable {
        
        // MARK: - Public Properties
        
        /// Исходный индекс символа в правой части до удаления
        public let position: Int
        
        /// Имя служебного нетерминала — ключ в карте развёртки
        public let name: String
    }
}
