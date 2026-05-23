//
//  Methods-Validation.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 21.05.2026.
//

import Foundation

extension Specification {
    
    // MARK: - Internal Methods
    
    /// Методы: типы аргументов и возврата опираются на известные
    func validateMethodTypes() -> [SemanticError] {
        var errors: [SemanticError] = []
        
        for (name, method) in methods {
            /// Проверка типов аргументов
            for type in method.arguments {
                if let unknown = unknownBaseType(of: type) {
                    let error = SemanticError.unknownArgumentType(
                        name: unknown,
                        method: name
                    )
                    
                    errors.append(error)
                }
            }
            
            /// Проверка возвращаемого типа
            if let returnType = method.returnType,
               let unknown = unknownBaseType(of: returnType)
            {
                let error = SemanticError.unknownReturnType(
                    name: unknown,
                    method: name
                )
                
                errors.append(error)
            }
        }
        
        return errors
    }
}
