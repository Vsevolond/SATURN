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
    ) -> (type: Property.Kind?, errors: [SemanticError]) {
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
                let error = SemanticError.optionalInBinary(
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
                    let error = SemanticError.binaryTypeMismatch(
                        operator: operation.rawValue,
                        left: leftType.identifier,
                        right: rightType.identifier,
                        nonterm: context.nonterm.name
                    )
                    errors.append(error)
                
                /// Иначе — оператор несовместим
                } else {
                    let error = SemanticError.operatorNotApplicable(
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
    
    /// Тип ссылки при ЧТеИИ, с обертками группировок
    private func inferReferenceType(
        _ reference: Reference,
        in context: Context
    ) -> (type: Property.Kind?, errors: [SemanticError]) {
        /// Если указывает на левую часть `$0`
        if reference.target == 0 {
            /// Проверяем, что атрибут существует
            guard let attribute = lookupAttribute(
                reference.attribute,
                of: context.nonterm.name,
                isToken: false
            ) else {
                let error = SemanticError.unknownAttribute(
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
                let error = SemanticError.referenceOutOfBounds(
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
                let error = SemanticError.unknownAttribute(
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
    
    /// Тип при ЧТеИИ: снятие subscript + наложение оберток группировок
    private func referenceType(
        _ reference: Reference,
        wrappers: [Wrapper],
        baseType: Property.Kind,
        in context: Context
    ) -> (type: Property.Kind?, errors: [SemanticError]) {
        /// Снимаем subscripts, чтобы получить базовый тип
        let unfold = unfoldSubscripts(
            reference,
            baseType: baseType,
            in: context
        )
        
        guard var type = unfold.type else { return (nil, unfold.errors) }
        
        /// Обертки изнутри наружу
        for wrapper in wrappers {
            switch wrapper {
            case .array:
                type = .array(type)
                
            case .optional:
                /// optional(optional(x)) → optional(x)
                if !type.isOptional { type = .optional(type) }
            }
        }
        
        return (type, unfold.errors)
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
