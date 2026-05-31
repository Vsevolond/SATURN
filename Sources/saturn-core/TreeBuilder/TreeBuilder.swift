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
    
    /// Занумерованные продукции — по номеру свернутого правила доступны метки выпавшего сахара
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
        
        /// Дети в порядке правой части правила, вложенный сахар разворачивается рекурсивно
        var children: [ParseTree.Child] = []
        
        for element in family.children {
            let child = try child(from: element)
            children.append(child)
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
    
    /// Превращает узел леса в ребенка дерева
    ///
    /// Единая точка для детей обычного узла и для тела витка повторения:
    /// - служебный нетерминал развертки схлопывается в `Repetition` (в том числе вложенный)
    /// - терминал становится листом-токеном
    /// - обычный нетерминал — вложенным поддеревом
    /// Рекурсия через collapse → child(from:) обрабатывает вложенный сахар любой глубины:
    /// повторение в повторении, опционал в повторении, повторение в опционале, опционал в опционале
    private func child(from node: SPPForest.Node) throws -> ParseTree.Child {
        /// Служебный нетерминал — схлопываем его гребенку в узел-повторение
        if let site = support(of: node) {
            let repetition = try collapse(node, site: site)
            return .repetition(repetition)
        }
        
        /// Обычный символ — терминал-лист или вложенное поддерево
        return try makeChild(node)
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
        
        /// Исходная длина правой части — присутствующие + все выпавшие
        let total = children.count + dropped.count
        
        /// Слоты выпавших символов по исходным позициям
        var droppedAt: [Int: Alternative.DroppedSymbol] = [:]
        
        for symbol in dropped { droppedAt[symbol.position] = symbol }
        
        var restored: [ParseTree.Child] = []
        var next = 0
        
        for position in 0..<total {
            /// Выпавший символ на этой позиции
            if let symbol = droppedAt[position] {
                /// Сахар получает пустой узел-якорь, обычный символ слот не занимает
                if let site = map[symbol.name] {
                    let empty = ParseTree.Repetition(
                        kind: site.type,
                        arity: site.arity,
                        items: [],
                        start: end,
                        end: end
                    )
                    
                    restored.append(.repetition(empty))
                }
                
                continue
            }
            
            /// Присутствующий символ — берем следующего фактического ребенка
            let child = children[next]
            
            restored.append(child)
            next += 1
        }
        
        return restored
    }
    
    /// Превращает обычный дочерний узел в ребенка:
    /// - терминал в лист
    /// - нетерминал в поддерево
    private func makeChild(_ node: SPPForest.Node) throws -> ParseTree.Child {
        /// Терминальный узел несет лексему — это лист
        if let lexeme = node.lexeme { return .token(lexeme) }
        
        /// Служебный сюда попасть не должен: его перехватывает child(from:) до makeChild
        if support(of: node) != nil {
            let name = name(of: node.symbol)
            throw TreeBuildError.unexpectedSupport(name: name)
        }
        
        /// Обычный нетерминал — вложенное поддерево
        let tree = try tree(from: node)
        return .tree(tree)
    }
    
    /// Схлопывает правую гребенку служебного нетерминала в один узел-повторение
    ///
    /// Развертка строит повторение праворекурсивно: `%rep(X)` → `A → X | X A`,
    /// `%rep[X]` → `A → ε | X A`. Идем по хвостам, на каждом витке снимая ведущие
    /// символы как одно вхождение, пока хвост не упрется в базу:
    /// - для `%rep(...)` база — нерекурсивная альтернатива `X`
    /// - для `%rep[...]` база — пустое тело (бывшая ε-альтернатива) → break
    /// Тело витка может содержать вложенный сахар — он разворачивается тем же
    /// child(from:), поэтому вложенность работает на любую глубину
    private func collapse(_ node: SPPForest.Node, site: SugarSite) throws -> ParseTree.Repetition {
        /// Обертка ноль-или-один над гребенкой: раскрываем внутреннюю гребенку,
        /// ее витки становятся витками этого повторения ноль-и-более
        guard !site.isZeroWrapper else {
            return try collapseZeroWrapper(node, site: site)
        }
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
            
            /// Последний символ — рекурсивный хвост ИМЕННО этой гребенки
            /// Сверяем и имя, и служебность: вложенная гребенка имеет свое имя
            /// и снимается своим collapse, чужой хвост сюда не попадет
            if let last = body.last,
               name(of: last.symbol) == supportName,
               support(of: last) != nil
            {
                tail = last
                body.removeLast()
            }
            
            /// Пустое тело — база достигнута, раскрутка завершена.
            if body.isEmpty { break }
            
            /// Тело витка без хвоста — одно вхождение; вложенный сахар сворачивается рекурсивно
            let group = try body.map { try child(from: $0) }
            
            /// Восстанавливаем выпавший при устранении ε сахар тела витка,
            /// чтобы число позиций совпадало с формой группы на всех витках
            let restored = restore(
                children: group,
                production: family.production,
                end: curr.end
            )
            
            items.append(restored)
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
    
    /// Сворачивает обертку `%rep[...]` (ноль-или-один над гребенкой) в плоское повторение ноль-и-более:
    /// пустая альтернатива — ноль витков, непустая — витки вложенной гребенки, поднятые на этот уровень
    private func collapseZeroWrapper(
        _ node: SPPForest.Node,
        site: SugarSite
    ) throws -> ParseTree.Repetition {
        guard let family = node.families.first else {
            throw TreeBuildError.emptyNode(
                symbol: name(of: node.symbol),
                start: node.start,
                end: node.end
            )
        }
        
        /// Пустая альтернатива обертки — ноль витков
        guard let inner = family.children.first else {
            return ParseTree.Repetition(
                kind: .repeatZeroOrMore,
                arity: site.arity,
                items: [],
                start: node.start,
                end: node.end
            )
        }
        
        /// Непустая альтернатива: единственный символ — вложенная гребенка один-и-более
        /// Сворачиваем ее и поднимаем ее витки как свои
        guard let innerSite = support(of: inner) else {
            throw TreeBuildError.unexpectedSupport(name: name(of: inner.symbol))
        }
        
        let nested = try collapse(inner, site: innerSite)
        
        return ParseTree.Repetition(
            kind: .repeatZeroOrMore,
            arity: nested.arity,
            items: nested.items,
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
