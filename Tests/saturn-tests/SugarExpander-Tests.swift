//
//  SugarExpander-Tests.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 24.05.2026.
//

import Testing

@testable import saturn_core
 
struct SugarExpanderTests {
    
    /// `%rep(B)` разворачивается в пару правил «один и более»: `S → B | B S`
    @Test func testRepeatOneOrMore() {
        let s = Nonterm(name: "S")
        let alt = Alternative(
            elements: [
                .repeat(
                    productions: [.term("B")],
                    optional: false
                )
            ]
        )
        s.add(alt)
        
        let result = SugarExpander().expand(axiom: s)
        let rules = ruleSet(result.grammar)
        
        #expect(rules["S"] == ["S_rep_0"])
        #expect(rules["S_rep_0"] == ["B", "B S_rep_0"])
        #expect(rules["S_rep_0"]?.contains("ε") == false)
    }
    
    /// Карта помечает служебный нетерминал как `repeatOneOrMore` с арностью 1
    @Test func testRepeatOneOrMoreSite() {
        let s = Nonterm(name: "S")
        let alt = Alternative(
            elements: [
                .repeat(
                    productions: [.term("B")],
                    optional: false
                )
            ]
        )
        s.add(alt)
        
        let result = SugarExpander().expand(axiom: s)
        
        #expect(result.map["S_rep_0"] == SugarSite(type: .repeatOneOrMore, arity: 1))
    }
    
    /// `%rep[B]` разворачивается в правила `repeatzeroOrMore`: `S → ε | B S`
    @Test func testRepeatZeroOrMore() {
        let s = Nonterm(name: "S")
        let alt = Alternative(
            elements: [
                .repeat(
                    productions: [.term("B")],
                    optional: true
                )
            ]
        )
        s.add(alt)
        
        let result = SugarExpander().expand(axiom: s)
        let rules = ruleSet(result.grammar)
        
        #expect(rules["S"] == ["S_rep_0"])
        #expect(rules["S_rep_0"] == ["ε", "B S_rep_0"])
        #expect(result.map["S_rep_0"] == SugarSite(type: .repeatZeroOrMore, arity: 1))
    }
    
    /// `[B]` разворачивается в пару альтернатив: `S → B | ε`
    @Test func testOptional() {
        let s = Nonterm(name: "S")
        let alt = Alternative(
            elements: [
                .optional(
                    productions: [.term("B")]
                )
            ]
        )
        s.add(alt)
        
        let result = SugarExpander().expand(axiom: s)
        let rules = ruleSet(result.grammar)
        
        #expect(rules["S"] == ["S_opt_0"])
        #expect(rules["S_opt_0"] == ["B", "ε"])
        #expect(result.map["S_opt_0"] == SugarSite(type: .optional, arity: 1))
    }
    
    /// Группа из нескольких символов даёт арность по числу символов вхождения
    @Test func testGroupArity() {
        let s = Nonterm(name: "S")
        let alt = Alternative(
            elements: [
                .repeat(
                    productions: [
                        .term("C"),
                        .term("D")
                    ],
                    optional: false
                )
            ]
        )
        s.add(alt)
        
        let result = SugarExpander().expand(axiom: s)
        let rules = ruleSet(result.grammar)
        
        #expect(rules["S_rep_0"] == ["C D", "C D S_rep_0"])
        #expect(result.map["S_rep_0"] == SugarSite(type: .repeatOneOrMore, arity: 2))
    }
    
    /// Сквозная нумерация: символы внутри конструкции вливаются в плоскую нумерацию правила
    /// Действия исходной альтернативы переносятся без изменений
    @Test func testSemanticActionsAndArityPreserved() {
        let action = Statement.assignment(
            reference: Reference(target: 0, attribute: "v"),
            value: .attribute(
                reference: Reference(target: 1, attribute: "v")
            )
        )
        
        let s = Nonterm(name: "S")
        let alt = Alternative(
            elements: [
                .term("A"),
                .repeat(
                    productions: [.term("B")],
                    optional: false
                ),
                .term("C")
            ],
            actions: [action]
        )
        s.add(alt)
        
        let result = SugarExpander().expand(axiom: s)
        
        let alternative = result.grammar.axiom.disclosures[0]
        /// Три позиции в правой части: A, служебный нетерминал, C
        #expect(alternative.elements.count == 3)
        #expect(alternative.actions == [action])
    }
    
    /// Вложенный сахар `[A %rep(B)] C` разворачивается рекурсивно
    @Test func testNestedSugar() {
        let repeatB = Production.repeat(
            productions: [
                .term("B")
            ],
            optional: false
        )
        let optional = Production.optional(
            productions: [
                .term("A"),
                repeatB
            ]
        )
        
        let expr = Nonterm(name: "Expr")
        let alt = Alternative(
            elements: [
                optional,
                .term("C")
            ]
        )
        expr.add(alt)
        
        let result = SugarExpander().expand(axiom: expr)
        let rules = ruleSet(result.grammar)
        
        #expect(rules["Expr"] == ["Expr_opt_0 C"])
        #expect(rules["Expr_opt_0"] == ["A Expr_opt_0_rep_1", "ε"])
        #expect(rules["Expr_opt_0_rep_1"] == ["B", "B Expr_opt_0_rep_1"])
        
        /// Внешний опционал покрывает два символа вхождения: A и внутренний rep
        #expect(result.map["Expr_opt_0"] == SugarSite(type: .optional, arity: 2))
        /// Внутреннее повторение — один символ B
        #expect(result.map["Expr_opt_0_rep_1"] == SugarSite(type: .repeatOneOrMore, arity: 1))
    }
    
    /// Рекурсивная грамматика `S → S A | A` не зацикливает обход и не
    /// порождает служебных правил (сахара нет)
    @Test func testRecursiveGrammarTerminates() {
        let s = Nonterm(name: "S")
        s.add([
            Alternative(
                elements: [
                    .nonterm(s),
                    .term("A")
                ]
            ),
            Alternative(
                elements: [
                    .term("A")
                ]
            )
        ])
        
        let result = SugarExpander().expand(axiom: s)
        
        #expect(result.grammar.nonterms.count == 1)
        #expect(result.grammar.nonterms.map(\.name) == ["S"])
        #expect(result.map.isEmpty)
        
        let rules = ruleSet(result.grammar)
        #expect(rules["S"] == ["S A", "A"])
    }
    
    /// Грамматика возвращается плоским списком в детерминированном порядке
    @Test func testFlatteningOrderAndIndex() {
        let s = Nonterm(name: "S")
        let alt = Alternative(
            elements: [
                .repeat(
                    productions: [
                        .term("B")
                    ],
                    optional: false
                )
            ]
        )
        s.add(alt)
        
        let result = SugarExpander().expand(axiom: s)
        
        #expect(result.grammar.nonterms.map(\.name) == ["S", "S_rep_0"])
        #expect(result.grammar.axiom.name == "S")
        #expect(result.grammar["S_rep_0"]?.name == "S_rep_0")
        #expect(result.grammar["missing"] == nil)
    }
    
    // MARK: - Private Methods
    
    /// Собирает грамматику в словарь: имя → список правых частей
    private func ruleSet(_ grammar: ExpandedGrammar) -> [String: [String]] {
        var result: [String: [String]] = [:]
        
        for nonterm in grammar.nonterms {
            result[nonterm.name] = nonterm.disclosures.map { alternative in
                alternative.elements.isEmpty
                    ? "ε"
                    : alternative.elements.map(symbol).joined(separator: " ")
            }
        }
        
        return result
    }
    
    /// Имя элемента правой части для строкового представления правила
    private func symbol(_ production: Production) -> String {
        switch production {
        case .term(let name): return name
        case .nonterm(let nonterm): return nonterm.name
        case .repeat: return "%rep"
        case .optional: return "[...]"
        }
    }
}
