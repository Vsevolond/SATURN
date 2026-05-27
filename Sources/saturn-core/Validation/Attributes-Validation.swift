//
//  Attributes-Validation.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 21.05.2026.
//

import Foundation

extension Specification {
    
    // MARK: - Internal Methods
    
    /// Атрибуты:
    /// - Типы опираются на известные
    /// - Нет дублей атрибутов
    /// - У токенов не может быть пользовательских атрибутов
    func validateAttributes(_ uniqueTokens: Set<String>) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        for (symbol, listOfAttributes) in attributes {
            /// Если символ — токен
            if uniqueTokens.contains(symbol) {
                /// Проходим по всем атрибутам
                for attribute in listOfAttributes {
                    let error = ValidationError.tokenAttributeNotAllowed(
                        attribute: attribute.property.name,
                        token: symbol
                    )
                    
                    errors.append(error)
                }
                
            /// Иначе — нетерминал
            } else {
                /// Проверка типов атрибутов
                for attribute in listOfAttributes {
                    /// Если базовый тип неизвестен
                    if let unknown = unknownBaseType(of: attribute.property.type) {
                        let error = ValidationError.unknownAttributeType(
                            name: unknown,
                            symbol: symbol,
                            attribute: attribute.property.name
                        )
                        
                        errors.append(error)
                    }
                }
                
                /// Проверка дублей
                for i in listOfAttributes.indices {
                    for j in listOfAttributes.indices where j > i {
                        /// Если совпадают имена атрибутов
                        if listOfAttributes[i].property.name == listOfAttributes[j].property.name {
                            let error = ValidationError.duplicateAttribute(
                                name: listOfAttributes[i].property.name,
                                symbol: symbol
                            )
                            
                            errors.append(error)
                        }
                    }
                }
            }
        }
        
        return errors
    }
    
    /// Имя неизвестного базового типа, `nil`, если тип известен
    func unknownBaseType(of type: Property.Kind) -> String? {
        switch type {
        case .int, .float, .bool, .string:
            return nil
            
        case .custom(let name):
            return types.contains(name) ? nil : name
            
        case .array(let kind):
            return unknownBaseType(of: kind)
            
        case .optional(let kind):
            return unknownBaseType(of: kind)
        }
    }
}
