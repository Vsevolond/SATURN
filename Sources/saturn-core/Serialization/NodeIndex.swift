//
//  NodeIndex.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 28.05.2026.
//

import Foundation
 
/// Двухсистемная нумерация узлов дерева для согласованного именования в выводах
public final class NodeIndex {
    
    // MARK: - Private Properties
    
    /// Имена нетерминалов в графе по идентичности узла дерева
    private var nonterminals: [ObjectIdentifier: String] = [:]
    
    /// Имена токенов в графе по позиции лексемы
    private var tokens: [TokenKey: String] = [:]
    
    // MARK: - Initializers
    
    /// Готовит индекс по дереву: два прохода для определения, какие символы повторяются
    public init(root: ParseTree) {
        let counts = countOccurrences(in: root)
        var counters: [String: Int] = [:]
        
        assign(tree: root, counts: counts, counters: &counters)
    }
    
    // MARK: - Public Methods
    
    /// Имя нетерминала в JSON-дереве — просто `symbol`, без индекса
    public func treeName(of tree: ParseTree) -> String { tree.symbol }
    
    /// Имя токена в JSON-дереве — `Lexeme.name` без индекса
    public func treeName(of token: Lexeme) -> String { token.name }
    
    /// Имя нетерминала в графе — с индексом, если символ встречается в дереве больше раза
    public func graphName(of tree: ParseTree) -> String {
        let identity = ObjectIdentifier(tree)
        return nonterminals[identity] ?? tree.symbol
    }
    
    /// Имя токена в графе — с индексом при повторе, иначе как `Lexeme.name`
    public func graphName(of token: Lexeme) -> String {
        let key = TokenKey(token)
        return tokens[key] ?? token.name
    }
    
    // MARK: - Private Methods
    
    /// Первый проход — подсчет встречаемости каждого имени символа в дереве
    private func countOccurrences(in tree: ParseTree) -> [String: Int] {
        var counts: [String: Int] = [:]
        count(tree: tree, into: &counts)
        
        return counts
    }
    
    /// Рекурсивно учитывает каждый символ — нетерминал или токен
    private func count(tree: ParseTree, into counts: inout [String: Int]) {
        counts[tree.symbol, default: 0] += 1
        
        for child in tree.children { count(child: child, into: &counts) }
    }
    
    /// Учет ребенка дерева по его виду, повторение разворачивается в плоский список
    private func count(child: ParseTree.Child, into counts: inout [String: Int]) {
        switch child {
        case .tree(let subtree):
            count(tree: subtree, into: &counts)
            
        case .token(let lexeme):
            counts[lexeme.name, default: 0] += 1
            
        case .repetition(let repetition):
            /// Витки разворачиваются как обычные дети
            for occurrence in repetition.items {
                for nested in occurrence { count(child: nested, into: &counts) }
            }
        }
    }
    
    /// Второй проход — раздает имена в графе, добавляя индекс только при повторе
    private func assign(
        tree: ParseTree,
        counts: [String: Int],
        counters: inout [String: Int]
    ) {
        let identity = ObjectIdentifier(tree)
        
        nonterminals[identity] = name(for: tree.symbol, counts: counts, counters: &counters)
        
        for child in tree.children {
            assign(child: child, counts: counts, counters: &counters)
        }
    }
    
    /// Раздача имени ребенку дерева в зависимости от его вида
    private func assign(
        child: ParseTree.Child,
        counts: [String: Int],
        counters: inout [String: Int]
    ) {
        switch child {
        case .tree(let subtree):
            assign(tree: subtree, counts: counts, counters: &counters)
            
        case .token(let lexeme):
            let key = TokenKey(lexeme)
            
            tokens[key] = name(for: lexeme.name, counts: counts, counters: &counters)
            
        case .repetition(let repetition):
            /// Витки разворачиваются плоско — каждый их элемент именуется как обычный ребенок
            for occurrence in repetition.items {
                for nested in occurrence {
                    assign(child: nested, counts: counts, counters: &counters)
                }
            }
        }
    }
    
    /// Имя с индексом, если символ встречается в дереве больше одного раза, иначе как есть
    private func name(
        for base: String,
        counts: [String: Int],
        counters: inout [String: Int]
    ) -> String {
        /// Один раз — без индекса, иначе — счетчик от нуля
        guard let total = counts[base], total > 1 else { return base }
        
        let index = counters[base, default: 0]
        counters[base] = index + 1
        
        return "\(base)_\(index)"
    }
}

// MARK: - Extensions

extension NodeIndex {
    
    // MARK: - Type Entities
    
    /// Ключ токена для идентификации по позиции во входе
    public struct TokenKey: Hashable {
        
        // MARK: - Public Properties
        
        public let line: Int
        public let column: Int
        public let offset: Int
        
        // MARK: - Initializers
        
        public init(_ lexeme: Lexeme) {
            self.line = lexeme.position.line
            self.column = lexeme.position.column
            self.offset = lexeme.position.offset
        }
    }
}
