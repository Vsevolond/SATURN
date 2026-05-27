//
//  TreeBuilder-Tests.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.05.2026.
//

import Testing

@testable import saturn_core

struct TreeBuilderTests {
    
    /// Простое правило сворачивается в узел с детьми по порядку
    @Test func plainRule() throws {
        /// Pair → a b
        let pair = Nonterm(name: "Pair")
        let alt = Alternative(
            elements: [
                .term("a"),
                .term("b")
            ]
        )
        pair.add(alt)
        
        let tree = try buildTree(
            axiom: pair,
            input: [
                lexeme("a", 0),
                lexeme("b", 1)
            ]
        )
        
        #expect(tree.symbol == "Pair")
        #expect(tree.children.count == 2)
        #expect(tree.start == 0)
        #expect(tree.end == 2)
        
        /// Оба ребенка — терминалы в порядке правой части
        guard case .token(let first) = tree.children[0] else {
            Issue.record("первый ребенок не терминал")
            return
        }
        
        guard case .token(let second) = tree.children[1] else {
            Issue.record("второй ребенок не терминал")
            return
        }
        
        #expect(first.name == "a")
        #expect(second.name == "b")
    }
    
    /// Неоднозначность снимается выбором первой семьи
    @Test func firstFamilyWins() throws {
        /// E → E + E | n — на n + n + n корень имеет две семьи, дерево берет первую
        let expr = Nonterm(name: "E")
        expr.add([
            Alternative(
                elements: [
                    .nonterm(expr),
                    .term("+"),
                    .nonterm(expr)
                ]
            ),
            Alternative(
                elements: [
                    .term("n")
                ]
            )
        ])
        
        let input = [
            lexeme("n", 0),
            lexeme("+", 1),
            lexeme("n", 2),
            lexeme("+", 3),
            lexeme("n", 4)
        ]
        let tree = try buildTree(axiom: expr, input: input)
        
        #expect(tree.symbol == "E")
        #expect(tree.start == 0)
        #expect(tree.end == 5)
        
        /// Дерево однозначно: ровно три ребенка E + E
        #expect(tree.children.count == 3)
        
        /// Средний ребенок — терминал +
        guard case .token(let plus) = tree.children[1] else {
            Issue.record("средний ребенок не оператор")
            return
        }
        
        #expect(plus.name == "+")
    }
    
    /// Повторение `%rep` схлопывается в один узел-список
    @Test func repetitionCollapses() throws {
        /// List → n %rep(+ n) — список из n через +
        let list = Nonterm(name: "List")
        let alt = Alternative(
            elements: [
                .term("n"),
                .repeat(
                    productions: [
                        .term("+"),
                        .term("n")
                    ],
                    optional: false
                )
            ]
        )
        list.add(alt)
        
        let input = [
            lexeme("n", 0),
            lexeme("+", 1),
            lexeme("n", 2),
            lexeme("+", 3),
            lexeme("n", 4)
        ]
        let tree = try buildTree(axiom: list, input: input)
        
        #expect(tree.symbol == "List")
        
        /// Ровно два ребенка: терминал n и узел-повторение — позиция $2 стабильна
        #expect(tree.children.count == 2)
        
        guard case .repetition(let repetition) = tree.children[1] else {
            Issue.record("второй ребенок не повторение")
            return
        }
        
        /// Вид сахара и арность перенесены из карты развертки
        #expect(repetition.kind == .repeatOneOrMore)
        #expect(repetition.arity == 2)
        
        /// Два вхождения: (+ n) и (+ n)
        #expect(repetition.items.count == 2)
        
        /// Границы покрывают оба витка целиком, а не только последний
        #expect(repetition.start == 1)
        #expect(repetition.end == 5)
        
        /// Каждое вхождение — символы детей одного витка
        for occurrence in repetition.items {
            #expect(occurrence.count == 2)
            
            guard case .token(let op) = occurrence[0] else {
                Issue.record("первый символ витка не оператор")
                return
            }
            
            #expect(op.name == "+")
        }
    }
    
    /// Пустое повторение `%rep[...]` дает узел без вхождений
    @Test func emptyRepetitionHasNoItems() throws {
        /// Seq → a %rep[b] — ноль и более b после a
        let seq = Nonterm(name: "Seq")
        let alt = Alternative(
            elements: [
                .term("a"),
                .repeat(
                    productions: [.term("b")],
                    optional: true
                )
            ]
        )
        seq.add(alt)
        
        /// Вход без единого b
        let tree = try buildTree(
            axiom: seq,
            input: [lexeme("a", 0)]
        )
        
        #expect(tree.children.count == 2)
        
        guard case .repetition(let repetition) = tree.children[1] else {
            Issue.record("второй ребенок не повторение")
            return
        }
        
        #expect(repetition.kind == .repeatZeroOrMore)
        #expect(repetition.items.isEmpty)
    }
    
    /// Свертка леса без корня сообщает об ошибке
    @Test func missingRootFails() throws {
        let forest = SPPForest()
        let builder = TreeBuilder(map: [:], productions: [])
        
        #expect(throws: TreeBuildError.missingRoot) {
            try builder.build(from: forest)
        }
    }
    
    /// Выпавший обычный обнуляемый нетерминал не занимает слот в children
    @Test func droppedOrdinaryNonterminalLeavesGap() throws {
        /// Greeting → sal Name punct
        /// Name → first | ε
        /// Name обнуляем явным ε и не является сахаром
        let name = Nonterm(name: "Name")
        name.add([
            Alternative(
                elements: [
                    .term("first")
                ]
            ),
            Alternative()
        ])

        let greeting = Nonterm(name: "Greeting")
        greeting.add(
            Alternative(
                elements: [
                    .term("sal"),
                    .nonterm(name),
                    .term("punct")
                ]
            )
        )

        /// Вход без Name: sal punct
        let tree = try buildTree(
            axiom: greeting,
            input: [
                lexeme("sal", 0),
                lexeme("punct", 1)
            ]
        )

        #expect(tree.symbol == "Greeting")

        /// Name выпал и не сахар — якоря нет, в children только два присутствующих символа
        #expect(tree.children.count == 2)

        guard case .token(let first) = tree.children[0] else {
            Issue.record("первый ребенок не терминал")
            return
        }
        guard case .token(let second) = tree.children[1] else {
            Issue.record("второй ребенок не терминал")
            return
        }

        /// Порядок сохранен: sal и punct, без пустого узла между ними
        #expect(first.name == "sal")
        #expect(second.name == "punct")
    }
    
    // MARK: - Private Methods
    
    /// Лексема терминала с тривиальной позицией
    private func lexeme(_ name: String, _ offset: Int) -> Lexeme {
        Lexeme(
            name: name,
            text: name,
            position: Position(
                line: 1,
                column: offset + 1,
                offset: offset
            )
        )
    }
    
    /// Прогоняет вход через весь конвейер и сворачивает результат в дерево
    private func buildTree(axiom: Nonterm, input: [Lexeme]) throws -> ParseTree {
        let (expanded, map) = SugarExpander().expand(axiom: axiom)
        let epsilonFree = try EpsilonEliminator().eliminate(expanded, map: map)
        let table = try ParseTable(epsilonFree.value, acceptsEmpty: epsilonFree.acceptsEmpty)
        
        let forest = try GLRParser(table: table, lexemes: input).parse()
        
        return try TreeBuilder(
            map: map,
            productions: table.productions
        )
        .build(from: forest)
    }
}
