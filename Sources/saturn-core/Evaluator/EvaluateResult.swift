//
//  EvaluateResult.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 28.05.2026.
//

import Foundation
import JavaScriptCore
 
/// Полный результат вычисления атрибутов на дереве разбора
public struct EvaluateResult {
    
    // MARK: - Public Properties
    
    /// Синтезированные атрибуты корня
    public let rootAttributes: [String: AttributeValue]
    
    /// Синтезированные атрибуты всех узлов по их идентичности
    public let synthesizedByNode: [ObjectIdentifier: [String: AttributeValue]]
    
    /// Наследуемые атрибуты всех узлов по их идентичности
    public let inheritedByNode: [ObjectIdentifier: [String: AttributeValue]]
    
    /// Граф зависимостей атрибутов, накопленный во время обхода
    public let dependencyGraph: DependencyGraph
    
    // MARK: - Public Methods
    
    /// Сериализует дерево с атрибутами в JSON
    public func treeJSON(
        tree: ParseTree,
        context: JSContext,
        pretty: Bool = true
    ) throws -> Data {
        let store = ParseTree.AttributeStore(
            synthesized: synthesizedByNode,
            inherited: inheritedByNode
        )
        
        return try tree.toJSONData(
            attributes: store,
            context: context,
            pretty: pretty
        )
    }
    
    /// Сериализует граф зависимостей в формат DOT
    public func dependenciesDOT() -> String { dependencyGraph.toDOT() }
}
