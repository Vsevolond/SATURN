//
//  Specification-ParseError.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import saturn_core

extension Specification {
    
    // MARK: - Type Entities
    
    /// Ошибки, возникающие при разборе файла спецификации
    enum ParseError: Error {
        
        // MARK: - Cases
        
        /// Шаблон регулярного выражения не удалось скомпилировать
        case invalidRegex(pattern: String, underlying: Error)
        
        /// Указанная аксиома не найдена в грамматике
        case invalidAxiom(name: String)
    }
}
