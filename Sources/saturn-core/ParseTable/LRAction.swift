//
//  LRAction.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 25.05.2026.
//

import Foundation

/// Действие таблицы управления
public enum LRAction: Hashable {
    
    // MARK: - Cases
    
    /// Перенос: положить символ и перейти в состояние
    case shift(Int)
    
    /// Свёртка по продукции с указанным номером
    case reduce(Int)
    
    /// Приём входа
    case accept
}
