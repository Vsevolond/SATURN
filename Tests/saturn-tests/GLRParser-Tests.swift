//
//  GLRParser-Tests.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.05.2026.
//

import Testing

@testable import saturn_core

/// Тесты GLR-разбора на эталонной неоднозначной грамматике E → E + E | n
/// Грамматика дает конфликт перенос/свертка в ячейке [4, +]
struct GLRParserTests {
    
    /// Одиночный операнд принимается
    @Test func singleOperand() throws {
        let table = try sumTable()
        let lexemes = sumInput(operands: 1)
        let parser = try GLRParser(table: table, lexemes: lexemes)
        
        let forest = try parser.parse()
        let root = try #require(forest.root)
        
        #expect(root.symbol == .nonterminal("E"))
        #expect(root.start == 0)
        #expect(root.end == 1)
        #expect(root.isAmbiguous == false)
    }
    
    /// Цепочка n + n принимается и однозначна
    @Test func twoOperands() throws {
        let table = try sumTable()
        let lexemes = sumInput(operands: 2)
        let parser = try GLRParser(table: table, lexemes: lexemes)
        
        let forest = try parser.parse()
        let root = try #require(forest.root)
        
        #expect(root.symbol == .nonterminal("E"))
        #expect(root.start == 0)
        #expect(root.end == 3)
        #expect(root.isAmbiguous == false)
        #expect(root.families.count == 1)
    }
    
    /// Цепочка n + n + n дает ровно две семьи в корне
    @Test func threeOperandsAreAmbiguous() throws {
        let table = try sumTable()
        let lexemes = sumInput(operands: 3)
        let parser = try GLRParser(table: table, lexemes: lexemes)
        
        let forest = try parser.parse()
        let root = try #require(forest.root)
        
        #expect(root.symbol == .nonterminal("E"))
        #expect(root.start == 0)
        #expect(root.end == 5)
        #expect(root.isAmbiguous)
        #expect(root.families.count == 2)
    }
    
    /// Обе семьи корня покрывают весь вход, но дробят его по-разному
    @Test func bothFamiliesSplitDifferently() throws {
        let table = try sumTable()
        let lexemes = sumInput(operands: 3)
        let parser = try GLRParser(table: table, lexemes: lexemes)
        
        let forest = try parser.parse()
        let root = try #require(forest.root)
        
        /// В каждой семье ровно три ребенка: E + E
        for family in root.families {
            #expect(family.children.count == 3)
            #expect(family.children[1].symbol == .terminal("+"))
        }
        
        /// Левая граница среднего плюса различает левую и правую ассоциативность:
        /// левоассоциативная семья делит вход после второго плюса [3,4],
        /// правоассоциативная — после первого [1,2]
        let plusPositions = Set(root.families.map { $0.children[1].start })
        #expect(plusPositions == [1, 3])
    }
    
    /// Поддеревья операндов разделяются между семьями
    @Test func operandSubtreesAreShared() throws {
        let table = try sumTable()
        let lexemes = sumInput(operands: 3)
        let parser = try GLRParser(table: table, lexemes: lexemes)
        
        let forest = try parser.parse()
        let root = try #require(forest.root)
        
        /// Узел E[4,5] (последний операнд) встречается в обеих трактовках
        let leftAssociative = root.families.first { $0.children[1].start == 3 }
        let rightAssociative = root.families.first { $0.children[1].start == 1 }
        
        let leftLastOperand = try #require(leftAssociative?.children[2])
        
        /// В правоассоциативной семье последний операнд спрятан внутри правого E[2,5]
        let rightInner = try #require(rightAssociative?.children[2])
        let rightInnerFamily = try #require(rightInner.families.first)
        let rightLastOperand = rightInnerFamily.children[2]
        
        #expect(leftLastOperand === rightLastOperand)
    }
    
    /// Незавершенная цепочка отвергается
    @Test func danglingOperatorFails() throws {
        let table = try sumTable()
        let broken = [lexeme("n", "n", 0), lexeme("+", "+", 1)]
        let parser = try GLRParser(table: table, lexemes: broken)
        
        #expect(throws: GLRParseError.self) {
            try parser.parse()
        }
    }
    
    /// Лишний операнд без оператора отвергается на нем
    @Test func missingOperatorFails() throws {
        let table = try sumTable()
        let broken = [lexeme("n", "n", 0), lexeme("n", "n", 1)]
        let parser = try GLRParser(table: table, lexemes: broken)
        
        #expect(throws: GLRParseError.self) {
            try parser.parse()
        }
    }
    
    /// Пустой вход отвергается, если язык не допускает пустую цепочку
    @Test func emptyInputFails() throws {
        let table = try sumTable()
        let parser = try GLRParser(table: table, lexemes: [])
        
        #expect(throws: GLRParseError.unexpectedEmptyInput) {
            try parser.parse()
        }
    }
    
    // MARK: - Private Methods
    
    /// Лексема терминала с тривиальной позицией
    private func lexeme(_ name: String, _ text: String, _ offset: Int) -> Lexeme {
        Lexeme(
            name: name,
            text: text,
            position: Position(
                line: 1,
                column: offset + 1,
                offset: offset
            )
        )
    }
    
    /// Поток лексем для цепочки вида n + n + ... из count операндов
    private func sumInput(operands count: Int) -> [Lexeme] {
        var result: [Lexeme] = []
        var offset = 0
        
        for index in 0..<count {
            result.append(lexeme("n", "n", offset))
            offset += 1
            
            if index < count - 1 {
                result.append(lexeme("+", "+", offset))
                offset += 1
            }
        }
        
        return result
    }
    
    /// Таблица для грамматики E → E + E | n из строкового описания через готовый конвейер
    private func sumTable() throws -> ParseTable {
        let nonterm = Nonterm(name: "E")
        
        /// E → E + E
        let recursive = Alternative(
            elements: [.nonterm(nonterm), .term("+"), .nonterm(nonterm)],
            actions: []
        )
        
        /// E → n
        let atom = Alternative(elements: [.term("n")], actions: [])
        
        nonterm.add(recursive)
        nonterm.add(atom)
        
        let (expanded, _) = SugarExpander().expand(axiom: nonterm)
        let epsilonFree = try EpsilonEliminator().eliminate(expanded)
        
        return try ParseTable(epsilonFree.value, acceptsEmpty: epsilonFree.acceptsEmpty)
    }
}
