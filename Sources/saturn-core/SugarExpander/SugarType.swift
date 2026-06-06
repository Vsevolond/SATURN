//
//  SugarType.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 24.05.2026.
//

import Foundation

/// Тип конструкции синтаксического сахара, породившей служебный нетерминал
public enum SugarType: Equatable {
    
    // MARK: - Cases
    
    /// `%rep(...)` : атрибуты внутренних символов читаются как `array<T>`
    case repeatOneOrMore
    
    /// `%rep[...]` : атрибуты читаются как `optional<array<T>>`
    case repeatZeroOrMore
    
    /// `[...]` : атрибуты читаются как `optional<T>`
    case optional
}
