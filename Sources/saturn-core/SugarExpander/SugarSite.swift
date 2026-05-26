//
//  SugarSite.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 24.05.2026.
//

import Foundation

/// Описание служебного нетерминала, порожденного разверткой сахара
public struct SugarSite: Equatable {
    
    // MARK: - Public Properties
    
    /// Тип породившей конструкции
    public let type: SugarType
    
    /// Число символов в одном вхождении группы
    public let arity: Int
}
