//
//  GSStack.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.05.2026.
//

import Foundation
 
/// Граф-структурированный стек
///
/// Вершина — пара (LR-состояние, позиция входа)
/// Ребро направлено к более раннему по разбору хвосту и несет узел SPPF
public final class GSStack {
    
    // MARK: - Private Properties
    
    /// Вершины по уровням: позиция → (состояние → вершина)
    private var levels: [Int: [Int: Vertex]] = [:]
    
    /// Глобальный счетчик идентификаторов ребер
    private var counter: Int = 0
    
    // MARK: - Public Methods
    
    /// Вершины уровня позиции в произвольном порядке
    public func vertices(at position: Int) -> [Vertex] {
        guard let level = levels[position] else { return [] }
        return Array(level.values)
    }
    
    /// Вершина состояния на уровне позиции или `nil`
    public func vertex(state: Int, position: Int) -> Vertex? {
        guard let level = levels[position] else { return nil }
        return level[state]
    }
    
    /// Возвращает вершину состояния на уровне, создавая ее при отсутствии
    /// Возвращает `true`, если вершина создана, и `false`, если нет
    @discardableResult
    func obtainVertex(state: Int, position: Int) -> (vertex: Vertex, created: Bool) {
        if let level = levels[position],
           let existing = level[state]
        {
            return (existing, false)
        }
        
        let vertex = Vertex(state: state, position: position)
        levels[position, default: [:]][state] = vertex
        
        return (vertex, true)
    }
    
    /// Соединяет вершину с хвостом ребром, несущим узел SPPF
    /// Выдает ребру стабильный идентификатор
    /// Возвращает `true`, если ребро новое
    @discardableResult
    func connect(_ vertex: Vertex, to tail: Vertex, carrying node: SPPForest.Node) -> Bool {
        let id = counter
        let added = vertex.addEdge(to: tail, carrying: node, id: id)
        
        if added { counter += 1 }
        
        return added
    }
}

// MARK: - Extensions

extension GSStack {
    
    // MARK: - Type Entities
    
    /// Ребро GSS: ссылка на вершину-хвост и узел SPPF, который лежит на стеке
    public struct Edge {
        
        /// Вершина, к которой ведет ребро (более ранний хвост стека)
        public let target: Vertex
        
        /// Узел SPPF, помещенный на стек при переносе или свертке
        public let node: SPPForest.Node
        
        /// Стабильный идентификатор ребра
        public let id: Int
    }
}

extension GSStack {
    
    // MARK: - Type Entities
    
    /// Вершина GSS: LR-состояние на конкретной позиции входа
    public final class Vertex {
        
        // MARK: - Public Properties
        
        /// LR-состояние анализатора
        public let state: Int
        
        /// Позиция входа, на которой живет вершина (номер обработанной границы)
        public let position: Int
        
        /// Исходящие ребра к хвостам стека
        public private(set) var edges: [Edge]
        
        // MARK: - Initializers
        
        init(state: Int, position: Int) {
            self.state = state
            self.position = position
            self.edges = []
        }
        
        // MARK: - Public Methods
        
        /// Добавляет ребро к хвосту, не допуская дубля по той же паре (хвост, узел)
        /// Возвращает `true`, если ребро новое.
        @discardableResult
        func addEdge(to target: Vertex, carrying node: SPPForest.Node, id: Int) -> Bool {
            let isDuplicate = edges.contains { $0.target === target && $0.node === node }
            
            guard !isDuplicate else { return false }
            
            edges.append(Edge(target: target, node: node, id: id))
            return true
        }
    }
}
