//
//  Expression-Validation.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 22.05.2026.
//

import Foundation

extension Specification {
    
    // MARK: - Internal Methods
    
    /// Возвращает результат вывода типа + сопутствующие ошибки
    func inferType(
        _ expression: Expression,
        in context: Context
    ) -> (type: Property.Kind?, errors: [ValidationError]) {
        switch expression {
        case .int: return (.int, [])
        case .float: return (.float, [])
        case .string: return (.string, [])
        case .bool: return (.bool, [])
            
        case .attribute(let reference):
            return inferReferenceType(reference, in: context)
            
        case .call(let method, let arguments):
            let (returnType, errors) = validateMethodCall(
                method: method,
                arguments: arguments,
                returnRequired: true,
                in: context
            )
            
            return (returnType, errors)
            
        case .binary(let left, let operation, let right):
            let leftResult = inferType(left, in: context)
            let rightResult = inferType(right, in: context)
            
            var errors = leftResult.errors + rightResult.errors
            
            guard let leftType = leftResult.type, let rightType = rightResult.type else {
                return (nil, errors)
            }
            
            /// Опциональный операнд запрещен
            if leftType.isOptional || rightType.isOptional {
                let error = ValidationError.optionalInBinary(
                    operator: operation.rawValue,
                    left: leftType.identifier,
                    right: rightType.identifier,
                    nonterm: context.nonterm.name
                )
                errors.append(error)
                
                return (nil, errors)
            }
            
            /// Получаем тип результата бинарной операции
            guard let resultType = binaryResultType(leftType, operation, rightType) else {
                /// Если один из типов не числовой
                if leftType.isNumeric != rightType.isNumeric {
                    let error = ValidationError.binaryTypeMismatch(
                        operator: operation.rawValue,
                        left: leftType.identifier,
                        right: rightType.identifier,
                        nonterm: context.nonterm.name
                    )
                    errors.append(error)
                
                /// Иначе — оператор несовместим
                } else {
                    let error = ValidationError.operatorNotApplicable(
                        operator: operation.rawValue,
                        left: leftType.identifier,
                        right: rightType.identifier,
                        nonterm: context.nonterm.name
                    )
                    errors.append(error)
                }
                
                return (nil, errors)
            }
            
            return (resultType, errors)
        }
    }
    
    // MARK: - Private Methods
    
    /// Тип ссылки при ЧТЕНИИ, с обертками группировок
    private func inferReferenceType(
        _ reference: Reference,
        in context: Context
    ) -> (type: Property.Kind?, errors: [ValidationError]) {
        /// Если указывает на левую часть `$0`
        if reference.target == 0 {
            /// Проверяем, что атрибут существует
            guard let attribute = lookupAttribute(
                reference.attribute,
                of: context.nonterm.name,
                isToken: false
            ) else {
                let error = ValidationError.unknownAttribute(
                    target: reference.target,
                    attribute: reference.attribute,
                    nonterm: context.nonterm.name
                )
                
                return (nil, [error])
            }
            
            return referenceType(
                reference,
                wrappers: [],
                baseType: attribute.property.type,
                in: context
            )
            
        /// Иначе — указывает на правую часть `$N`
        } else {
            /// Проверяем, что `N` не выходит за границы
            guard let symbol = resolveSymbol(reference.target, in: context) else {
                let error = ValidationError.referenceOutOfBounds(
                    target: reference.target,
                    count: context.symbols.count,
                    nonterm: context.nonterm.name
                )
                
                return (nil, [error])
            }
            
            /// Проверяем, что атрибут существует
            guard let attribute = lookupAttribute(
                reference.attribute,
                of: symbol.name,
                isToken: symbol.isToken
            ) else {
                let error = ValidationError.unknownAttribute(
                    target: reference.target,
                    attribute: reference.attribute,
                    symbol: symbol.name,
                    nonterm: context.nonterm.name
                )
                
                return (nil, [error])
            }
            
            return referenceType(
                reference,
                wrappers: symbol.wrappers,
                baseType: attribute.property.type,
                in: context
            )
        }
    }
    
    /// Тип при ЧТЕНИИ: наложение оберток группировок, затем снятие subscript
    private func referenceType(
        _ reference: Reference,
        wrappers: [Wrapper],
        baseType: Property.Kind,
        in context: Context
    ) -> (type: Property.Kind?, errors: [ValidationError]) {
        /// Обертки изнутри наружу
        var wrapped = baseType
        
        for wrapper in wrappers {
            switch wrapper {
            case .array:
                wrapped = .array(wrapped)
                
            case .optional:
                /// optional(optional(x)) → optional(x)
                if !wrapped.isOptional { wrapped = .optional(wrapped) }
            }
        }
        
        /// Снимаем subscripts с уже обернутого типа
        return unfoldSubscripts(reference, baseType: wrapped, in: context)
    }
    
    /// Тип результата бинарной операции
    func binaryResultType(
        _ left: Property.Kind,
        _ operation: Operator,
        _ right: Property.Kind
    ) -> Property.Kind? {
        /// Только сложение двух строк
        if case .string = left, case .string = right {
            return operation == .add ? .string : nil
        }
        
        /// Операции с булевыми типами не поддерживаются
        if case .bool = left { return nil }
        if case .bool = right { return nil }
        
        /// Только операции с числовыми типами
        guard left.isNumeric && right.isNumeric else { return nil }
        
        /// float + int → float, int + float → float
        return (left.isFloat || right.isFloat) ? .float : .int
    }
}
