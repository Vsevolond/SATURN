//
//  LRItem.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 25.05.2026.
//

import Foundation

/// LR(0)-пункт: номер продукции с отмеченной позицией точки в правой части
public struct LRItem: Hashable {
    
    // MARK: - Public Properties
    
    /// Номер продукции
    public let production: Int
    
    /// Позиция точки — число распознанных символов правой части
    public let position: Int
}
