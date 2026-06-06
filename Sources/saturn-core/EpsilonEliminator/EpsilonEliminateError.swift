//
//  EpsilonEliminateError.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 25.05.2026.
//

import Foundation

/// Ошибки, возникающие при устранении ε-правил
public enum EpsilonEliminateError: Error {
    
    /// Синтаксический сахар должен быть развернут до устранения ε-правил
    case sugarNotExpanded
    
    /// Аксиома не найдена
    case axiomNotFound
}

// MARK: - Extensions

extension EpsilonEliminateError: LocalizedError {
    
    // MARK: - Public Properties
    
    /// Описание ошибки устранения ε-правил
    public var errorDescription: String? {
        switch self {
        case .sugarNotExpanded:
            return "Синтаксический сахар должен быть развернут до устранения ε-правил"
            
        case .axiomNotFound:
            return "Аксиома грамматики не найдена"
        }
    }
}
