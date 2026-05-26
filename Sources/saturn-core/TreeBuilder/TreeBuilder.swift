//
//  TreeBuilder.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.05.2026.
//

import Foundation
 
/// Свертка леса разбора в дерево пользовательской структуры
///
/// Неоднозначность снимается выбором первой семьи каждого узла
/// Служебные нетерминалы развертки сахара не попадают в дерево
public struct TreeBuilder {
    
    // MARK: - Private Properties
    
    /// Карта развертки: имя служебного нетерминала → описание породившего сахара
    private let map: ExpansionMap
    
    /// Занумерованные продукции — по номеру свёрнутого правила доступны метки выпавшего сахара
    private let productions: [NumberedProduction]
    
    // MARK: - Initializers
    
    public init(map: ExpansionMap, productions: [NumberedProduction]) {
        self.map = map
        self.productions = productions
    }
    
    // MARK: - Public Methods
    
    /// Сворачивает лес в дерево, начиная с его корня
    public func build(from forest: SPPForest) throws -> ParseTree {
        /// Без корня разбора нет — приема не было
        guard let root = forest.root else { throw TreeBuildError.missingRoot }
        
        return try tree(from: root)
    }
    
    // MARK: - Private Methods
    
    /// Строит поддерево из узла-нетерминала по его первой семье
    private func tree(from node: SPPForest.Node) throws -> ParseTree {
        /// Первая семья — выбранный разбор, ею снимается неоднозначность узла
        guard let family = node.families.first else {
            /// Нетерминал без семей бывает только в поврежденном лесу
            let name = name(of: node.symbol)
            
            throw TreeBuildError.emptyNode(
                symbol: name,
                start: node.start,
                end: node.end
            )
        }
        
        /// Дети в порядке правой части правила
        var children: [ParseTree.Child] = []
        
        for child in family.children {
            /// Служебный нетерминал развертки не идет в дерево узлом — его раскручивает родитель
            if let site = support(of: child) {
                /// Гребенка повторения схлопывается в один узел-контейнер на месте символа
                let repetition = try collapse(child, site: site)
                children.append(.repetition(repetition))
                
            } else {
                /// Обычный символ — терминал-лист или вложенное поддерево
                let parsed = try makeChild(child)
                children.append(parsed)
            }
        }
        
        /// Левая часть продукции — пользовательский нетерминал этого узла
        let name = name(of: node.symbol)
        
        /// Восстанавливаем пустые повторения, выпавшие при устранении ε
        let restored = restore(
            children: children,
            production: family.production,
            end: node.end
        )
        
        return ParseTree(
            symbol: name,
            production: family.production,
            children: restored,
            start: node.start,
            end: node.end
        )
    }
    
    /// Вставляет пустые узлы-повторения на места выпавшего при устранении ε сахара
    private func restore(
        children: [ParseTree.Child],
        production: Int,
        end: Int
    ) -> [ParseTree.Child] {
        let dropped = productions[production].dropped
        
        /// Обычное правило без выпавшего сахара — детей не трогаем
        guard !dropped.isEmpty else { return children }
        
        var restored = children
        
        for sugar in dropped.sorted(by: { $0.position < $1.position }) {
            /// Описание сахара берём из карты; без него вставлять нечего
            guard let site = map[sugar.name] else { continue }
            
            /// Пустое повторение не покрывает лексем — вырожденный диапазон на крае узла
            let empty = ParseTree.Repetition(
                kind: site.type,
                arity: site.arity,
                items: [],
                start: end,
                end: end
            )
            
            restored.insert(
                .repetition(empty),
                at: min(sugar.position, restored.count)
            )
        }
        
        return restored
    }
    
    /// Превращает обычный дочерний узел в ребенка:
    /// - терминал в лист
    /// - нетерминал в поддерево
    private func makeChild(_ node: SPPForest.Node) throws -> ParseTree.Child {
        /// Терминальный узел несет лексему — это лист
        if let lexeme = node.lexeme { return .token(lexeme) }
        
        /// Служебный сюда попасть не должен: его перехватывает вызывающий до makeChild
        if support(of: node) != nil {
            let name = name(of: node.symbol)
            throw TreeBuildError.unexpectedSupport(name: name)
        }
        
        /// Обычный нетерминал — вложенное поддерево
        let tree = try tree(from: node)
        return .tree(tree)
    }
    
    /// Схлопывает правую гребенку служебного нетерминала в один узел-повторение
    /// Развертка строит повторение праворекурсивно: `A → X | X A` либо `A → ε | X A`,
    /// Идем по хвостам, на каждом витке снимая ведущие символы как одно вхождение, пока хвост не упрется в базу
    private func collapse(_ node: SPPForest.Node, site: SugarSite) throws -> ParseTree.Repetition {
        /// Имя гребенки — по нему опознаем рекурсивный хвост среди детей витка
        let supportName = name(of: node.symbol)
        
        /// Вхождения в порядке витков
        var items: [[ParseTree.Child]] = []
        
        /// Узел текущего витка, `nil` означает, что хвостов больше нет
        var current: SPPForest.Node? = node
        
        while let curr = current {
            /// Виток разбираем по первой семье, как и обычный узел
            guard let family = curr.families.first else {
                throw TreeBuildError.emptyNode(
                    symbol: supportName,
                    start: curr.start,
                    end: curr.end
                )
            }
            
            /// Дети витка целиком, из них отделяем рекурсивный хвост
            var body = family.children
            
            /// Хвост следующего витка, если правило рекурсивно
            var tail: SPPForest.Node? = nil
            
            /// Последний символ — рекурсивный хвост той же гребенки, отделяем его от тела
            if let last = body.last, name(of: last.symbol) == supportName {
                tail = last
                body.removeLast()
            }
            
            /// Пустое тело — вхождения нет, раскрутка завершена
            if body.isEmpty { break }
            
            /// Оставшееся тело без хвоста — одно вхождение повторения
            let group = try body.map { try makeChild($0) }
            items.append(group)
            
            current = tail
        }
        
        /// Границы берем у исходного узла гребенки
        return ParseTree.Repetition(
            kind: site.type,
            arity: site.arity,
            items: items,
            start: node.start,
            end: node.end
        )
    }
    
    /// Описание сахара, если узел — служебный нетерминал развертки, иначе `nil`
    private func support(of node: SPPForest.Node) -> SugarSite? {
        /// У терминала имени-нетерминала нет
        guard node.lexeme == nil else { return nil }
        
        let name = name(of: node.symbol)
        /// Служебность определяется наличием в карте развертки
        return map[name]
    }
    
    /// Имя символа для левой части и свертки со служебными именами
    private func name(of symbol: GrammarSymbol) -> String {
        switch symbol {
        case .terminal(let name): return name
        case .nonterminal(let name): return name
        case .end: return ""
        }
    }
}
