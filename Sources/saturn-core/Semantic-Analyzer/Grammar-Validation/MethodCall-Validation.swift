//
//  MethodCall-Validation.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 21.05.2026.
//

import Foundation

extension Specification {
    
    // MARK: - Internal Methods
    
    func validateMethodCall(
        method: String,
        arguments: [Expression],
        returnRequired: Bool,
        in context: Context
    ) -> (returnType: Property.Kind?, errors: [SemanticError]) {
        /// Проверка существования метода по имени
        guard let declaration = methods[method] else {
            let error = SemanticError.unknownMethod(name: method, nonterm: context.nonterm.name)
            return (nil, [error])
        }
        
        var errors: [SemanticError] = []
        
        /// Проверка соответствия количества аргументов
        if arguments.count != declaration.arguments.count {
            let error = SemanticError.argumentCountMismatch(
                method: method,
                expected: declaration.arguments.count,
                given: arguments.count,
                nonterm: context.nonterm.name
            )
            
            errors.append(error)
        }
        
        /// Проверка типов переданных аргументов
        for (index, argument) in arguments.enumerated() where index < declaration.arguments.count {
            let type = declaration.arguments[index]
            let result = inferType(argument, in: context)
            
            errors += result.errors
            
            /// Если тип переданного аргумента невозможно присвоить типу аргумента метода
            if let argumentType = result.type, !argumentType.assignable(to: type) {
                let error = SemanticError.argumentTypeMismatch(
                    method: method,
                    index: index,
                    expected: type.identifier,
                    given: argumentType.identifier,
                    nonterm: context.nonterm.name
                )
                
                errors.append(error)
            }
        }
        
        /// Если возвращаемый тип существует
        if let returnType = declaration.returnType {
            return (returnType, errors)
            
        } else {
            /// Если возвращаемый тип важен
            if returnRequired {
                let error = SemanticError.voidMethodInExpression(
                    method: method,
                    nonterm: context.nonterm.name
                )
                
                errors.append(error)
            }
            
            return (nil, errors)
        }
    }
}
