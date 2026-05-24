//
//  Specification-Validation.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 21.05.2026.
//

import Foundation

extension Specification {
    
    // MARK: - Public Methods
    
    /// Выполняет полный семантический анализ спецификации
    /// Возвращает все найденные ошибки
    public func validate() -> [SemanticError] {
        var errors: [SemanticError] = []
        
        /// Валидация объявлений токенов
        let tokensValidation = validateTokens()
        errors += tokensValidation.errors
        
        /// Валидация объявлений атрибутов
        errors += validateAttributes(tokensValidation.tokens)
        
        /// Валидация объявлений методов
        errors += validateMethodTypes()
        
        /// Валидация грамматики
        errors += validateGrammar(tokensValidation.tokens)
        
        return errors
    }
    
    // MARK: - Internal Porperties
    
    static let builtinTokenAttribute = "text"
}
