//
//  LRTransition.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 25.05.2026.
//

import Foundation

/// Переход автомата: из состояния по символу в состояние
public struct LRTransition: Equatable {
    
    // MARK: - Public Properties
    
    public let from: Int
    public let symbol: GrammarSymbol
    public let to: Int
}
