//
//  SemanticRuntime.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 27.05.2026.
//

import Foundation
import JavaScriptCore
 
/// Среда выполнения пользовательской логики из `semantics.js`
public final class SemanticRuntime {
    
    // MARK: - Public Properties
    
    /// Контекст движка с загруженным кодом семантики
    public let context: JSContext
    
    // MARK: - Initializers
    
    public init(script: String) throws {
        guard let context = JSContext() else {
            throw EvaluateError.runtimeUnavailable
        }
        
        self.context = context
        
        /// Перехватываем исключения движка
        var error: String? = nil
        
        context.exceptionHandler = { _, exception in
            error = exception.flatMap { $0.toString() }
        }
        
        /// Загрузка кода семантики в контекст
        context.evaluateScript(script)
        
        /// Ошибка в самом коде семантики прерывает подготовку
        if let error { throw EvaluateError.scriptError(message: error) }
    }
    
    // MARK: - Public Methods
    
    /// Вызывает метод семантики по имени с готовыми аргументами движка
    public func call(_ method: String, arguments: [JSValue]) throws -> JSValue {
        /// Метод ищется среди глобальных функций контекста
        guard let function = context.objectForKeyedSubscript(method),
              !function.isUndefined
        else {
            throw EvaluateError.methodNotFound(name: method)
        }
        
        var error: String? = nil
        
        context.exceptionHandler = { _, exception in
            error = exception.flatMap { $0.toString() }
        }
        
        let result = function.call(withArguments: arguments)
        
        /// Исключение во время вызова прерывает трансляцию
        if let error { throw EvaluateError.methodFailed(name: method, message: error) }
        
        /// Возврат отсутствует только при внутренней ошибке движка
        guard let result else {
            throw EvaluateError.methodFailed(
                name: method,
                message: "Нет результата"
            )
        }
        
        return result
    }
}
