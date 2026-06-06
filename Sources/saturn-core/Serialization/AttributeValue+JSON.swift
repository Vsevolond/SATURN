//
//  AttributeValue+JSON.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 28.05.2026.
//

import Foundation
import JavaScriptCore
 
extension AttributeValue {
    
    // MARK: - Internal Methods
    
    /// Конвертирует значение в JSON-совместимое Swift-значение
    func toJSONValue(in context: JSContext) -> Any? {
        switch self {
        case .int(let value):
            return value
            
        case .float(let value):
            return value
            
        case .string(let value):
            return value
            
        case .bool(let value):
            return value
            
        case .array(let values):
            /// Массив разворачивается поэлементно, пустые слоты (`.undefined`) превращаются в `null`
            return values.map { $0.toJSONValue(in: context) ?? NSNull() }
            
        case .optional(let wrapped):
            /// Пустой опционал — `null`, заполненный — содержимое
            guard let wrapped else { return NSNull() }
            
            return wrapped.toJSONValue(in: context)
            
        case .object(let value):
            /// Пользовательский объект сериализуется средствами движка, затем парсится обратно
            return serializeObject(value, in: context)
            
        case .undefined:
            /// Отсутствие — сигнал родителю опустить ключ
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    /// Превращает `JSValue` в Swift-значение через `JSON.stringify` и разбор полученной строки
    private func serializeObject(_ value: JSValue, in context: JSContext) -> Any {
        /// Помещаем объект во временную глобальную переменную для безопасного вызова `stringify`
        let temporaryKey = "__saturn_serialize__"
        context.setObject(value, forKeyedSubscript: temporaryKey as NSString)
        
        defer {
            /// Снимаем временную привязку, чтобы не загромождать контекст
            let undefined = JSValue(undefinedIn: context)
            context.setObject(undefined, forKeyedSubscript: temporaryKey as NSString)
        }
        
        let stringified = context.evaluateScript("JSON.stringify(\(temporaryKey))")
        
        guard let string = stringified?.toString(),
              !string.isEmpty, string != "undefined"
        else { return NSNull() }
        
        /// Разбираем JSON-строку обратно в дерево Swift-значений
        guard let data = string.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(
                  with: data,
                  options: [.fragmentsAllowed]
              )
        else { return NSNull() }
        
        return parsed
    }
}
