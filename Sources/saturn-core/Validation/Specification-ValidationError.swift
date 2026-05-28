//
//  Specification-ValidationError.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 21.05.2026.
//

import Foundation

extension Specification {
    
    /// Ошибка семантического анализа спецификации
    public enum ValidationError: Error, Equatable {
        
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

// MARK: - Extensions

extension Specification.ValidationError: CustomStringConvertible {
    
    // MARK: - Public Properties
    
    /// Описание ошибки валидации
    public var description: String {
        switch self {
            
        case .duplicateTokenName(let name):
            return "Повторное объявление токена «\(name)» в секции %tokens"
            
        case .duplicateTokenValue(let first, let second):
            return "Токены «\(first)» и «\(second)» имеют одинаковое значение"
            
        case .unknownAttributeType(let name, let symbol, let attribute):
            return "Неизвестный тип «\(name)» у атрибута «\(attribute)» символа «\(symbol)»"
            
        case .unknownArgumentType(let name, let method):
            return "Неизвестный тип «\(name)» в списке аргументов метода «\(method)»"
            
        case .unknownReturnType(let name, let method):
            return "Неизвестный возвращаемый тип «\(name)» у метода «\(method)»"
            
        case .duplicateAttribute(let name, let symbol):
            return "Повторное объявление атрибута «\(name)» у символа «\(symbol)»"
            
        case .tokenAttributeNotAllowed(let attribute, let token):
            return "У токена «\(token)» нельзя объявлять собственный атрибут «\(attribute)»"
            
        case .unknownTerm(let name):
            return "Терминал «\(name)» используется в правиле, но не объявлен в секции %tokens"
            
        case .emptyNonterm(let name):
            return "У нетерминала «\(name)» нет ни одной альтернативы"
            
        case .referenceOutOfBounds(let target, let count, let nonterm):
            return "Ссылка $\(target) выходит за границы правой части правила «\(nonterm)» — в правиле \(count) символов"
            
        case .unknownAttribute(let target, let attribute, let symbol, let nonterm):
            if let symbol {
                return "У символа $\(target) «\(symbol)» в правиле «\(nonterm)» нет атрибута «\(attribute)»"
            }
            
            return "У левой части $\(target) правила «\(nonterm)» нет атрибута «\(attribute)»"
            
        case .subscriptOnNonArray(let target, let attribute, let nonterm):
            return "Индексация $\(target).\(attribute) в правиле «\(nonterm)» применена к неиндексируемому типу"
            
        case .subscriptIndexNotInt(let target, let attribute, let nonterm):
            return "Индекс сабскрипта у $\(target).\(attribute) в правиле «\(nonterm)» не является целым числом"
            
        case .binaryTypeMismatch(let op, let left, let right, let nonterm):
            return "Несовместимые типы операндов оператора «\(op)» в правиле «\(nonterm)»: левый «\(left)», правый «\(right)»"
            
        case .operatorNotApplicable(let op, let left, let right, let nonterm):
            return "Оператор «\(op)» неприменим к операндам «\(left)» и «\(right)» в правиле «\(nonterm)»"
            
        case .optionalInBinary(let op, let left, let right, let nonterm):
            return "Операнд бинарной операции «\(op)» в правиле «\(nonterm)» — опционал: левый «\(left)», правый «\(right)»"
            
        case .unknownMethod(let name, let nonterm):
            return "Метод «\(name)», вызванный в правиле «\(nonterm)», не объявлен в секции %methods"
            
        case .argumentCountMismatch(let method, let expected, let given, let nonterm):
            return "Метод «\(method)» в правиле «\(nonterm)» ожидает аргументов: \(expected), передано: \(given)"
            
        case .argumentTypeMismatch(let method, let index, let expected, let given, let nonterm):
            return "Аргумент номер \(index + 1) метода «\(method)» в правиле «\(nonterm)» имеет тип «\(given)», ожидался «\(expected)»"
            
        case .voidMethodInExpression(let method, let nonterm):
            return "Метод «\(method)» без возвращаемого значения использован в выражении в правиле «\(nonterm)»"
            
        case .illegalAssignment(let target, let attribute, let nonterm):
            if target == 0 {
                return "В правиле «\(nonterm)» нельзя присваивать наследуемому атрибуту левой части $0.\(attribute) — его задает родитель"
                
            } else {
                return "В правиле «\(nonterm)» нельзя присваивать атрибуту $\(target).\(attribute) — записывать можно только в наследуемые атрибуты правой части"
            }
            
        case .assignmentTypeMismatch(let target, let attribute, let expected, let given, let nonterm):
            return "Тип значения «\(given)» несовместим с типом цели $\(target).\(attribute) «\(expected)» в правиле «\(nonterm)»"
        }
    }
}
