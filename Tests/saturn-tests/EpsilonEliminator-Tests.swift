//
//  EpsilonEliminator-Tests.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 25.05.2026.
//

import Testing

@testable import saturn_core

struct EpsilonEliminatorTests {
    
    /// `R → ε | C D R` теряет ε-альтернативу,
    /// а родитель `S → A R` получает вариант без обнулённого `R`
    @Test func testEliminatesEpsilonAndExpandsParent() throws {
        let r = Nonterm(name: "R")
        let s = Nonterm(name: "S")
        
        r.add([
            Alternative(),
            Alternative(
                elements: [
                    .term("C"),
                    .term("D"),
                    .nonterm(r)
                ]
            )
        ])
        
        s.add(
            Alternative(
                elements: [
                    .term("A"),
                    .nonterm(r)
                ]
            )
        )
        
        let expanded = ExpandedGrammar(axiom: s, nonterms: [s, r])
        let grammar = try EpsilonEliminator().eliminate(expanded)
        let rules = ruleSet(grammar.value)
        
        #expect(rules["S"] == ["A R", "A"])
        #expect(rules["R"] == ["C D R", "C D"])
        /// Аксиома `S` не обнуляема — пустая цепочка не принимается
        #expect(grammar.acceptsEmpty == false)
    }
    
    /// Обнуляемость транзитивна: `S → R`, `R → ε` делает обнуляемым и `S`
    @Test func testNullableIsTransitive() throws {
        let r = Nonterm(name: "R")
        let s = Nonterm(name: "S")
        
        r.add([
            Alternative(),
            Alternative(
                elements: [
                    .term("a"),
                    .nonterm(r)
                ]
            )
        ])
        
        s.add(
            Alternative(
                elements: [
                    .nonterm(r)
                ]
            )
        )
        
        let expanded = ExpandedGrammar(axiom: s, nonterms: [s, r])
        let grammar = try EpsilonEliminator().eliminate(expanded)
        
        /// Аксиома обнуляема через цепочку — пустая цепочка принимается
        #expect(grammar.acceptsEmpty == true)
    }
    
    /// Два обнуляемых символа подряд дают все непустые комбинации:
    /// `X → P Q` при обнуляемых `P`, `Q` → `P Q | Q | P`
    @Test func testTwoNullableSymbols() throws {
        let p = Nonterm(name: "P")
        let q = Nonterm(name: "Q")
        let x = Nonterm(name: "X")
        
        p.add([
            Alternative(),
            Alternative(
                elements: [
                    .term("p")
                ]
            )
        ])
        
        q.add([
            Alternative(),
            Alternative(
                elements: [
                    .term("q")
                ]
            )
        ])
        
        x.add(
            Alternative(
                elements: [
                    .nonterm(p),
                    .nonterm(q)
                ]
            )
        )
        
        let expanded = ExpandedGrammar(axiom: x, nonterms: [x, p, q])
        let grammar = try EpsilonEliminator().eliminate(expanded)
        let rules = ruleSet(grammar.value)
        
        #expect(rules["X"] == ["P Q", "Q", "P"])
        #expect(rules["P"] == ["p"])
        #expect(rules["Q"] == ["q"])
    }
    
    /// Совпавшие варианты отсеиваются: `Y → A A` при обнуляемом `A` даёт
    /// `A A | A | (пусто)` — две одиночные `A` сливаются в одну, пустая убрана
    @Test func testDuplicateVariantsMerged() throws {
        let a = Nonterm(name: "A")
        let y = Nonterm(name: "Y")
        
        a.add([
            Alternative(),
            Alternative(
                elements: [
                    .term("a")
                ]
            )
        ])
        
        y.add(
            Alternative(
                elements: [
                    .nonterm(a),
                    .nonterm(a)
                ]
            )
        )
        
        let expanded = ExpandedGrammar(axiom: y, nonterms: [y, a])
        let grammar = try EpsilonEliminator().eliminate(expanded)
        let rules = ruleSet(grammar.value)
        
        /// Удаление левого и правого `A` даёт одинаковый `A` — остаётся один
        #expect(rules["Y"] == ["A A", "A"])
    }
    
    /// Обнуляемая аксиома оборачивается в свежую `_Start → S`, которая
    /// становится новой аксиомой и идёт первой в списке
    @Test func testNullableAxiomWrapped() throws {
        let s = Nonterm(name: "S")
        
        s.add([
            Alternative(),
            Alternative(
                elements: [
                    .term("a")
                ]
            )
        ])
        
        let expanded = ExpandedGrammar(axiom: s, nonterms: [s])
        let grammar = try EpsilonEliminator().eliminate(expanded)
        
        #expect(grammar.value.axiom.name == "_Start")
        #expect(grammar.value.nonterms.first?.name == "_Start")
        #expect(grammar.acceptsEmpty == true)
        
        let rules = ruleSet(grammar.value)
        #expect(rules["_Start"] == ["S"])
        /// Пустая альтернатива исходной аксиомы убрана
        #expect(rules["S"] == ["a"])
    }
    
    /// Действия исходной альтернативы переносятся в каждый порождённый вариант без изменений
    @Test func testActionsCarriedToAllVariants() throws {
        let action = Statement.call(method: "log", arguments: [.int(1)])
        let r = Nonterm(name: "R")
        let s = Nonterm(name: "S")
        
        r.add([
            Alternative(),
            Alternative(
                elements: [
                    .term("x")
                ]
            )
        ])
        
        s.add(
            Alternative(
                elements: [
                    .nonterm(r)
                ],
                actions: [action]
            )
        )
        
        let expanded = ExpandedGrammar(axiom: s, nonterms: [s, r])
        let grammar = try EpsilonEliminator().eliminate(expanded)
        
        /// `S → R` обнуляемо по `R`, но сам `S` после удаления `R` даёт пустую правую часть, которая убирается.
        /// Остаётся единственная `S → R` с сохранёнными действиями
        let s2 = grammar.value["S"]
        #expect(s2?.disclosures.count == 1)
        #expect(s2?.disclosures.first?.actions == [action])
    }
    
    /// Грамматика без обнуляемых нетерминалов проходит без изменений
    @Test func testGrammarWithoutNullableUnchanged() throws {
        let s = Nonterm(name: "S")
        
        s.add(
            Alternative(
                elements: [
                    .term("a"),
                    .term("b")
                ]
            )
        )
        
        let expanded = ExpandedGrammar(axiom: s, nonterms: [s])
        let grammar = try EpsilonEliminator().eliminate(expanded)
        let rules = ruleSet(grammar.value)
        
        #expect(rules["S"] == ["a b"])
        #expect(grammar.acceptsEmpty == false)
        #expect(grammar.value.axiom.name == "S")
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
