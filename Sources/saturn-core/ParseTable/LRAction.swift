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
    
    /// Свертка по продукции с указанным номером
    case reduce(Int)
    
    /// Прием входа
    case accept
}
