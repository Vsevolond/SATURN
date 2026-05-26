//
//  ParseTree.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.05.2026.
//

import Foundation
 
/// Дерево разбора с пользовательской структурой правил
///
/// Строится из SPPF сверткой:
/// - служебные нетерминалы развертки сахара схлопываются
/// - неоднозначность снимается выбором первой семьи
public final class ParseTree {
    
    // MARK: - Public Properties
    
    /// Нетерминал левой части правила
    public let symbol: String
    
    /// Номер свернутой продукции
    public let production: Int
    
    /// Дети в порядке правой части правила
    public let children: [Child]
    
    /// Левая граница диапазона входа (позиция перед первой лексемой поддерева)
    public let start: Int
    
    /// Правая граница диапазона входа (позиция после последней лексемы поддерева)
    public let end: Int
    
    // MARK: - Initializers
    
    init(symbol: String, production: Int, children: [Child], start: Int, end: Int) {
        self.symbol = symbol
        self.production = production
        self.children = children
        self.start = start
        self.end = end
    }
}
 
// MARK: - Extensions
 
extension ParseTree {
    
    // MARK: - Type Entities
    
    /// Ребенок узла дерева — символ правой части правила
    public enum Child {
        
        // MARK: - Cases
        
        /// Вложенный нетерминал — поддерево
        case tree(ParseTree)
        
        /// Терминал — лист с исходной лексемой
        case token(Lexeme)
        
        /// Схлопнутое повторение или опционал на месте служебного нетерминала
        case repetition(Repetition)
    }
}
 
extension ParseTree {
    
    // MARK: - Type Entities
    
    /// Схлопнутая конструкция сахара: повторение `%rep` или опционал `[...]`
    public struct Repetition {
        
        // MARK: - Public Properties
        
        /// Вид породившей конструкции сахара
        public let kind: SugarType
        
        /// Число детей в одном вхождении
        public let arity: Int
        
        /// Вхождения по порядку, каждое — дети одного витка повторения
        public let items: [[Child]]
        
        /// Левая граница диапазона входа, покрытого конструкцией
        public let start: Int
        
        /// Правая граница диапазона входа, покрытого конструкцией
        public let end: Int
        
        // MARK: - Initializers
        
        init(kind: SugarType, arity: Int, items: [[Child]], start: Int, end: Int) {
            self.kind = kind
            self.arity = arity
            self.items = items
            self.start = start
            self.end = end
        }
    }
}
