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
