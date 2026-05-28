//
//  DependencyGraph+DOT.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 28.05.2026.
//

import Foundation
import GraphViz
 
extension DependencyGraph {
    
    // MARK: - Public Methods
    
    /// Сериализует граф в текст формата DOT
    ///
    /// Узлы подписываются именем атрибута
    /// Овал — синтезированный атрибут
    /// Прямоугольник — наследуемый атрибут
    /// Шестиугольник — атрибут токена
    public func toDOT() -> String {
        var graph = Graph(directed: true)
        graph.rankDirection = .leftToRight
        
        /// Узлы графа: каждый получает идентификатор и подпись с владельцем и атрибутом
        for attribute in nodes {
            var node = Node(id(of: attribute))
            node.label = label(of: attribute)
            node.shape = shape(of: attribute)
            
            graph.append(node)
        }
        
        /// Ребра графа: от прочитанного атрибута к вычисляемому
        for edge in edges {
            let connector = GraphViz.Edge(
                from: id(of: edge.from),
                to: id(of: edge.to)
            )
            
            graph.append(connector)
        }
        
        return DOTEncoder().encode(graph)
    }
    
    // MARK: - Private Methods
    
    /// Идентификатор узла DOT — повторяет естественное имя атрибута
    private func id(of attribute: AttributeNode) -> String {
        "\(attribute.owner).\(attribute.attribute)"
    }
    
    /// Подпись узла на схеме — носитель и атрибут на одной строке
    private func label(of attribute: AttributeNode) -> String {
        "\(attribute.owner)\n\(attribute.attribute)"
    }
    
    /// Форма узла различает вид атрибута и принадлежность токену
    private func shape(of attribute: AttributeNode) -> Node.Shape {
        switch attribute.kind {
        case .token:
            /// Атрибуты токенов — листья графа
            return .hexagon
            
        case .inherited:
            /// Наследуемый атрибут принимает значение от родителя
            return .box
            
        case .synthesized:
            /// Синтезированный вычисляется из детей или собственного правила
            return .ellipse
        }
    }
}
