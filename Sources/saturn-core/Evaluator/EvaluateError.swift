//
//  EvaluateError.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 27.05.2026.
//

import Foundation
 
/// Ошибка вычисления атрибутов
public enum EvaluateError: Error, Equatable {
    
    /// Движок JavaScript недоступен в этой среде
    case runtimeUnavailable
    
    /// Ошибка в исходном коде `semantics.js` при загрузке
    case scriptError(message: String)
    
    /// Метод вызван, но не объявлен в `semantics.js`
    case methodNotFound(name: String)
    
    /// Метод бросил исключение во время выполнения
    case methodFailed(name: String, message: String)
    
    /// Отсутствующее значение использовано в арифметике или присваивании
    case undefinedInExpression(nonterm: String)
    
    /// Ссылка на символ за границами правой части правила
    case referenceOutOfBounds(target: UInt, nonterm: String)
    
    /// Индекс массива вне диапазона при снятии `subscript`
    case subscriptOutOfBounds(target: UInt, attribute: String)
    
    /// Чтение атрибута, который еще не вычислен ни одним действием
    case attributeNotComputed(target: UInt, attribute: String, nonterm: String)
    
    /// Деление на ноль в арифметическом выражении
    case divisionByZero(nonterm: String)
    
    /// Циклическая зависимость атрибутов
    case cyclicDependency(attribute: String? = nil, nonterm: String)
}

// MARK: - Extensions

extension EvaluateError: LocalizedError {
    
    // MARK: - Public Properties
    
    /// Описание ошибки вычисления атрибутов
    public var errorDescription: String? {
        switch self {
        case .runtimeUnavailable:
            return "Среда выполнения JavaScript недоступна — невозможно загрузить semantics.js"
            
        case .scriptError(let message):
            return "Ошибка при загрузке semantics.js: \(message)"
            
        case .methodNotFound(let name):
            return "Метод «\(name)» не объявлен в semantics.js"
            
        case .methodFailed(let name, let message):
            return "Метод «\(name)» завершился исключением: \(message)"
            
        case .undefinedInExpression(let nonterm):
            return "В правиле «\(nonterm)» отсутствующее значение использовано в арифметике или присваивании"
            
        case .referenceOutOfBounds(let target, let nonterm):
            return "Ссылка $\(target) в правиле «\(nonterm)» выходит за границы правой части"
            
        case .subscriptOutOfBounds(let target, let attribute):
            return "Индекс сабскрипта у $\(target).\(attribute) вышел за границы массива"
            
        case .attributeNotComputed(let target, let attribute, let nonterm):
            let owner = target == 0 ? "$0" : "$\(target)"
            
            return "В правиле «\(nonterm)» читается атрибут \(owner).\(attribute), который еще не вычислен"
            
        case .divisionByZero(let nonterm):
            return "Деление на ноль в арифметическом выражении правила «\(nonterm)»"
            
        case .cyclicDependency(let attribute, let nonterm):
            if let attribute {
                return "Циклическая зависимость атрибута «\(attribute)» в правиле «\(nonterm)»"
                
            } else {
                return "Циклическая зависимость атрибутов через спуск в правило «\(nonterm)»"
            }
        }
    }
}
