//
//  AttributeValue.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 27.05.2026.
//

import Foundation
import JavaScriptCore
 
/// Значение атрибута на этапе вычисления
public indirect enum AttributeValue {
    
    // MARK: - Cases
    
    /// Целое число
    case int(Int)
    
    /// Вещественное число
    case float(Double)
    
    /// Строка
    case string(String)
    
    /// Логическое значение
    case bool(Bool)
    
    /// Массив значений — результат повторения `%rep`
    case array([AttributeValue])
    
    /// Опциональное значение — результат опционала `[...]` или хвоста `%rep[...]`
    case optional(AttributeValue?)
    
    /// Пользовательский тип, хранимый как значение движка
    case object(JSValue)
    
    /// Значение отсутствует: символ выпал при устранении ε, либо атрибут еще не вычислен
    case undefined
    
    // MARK: - Public Properties
    
    /// Отсутствует ли значение
    public var isUndefined: Bool {
        if case .undefined = self { return true }
        return false
    }
}
 
// MARK: - Extensions
 
extension AttributeValue {
    
    // MARK: - Internal Methods
    
    /// Переводит значение в `JSValue` для передачи в метод `semantics.js`
    func toJS(in context: JSContext) -> JSValue {
        switch self {
        case .int(let value):
            return JSValue(int32: Int32(value), in: context)
            
        case .float(let value):
            return JSValue(double: value, in: context)
            
        case .string(let value):
            return JSValue(object: value, in: context)
            
        case .bool(let value):
            return JSValue(bool: value, in: context)
            
        case .array(let values):
            /// Массив разворачивается поэлементно в массив движка
            let elements = values.map { $0.toJS(in: context) }
            return JSValue(object: elements, in: context)
            
        case .optional(let wrapped):
            /// Отсутствие внутри опционала — это `null` движка, иначе разворачиваем
            guard let wrapped else { return JSValue(nullIn: context) }
            return wrapped.toJS(in: context)
            
        case .object(let value):
            return value
            
        case .undefined:
            return JSValue(undefinedIn: context)
        }
    }
    
    /// Восстанавливает значение из результата метода `semantics.js` по ожидаемому типу
    static func fromJS(_ value: JSValue, expected kind: Property.Kind) -> AttributeValue {
        let isEmpty = value.isUndefined || value.isNull
        
        switch kind {
        case .int:
            guard !isEmpty else { return .undefined }
            
            let converted = Int(value.toInt32())
            return .int(converted)
            
        case .float:
            guard !isEmpty else { return .undefined }
            
            let converted = value.toDouble()
            return .float(converted)
            
        case .string:
            guard !isEmpty else { return .undefined }
            
            let converted = value.toString() ?? ""
            return .string(converted)
            
        case .bool:
            guard !isEmpty else { return .undefined }
            
            let converted = value.toBool()
            return .bool(converted)
            
        case .custom:
            guard !isEmpty else { return .undefined }
            /// Пользовательский тип — структура известна только движку
            return .object(value)
            
        case .array(let element):
            guard !isEmpty else { return .undefined }
            /// Массив движка восстанавливаем поэлементно по типу элемента
            let count = value.objectForKeyedSubscript("length").toInt32()
            let length = Int(count)
            
            var values: [AttributeValue] = []
            
            for index in 0..<length {
                guard let item = value.atIndex(index) else { continue }
                
                let nested = fromJS(item, expected: element)
                values.append(nested)
            }
            
            return .array(values)
            
        case .optional(let wrapped):
            /// Опционал: пустота движка — это явно незаполненный опционал
            guard !isEmpty else { return .optional(nil) }
            
            let nested = fromJS(value, expected: wrapped)
            return .optional(nested)
        }
    }
}

// MARK: - Extensions

extension AttributeValue: CustomStringConvertible {
    
    // MARK: - Public Properties
    
    /// Человекочитаемое представление значения атрибута для вывода в консоль
    public var description: String {
        switch self {
        case .int(let value):
            return String(value)
            
        case .float(let value):
            return String(value)
            
        case .string(let value):
            /// Строка в кавычках
            return "\"\(value)\""
            
        case .bool(let value):
            return String(value)
            
        case .array(let values):
            /// Массив через запятую в квадратных скобках
            let parts = values.map { $0.description }.joined(separator: ", ")
            return "[\(parts)]"
            
        case .optional(let wrapped):
            /// Пустой опционал — `null`, заполненный — содержимое без обертки
            guard let wrapped else { return "null" }
            return wrapped.description
            
        case .object(let value):
            /// Пользовательский тип выводится средствами движка через свой `toString`
            return value.toString() ?? "object"
            
        case .undefined:
            return "undefined"
        }
    }
}
