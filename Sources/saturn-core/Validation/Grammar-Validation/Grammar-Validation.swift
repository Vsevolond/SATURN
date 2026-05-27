//
//  Grammar-Validation.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 21.05.2026.
//

import Foundation

extension Specification {
    
    // MARK: - Internal Methods
    
    /// Известность терминалов и непустота альтернатив у достижимых нетерминалов
    func validateGrammar(_ uniqueTokens: Set<String>) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        var visited: Set<ObjectIdentifier> = []
        var stack: [Nonterm] = [axiom]
        
        while let nonterm = stack.popLast() {
            let id = ObjectIdentifier(nonterm)
            
            if visited.contains(id) { continue }
            visited.insert(id)
            
            /// Достижимый нетерминал без альтернатив
            if nonterm.disclosures.isEmpty {
                let error = ValidationError.emptyNonterm(name: nonterm.name)
                errors.append(error)
            }
            
            for alternative in nonterm.disclosures {
                /// Структура альтернативы — все терминалы объявлены
                for term in terms(in: alternative.elements) where !uniqueTokens.contains(term) {
                    let error = ValidationError.unknownTerm(name: term)
                    errors.append(error)
                }
                
                /// Блок действий и полнота
                errors += validateAlternative(alternative, of: nonterm)
                
                /// Заталкиваем дочерние нетерминалы для дальнейшего обхода
                for child in nonterms(in: alternative.elements) { stack.append(child) }
            }
        }
        
        return errors
    }
    
    // MARK: - Private Methods
    
    /// Все нетерминалы в продукциях, включая вложенные группы
    func nonterms(in productions: [Production]) -> [Nonterm] {
        var result: [Nonterm] = []
        
        for production in productions {
            switch production {
            case .term:
                continue
                
            case let .nonterm(nonterm):
                result.append(nonterm)
                
            case let .repeat(nested, _):
                result += nonterms(in: nested)
                
            case let .optional(nested):
                result += nonterms(in: nested)
            }
        }
        
        return result
    }

    /// Все терминалы в продукциях, включая вложенные группы
    func terms(in productions: [Production]) -> [String] {
        var result: [String] = []
        
        for production in productions {
            switch production {
            case let .term(name):
                result.append(name)
                
            case .nonterm:
                continue
                
            case let .repeat(nested, _):
                result += terms(in: nested)
                
            case let .optional(nested):
                result += terms(in: nested)
            }
        }
        return result
    }
}
