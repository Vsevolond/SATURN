//
//  Statement-Validation.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 21.05.2026.
//

import Foundation

extension Specification {
    
    // MARK: - Internal Methods
    
    /// Выражение: валидация вызова метода или присваивания
    func validateStatement(_ statement: Statement, in context: Context) -> [ValidationError] {
        switch statement {
        case .call(let method, let arguments):
            /// `returnType` игнорируется
            return validateMethodCall(
                method: method,
                arguments: arguments,
                returnRequired: false,
                in: context
            )
            .errors
            
        case .assignment(let reference, let value):
            return validateAssignment(
                reference: reference,
                value: value,
                in: context
            )
        }
    }
    
    /// Объявление атрибута по имени символа, дубли - берется последний
    func lookupAttribute(_ name: String, of symbol: String, isToken: Bool) -> Attribute? {
        /// Если символ — токен
        if isToken {
            /// Имя атрибута должно совпадать с встроенным атрибутом токена `text`
            guard name == Specification.builtinTokenAttribute else { return nil }
            
            return Attribute(
                property: Property(name: name, type: .string),
                target: symbol
            )
            
        /// Иначе — нетерминал
        } else {
            guard let listOfAttributes = attributes[symbol] else { return nil }
            return listOfAttributes.last { $0.property.name == name }
        }
    }
    
    /// `$N` → символ правой части, `nil` вне границ
    func resolveSymbol(_ target: UInt, in context: Context) -> FlatSymbol? {
        guard target >= 1 && target <= context.symbols.count else { return nil }
        return context.symbols[Int(target) - 1]
    }
    
    /// Снятие subscripts: каждый индекс типа `int`, тип на каждом шаге — `array`
    func unfoldSubscripts(
        _ reference: Reference,
        baseType: Property.Kind,
        in context: Context
    ) -> (type: Property.Kind?, errors: [ValidationError]) {
        var errors: [ValidationError] = []
        var type = baseType
        
        for index in reference.subscripts {
            /// Вычисляем тип выражения
            let result = inferType(index, in: context)
            errors += result.errors
            
            /// Если тип не `int`
            if result.type != .int {
                let error = ValidationError.subscriptIndexNotInt(
                    target: reference.target,
                    attribute: reference.attribute,
                    nonterm: context.nonterm.name
                )
                
                errors.append(error)
            }
            
            /// Базовый тип (или на прошлом шаге) должен быть `array`
            guard case .array(let nested) = type else {
                let error = ValidationError.subscriptOnNonArray(
                    target: reference.target,
                    attribute: reference.attribute,
                    nonterm: context.nonterm.name
                )
                errors.append(error)
                
                return (nil, errors)
            }
            
            type = nested
        }
        
        return (type, errors)
    }
    
    // MARK: - Private Methods
    
    /// Валидация присваивания
    private func validateAssignment(
        reference: Reference,
        value: Expression,
        in context: Context
    ) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        /// Если указывает на левую часть `$0`
        if reference.target == 0 {
            /// Проверяем, что атрибут существует
            guard let attribute = lookupAttribute(
                reference.attribute,
                of: context.nonterm.name,
                isToken: false
            ) else {
                return [
                    ValidationError.unknownAttribute(
                        target: reference.target,
                        attribute: reference.attribute,
                        nonterm: context.nonterm.name
                    )
                ]
            }
            
            /// Наследуемый атрибут левой части задается родителем
            /// Аксиома — исключение, она сама задает свои наследуемые атрибуты
            if attribute.type == .inherited, context.nonterm.name != axiom.name {
                return [
                    ValidationError.illegalAssignment(
                        target: reference.target,
                        attribute: reference.attribute,
                        nonterm: context.nonterm.name
                    )
                ]
            }
            
            /// Тип цели: объявленный, со снятием subscripts (у `$0` оберток группировок нет)
            let unfold = unfoldSubscripts(
                reference,
                baseType: attribute.property.type,
                in: context
            )
            
            errors += unfold.errors
            
            guard let type = unfold.type else { return errors }
            
            /// Совместимость типов при присваивании
            errors += validateAssignmentValue(
                reference: reference,
                value: value,
                targetType: type,
                in: context
            )
            
            return errors
            
            
        /// Иначе — указывает на правую часть `$N`
        } else {
            /// Проверяем, что `N` не выходит за границы
            guard let symbol = resolveSymbol(reference.target, in: context) else {
                return [
                    ValidationError.referenceOutOfBounds(
                        target: reference.target,
                        count: context.symbols.count,
                        nonterm: context.nonterm.name
                    )
                ]
            }
            
            /// Проверяем, что атрибут существует
            guard let attribute = lookupAttribute(
                reference.attribute,
                of: symbol.name,
                isToken: symbol.isToken
            ) else {
                return [
                    ValidationError.unknownAttribute(
                        target: reference.target,
                        attribute: reference.attribute,
                        symbol: symbol.name,
                        nonterm: context.nonterm.name
                    )
                ]
            }
            
            /// Писать в правую часть можно только наследуемые
            /// У токена единственный синтезированный атрибут - только читаемый
            /// У нетерминалов синтезированные атрибуты вычисляются в их правилах
            if attribute.type != .inherited {
                let error = ValidationError.illegalAssignment(
                    target: reference.target,
                    attribute: reference.attribute,
                    nonterm: context.nonterm.name
                )
                
                errors.append(error)
            }
            
            /// Тип цели: объявленный, со снятием subscripts, Бе оберток группировок
            let unfold = unfoldSubscripts(
                reference,
                baseType: attribute.property.type,
                in: context
            )
            
            errors += unfold.errors
            
            guard let type = unfold.type else { return errors }
            
            /// Совместимость типов при присваивании
            errors += validateAssignmentValue(
                reference: reference,
                value: value,
                targetType: type,
                in: context
            )
            
            return errors
        }
    }
    
    /// Проверка значения присваивания: тип значения совместим с типом цели
    private func validateAssignmentValue(
        reference: Reference,
        value: Expression,
        targetType: Property.Kind,
        in context: Context
    ) -> [ValidationError] {
        let result = inferType(value, in: context)
        var errors = result.errors
        
        guard let type = result.type else { return errors }
        
        /// Если типы несовместимы при присваивании
        if !type.assignable(to: targetType) {
            let error = ValidationError.assignmentTypeMismatch(
                target: reference.target,
                attribute: reference.attribute,
                expected: targetType.identifier,
                given: type.identifier,
                nonterm: context.nonterm.name
            )
            
            errors.append(error)
        }
        
        return errors
    }
}
