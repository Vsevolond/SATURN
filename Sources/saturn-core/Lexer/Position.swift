//
//  Position.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 24.05.2026.
//

import Foundation

/// Позиция кодовой точки во входном тексте
public struct Position: Equatable, Sendable {
    
    // MARK: - Public Properties
    
    /// Номер строки, считая с единицы
    public let line: Int
    
    /// Номер столбца, считая с единицы
    public let column: Int
    
    /// Абсолютное смещение от начала текста в кодовых точках
    public let offset: Int
    
    // MARK: - Type Properties
    
    /// Начало входного текста
    static let start = Position(line: 1, column: 1, offset: 0)
}
