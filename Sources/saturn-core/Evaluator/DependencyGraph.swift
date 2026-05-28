//
//  DependencyGraph.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 28.05.2026.
//

import Foundation
 
/// Граф зависимостей атрибутов на дереве разбора
///
/// Узел графа — атрибут конкретного узла дерева
/// Ребро — зависимость значения от другого атрибута
public struct DependencyGraph {
    
    // MARK: - Public Properties
    
    /// Все участвовавшие в трансляции атрибуты как узлы графа
    public let nodes: Set<AttributeNode>
    
    /// Зависимости между атрибутами: значение источника требуется для вычисления цели
    public let edges: Set<Edge>
    
    // MARK: - Initializers
    
    public init(
        nodes: Set<AttributeNode> = [],
        edges: Set<Edge> = []
    ) {
        self.nodes = nodes
        self.edges = edges
    }
}
 
// MARK: - Extensions
 
extension DependencyGraph {
    
    // MARK: - Type Entities
    
    /// Вид узла графа: атрибут нетерминала или встроенный атрибут токена
    public enum NodeKind: Hashable {
        
        /// Синтезированный атрибут нетерминала
        case synthesized
        
        /// Наследуемый атрибут нетерминала
        case inherited
        
        /// Встроенный атрибут токена — для токенов он один,`text`
        case token
    }
}

extension DependencyGraph {
    
    // MARK: - Type Entities
    
    /// Узел графа — один атрибут одного экземпляра символа дерева
    public struct AttributeNode: Hashable {
        
        // MARK: - Public Properties
        
        /// Стабильный идентификатор символа дерева с индексом при повторе
        public let owner: String
        
        /// Имя атрибута символа
        public let attribute: String
        
        /// Вид атрибута и принадлежность токену
        public let kind: NodeKind
    }
}
 
extension DependencyGraph {
    
    // MARK: - Type Entities
    
    /// Ребро графа — направление зависимости от источника к цели
    public struct Edge: Hashable {
        
        // MARK: - Public Properties
        
        /// Атрибут, значение которого читается
        public let from: AttributeNode
        
        /// Атрибут, для вычисления которого нужен источник
        public let to: AttributeNode
    }
}
