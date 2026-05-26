//
//  SPPForest.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.05.2026.
//

import Foundation
 
/// Разделённый упакованный лес разбора
///
/// Узел помечен тройкой (символ, начало, конец)
/// Семья хранит полный список детей продукции и её номер
public final class SPPForest {
    
    // MARK: - Public Properties
    
    /// Корень разбора — узел аксиомы поверх всего входа
    public internal(set) var root: Node?
    
    // MARK: - Private Properties
    
    /// Кэш узлов по ключу
    private var nodes: [NodeKey: Node] = [:]
    
    // MARK: - Initializers
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Узел по ключу или `nil`, если такого нет
    public func node(symbol: GrammarSymbol, start: Int, end: Int) -> Node? {
        let key = NodeKey(symbol: symbol, start: start, end: end)
        return nodes[key]
    }
    
    /// Терминальный узел над лексемой, при повторном запросе возвращает тот же узел
    func terminalNode(symbol: GrammarSymbol, lexeme: Lexeme, start: Int, end: Int) -> Node {
        let key = NodeKey(symbol: symbol, start: start, end: end)
        
        if let existing = nodes[key] { return existing }
        
        let node = Node(terminal: symbol, lexeme: lexeme, start: start, end: end)
        nodes[key] = node
        
        return node
    }
    
    /// Нетерминальный узел над диапазоном, при повторном запросе возвращает тот же узел
    func nonterminalNode(symbol: GrammarSymbol, start: Int, end: Int) -> Node {
        let key = NodeKey(symbol: symbol, start: start, end: end)
        
        if let existing = nodes[key] { return existing }
        
        let node = Node(nonterminal: symbol, start: start, end: end)
        nodes[key] = node
        
        return node
    }
}

// MARK: - Extensions

extension SPPForest {
    
    // MARK: - Type Entities
    
    /// Семья детей узла: одна продукция и порядок порождённых узлов
    public struct Family: Equatable {
        
        // MARK: - Public Properties
        
        /// Номер свёрнутой продукции
        public let production: Int
        
        /// Дети в порядке правой части продукции
        public let children: [Node]
        
        // MARK: - Type Methods
        
        public static func == (lhs: Family, rhs: Family) -> Bool {
            guard lhs.production == rhs.production else { return false }
            guard lhs.children.count == rhs.children.count else { return false }
            
            return zip(lhs.children, rhs.children).allSatisfy { $0 === $1 }
        }
    }
}

extension SPPForest {
    
    // MARK: - Type Entities
    
    /// Узел леса: символ грамматики над диапазоном входа [start, end)
    public final class Node {
        
        // MARK: - Public Properties
        
        /// Символ грамматики, который покрывает узел
        public let symbol: GrammarSymbol
        
        /// Левая граница диапазона входа (номер позиции перед первой лексемой)
        public let start: Int
        
        /// Правая граница диапазона входа (номер позиции после последней лексемы)
        public let end: Int
        
        /// Лексема для терминального узла, `nil` у нетерминального
        public let lexeme: Lexeme?
        
        /// Семьи детей, пусто у терминала, одна и более у нетерминала
        public private(set) var families: [Family]
        
        /// Неоднозначен ли узел — выведен более чем одним способом
        public var isAmbiguous: Bool { families.count > 1 }
        
        // MARK: - Initializers
        
        /// Терминальный узел поверх лексемы
        init(terminal symbol: GrammarSymbol, lexeme: Lexeme, start: Int, end: Int) {
            self.symbol = symbol
            self.lexeme = lexeme
            self.start = start
            self.end = end
            self.families = []
        }
        
        /// Нетерминальный узел без семей; семьи добавляются по мере свёрток
        init(nonterminal symbol: GrammarSymbol, start: Int, end: Int) {
            self.symbol = symbol
            self.lexeme = nil
            self.start = start
            self.end = end
            self.families = []
        }
        
        // MARK: - Internal Methods
        
        /// Добавляет семью, если такой ещё нет
        func add(_ family: Family) {
            guard !families.contains(family) else { return }
            
            families.append(family)
        }
    }
}

// MARK: - Private Extensions

private extension SPPForest {
    
    // MARK: - Type Entities
    
    /// Ключ узла для разделения: символ и границы диапазона определяют узел однозначно
    struct NodeKey: Hashable {
        
        // MARK: - Internal Properties
        
        let symbol: GrammarSymbol
        let start: Int
        let end: Int
    }
}
