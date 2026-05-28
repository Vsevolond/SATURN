//
//  ParseTree+JSON.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 28.05.2026.
//

import Foundation
import JavaScriptCore
 
extension ParseTree {
    
    // MARK: - Type Entities
    
    /// Хранилище атрибутов узлов для подстановки при сериализации
    public struct AttributeStore {
        
        // MARK: - Public Properties
        
        /// Синтезированные атрибуты по узлам
        public let synthesized: [ObjectIdentifier: [String: AttributeValue]]
        
        /// Наследуемые атрибуты по узлам
        public let inherited: [ObjectIdentifier: [String: AttributeValue]]
    }
    
    // MARK: - Public Methods
    
    /// Превращает дерево в JSON-совместимое Swift-значение
    ///
    /// Каждый нетерминал отдат однопольный объект
    /// `{ "имя": { синтезуемые, наследуемые, дети } }`.
    /// Токен — однопольный объект `{ "имя": "текст" }`
    /// Повторения и опционалы в JSON разворачиваются плоско в массив детей родителя
    /// Пустые витки и пустые секции атрибутов опускаются
    public func toJSON(attributes: AttributeStore, context: JSContext) -> [String: Any] {
        let body = body(attributes: attributes, context: context)
        return [symbol: body]
    }
    
    /// Обертка над JSONSerialization для записи в файл или строку
    public func toJSONData(
        attributes: AttributeStore,
        context: JSContext,
        pretty: Bool = true
    ) throws -> Data {
        let json = toJSON(attributes: attributes, context: context)
        
        var options: JSONSerialization.WritingOptions = [.fragmentsAllowed]
        if pretty { options.insert(.prettyPrinted) }
        
        return try JSONSerialization.data(withJSONObject: json, options: options)
    }
    
    // MARK: - Private Methods
    
    /// Тело узла: атрибуты и массив детей без обертки именем
    private func body(attributes: AttributeStore, context: JSContext) -> [String: Any] {
        var result: [String: Any] = [:]
        let identity = ObjectIdentifier(self)
        
        /// Секции атрибутов добавляются только когда есть, что сериализовать
        if let attrs = attributes.synthesized[identity],
           let synthesized = serialize(attrs, context: context)
        {
            result["synthesized"] = synthesized
        }
        
        if let attrs = attributes.inherited[identity],
           let inherited = serialize(attrs, context: context)
        {
            result["inherited"] = inherited
        }
        
        /// Дети собираются плоско: вложенные витки повторений раскрываются на этом же уровне
        result["children"] = flatten(children, attributes: attributes, context: context)
        
        return result
    }
    
    /// Сериализует один дочерний элемент в однопольный объект
    private func serialize(
        child: ParseTree.Child,
        attributes: AttributeStore,
        context: JSContext
    ) -> [Any] {
        switch child {
        case .tree(let subtree):
            /// Нетерминал — однопольный объект с именем символа
            return [
                [
                    subtree.symbol: subtree.body(attributes: attributes, context: context)
                ]
            ]
            
        case .token(let lexeme):
            /// Токен — однопольный объект с именем токена и его текстом
            return [
                [
                    lexeme.name: lexeme.text
                ]
            ]
            
        case .repetition(let repetition):
            /// Повторение раскрывается плоско: все элементы всех витков идут на уровне родителя
            var flat: [Any] = []
            
            for occurrence in repetition.items {
                for nested in occurrence {
                    let serialized = serialize(
                        child: nested,
                        attributes: attributes,
                        context: context
                    )
                    
                    flat.append(contentsOf: serialized)
                }
            }
            
            return flat
        }
    }
    
    /// Плоский массив детей с разворачиванием вложенных повторений
    private func flatten(
        _ children: [ParseTree.Child],
        attributes: AttributeStore,
        context: JSContext
    ) -> [Any] {
        var result: [Any] = []
        
        for child in children {
            let serialized = serialize(
                child: child,
                attributes: attributes,
                context: context
            )
            
            result.append(contentsOf: serialized)
        }
        
        return result
    }
    
    /// Сериализация словаря атрибутов: пустой словарь и недопустимые значения опускаются
    private func serialize(
        _ values: [String: AttributeValue],
        context: JSContext
    ) -> [String: Any]? {
        var result: [String: Any] = [:]
        
        for (name, value) in values {
            /// `.undefined` сигнализируется через `nil` — такие ключи опускаются
            guard let converted = value.toJSONValue(in: context) else {
                continue
            }
            
            result[name] = converted
        }
        
        return result.isEmpty ? nil : result
    }
}
