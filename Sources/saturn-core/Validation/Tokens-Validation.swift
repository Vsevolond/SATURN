//
//  Tokens-Validation.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 21.05.2026.
//

import Foundation

extension Specification {
    
    // MARK: - Private Methods
    
    /// Токены: уникальность имен и значений.
    func validateTokens() -> (tokens: Set<String>, errors: [SemanticError]) {
        var errors: [SemanticError] = []
        
        var names: Set<String> = []
        
        /// Проверка уникальности имен
        for token in tokens {
            if names.contains(token.name) {
                let error = SemanticError.duplicateTokenName(token.name)
                errors.append(error)
            }
            
            names.insert(token.name)
        }
        
        /// Проверка уникальности значений
        for i in tokens.indices {
            for j in tokens.indices where j > i && tokens[i].value == tokens[j].value {
                let error = SemanticError.duplicateTokenValue(
                    first: tokens[i].name,
                    second: tokens[j].name
                )
                
                errors.append(error)
            }
        }
        
        return (names, errors)
    }
}
