//
//  Specification-SemanticError.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 21.05.2026.
//

import Foundation

extension Specification {
    
    /// Ошибка семантического анализа спецификации
    public enum SemanticError: Error, Equatable {
        
        // MARK: - Token errors
        
        /// Два токена имеют одинаковое имя
        case duplicateTokenName(String)
        
        /// Два токена имеют одинаковое значение
        case duplicateTokenValue(first: String, second: String)
        
        // MARK: - Type errors
        
        /// Неизвестный тип атрибута
        case unknownAttributeType(name: String, symbol: String, attribute: String)
        
        /// Неизвестный тип аргумента метода
        case unknownArgumentType(name: String, method: String)
        
        /// Неизвестный возвращаемый тип метода
        case unknownReturnType(name: String, method: String)
        
        // MARK: - Attribute errors
        
        /// Два атрибута имеют одинаковое имя
        case duplicateAttribute(name: String, symbol: String)
        
        /// У токенов не может быть пользовательских атрибутов
        case tokenAttributeNotAllowed(attribute: String, token: String)
        
        // MARK: - Grammar errors
        
        /// Терминал не объявлен в секции токенов
        case unknownTerm(name: String)
        
        /// У нетерминала нет альтернатив
        case emptyNonterm(name: String)
        
        // MARK: - Reference errors
        
        /// `$N` выходит за границы числа элементов альтернативы
        case referenceOutOfBounds(target: UInt, count: Int, nonterm: String)
        
        /// У символа в позиции `$N` нет такого атрибута
        case unknownAttribute(target: UInt, attribute: String, symbol: String? = nil, nonterm: String)
        
        /// Индексация применена к неиндексируемому типу
        case subscriptOnNonArray(target: UInt, attribute: String, nonterm: String)
        
        /// Индекс subscript не является целым
        case subscriptIndexNotInt(target: UInt, attribute: String, nonterm: String)
        
        // MARK: - Expression errors
        
        /// Несовместимые типы операндов бинарной операции
        case binaryTypeMismatch(operator: String, left: String, right: String, nonterm: String)
        
        /// Оператор неприменим к типу операнда
        case operatorNotApplicable(operator: String, left: String, right: String, nonterm: String)

        /// Операнд бинарной операции — опционал
        case optionalInBinary(operator: String, left: String, right: String, nonterm: String)
        
        // MARK: - Method errors
        
        /// Вызываемый метод не объявлен
        case unknownMethod(name: String, nonterm: String)
        
        /// Число аргументов не совпадает с арностью
        case argumentCountMismatch(method: String, expected: Int, given: Int, nonterm: String)
        
        /// Тип аргумента несовместим с типом параметра
        case argumentTypeMismatch(method: String, index: Int, expected: String, given: String, nonterm: String)
        
        /// Метод без возвращаемого значения использован в выражении
        case voidMethodInExpression(method: String, nonterm: String)
        
        // MARK: - Attribute Flow errors
        
        /// Присваивание атрибуту, которому присваивать нельзя
        case illegalAssignment(target: UInt, attribute: String, nonterm: String)
        
        /// Тип значения несовместим с типом атрибута-цели
        case assignmentTypeMismatch(target: UInt, attribute: String, expected: String, given: String, nonterm: String)
    }
}
