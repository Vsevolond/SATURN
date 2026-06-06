//
//  ParseTable-Tests.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 25.05.2026.
//

import Testing

@testable import saturn_core

struct ParseTableTests {
    
    /// Грамматика расширяется свежей стартовой продукцией с номером 0
    /// ее правая часть — пользовательская аксиома E
    @Test func testAxiomIsAugmented() throws {
        let grammar = ambiguousExpressionGrammar()
        let numbered = try NumberedGrammar(grammar)
        
        #expect(numbered.productions[0].id == 0)
        #expect(numbered.productions[0].rhs == [.nonterminal("E")])
        /// Нумерация плотная и по порядку
        #expect(numbered.productions.map(\.id) == Array(0 ..< numbered.productions.count))
        /// Аксиома грамматики — свежий стартовый нетерминал, не пользовательский
        #expect(numbered.axiom != "E")
    }
    
    /// FOLLOW(E) для `E → E + E | n` с аксиомой E содержит `+` и конец входа
    @Test func testFollowOfAxiom() throws {
        let grammar = ambiguousExpressionGrammar()
        let numbered = try NumberedGrammar(grammar)
        let follow = numbered.follow
        
        #expect(follow["E"] == [.terminal("+"), .end])
    }
    
    /// Неоднозначность дает ячейку с конфликтом shift/reduce — оба действия присутствуют
    @Test func testShiftReduceConflictPresent() throws {
        let grammar = ambiguousExpressionGrammar()
        let table = try ParseTable(grammar, acceptsEmpty: false)
        
        /// Ищем хоть одну ячейку, где одновременно есть перенос и свертка
        let hasConflict = table.action.values.contains { row in
            row.values.contains { cell in
                let hasShift = cell.contains {
                    if case .shift = $0 { return true } else { return false }
                }
                
                let hasReduce = cell.contains {
                    if case .reduce = $0 { return true } else { return false }
                }
                
                return hasShift && hasReduce
            }
        }
        
        #expect(hasConflict, "Неоднозначная грамматика должна давать конфликт shift/reduce")
    }
    
    /// В таблице есть прием по концу входа
    @Test func testAcceptOnEnd() throws {
        let grammar = ambiguousExpressionGrammar()
        let table = try ParseTable(grammar, acceptsEmpty: false)
        
        let hasAccept = table.action.values.contains { row in
            row[.end]?.contains(.accept) ?? false
        }
        
        #expect(hasAccept)
    }
    
    /// Однозначная грамматика `S → a S | b` не дает конфликтов:
    /// каждая ячейка ACTION содержит ровно одно действие
    @Test func testDeterministicGrammarHasNoConflicts() throws {
        let s = Nonterm(name: "S")
        
        s.add([
            Alternative(
                elements: [
                    .term("a"),
                    .nonterm(s)
                ]
            ),
            Alternative(
                elements: [
                    .term("b")
                ]
            )
        ])
        let grammar = ExpandedGrammar(axiom: s, nonterms: [s])
        
        let table = try ParseTable(grammar, acceptsEmpty: false)
        
        let maxCell = table.action.values
            .flatMap { $0.values }
            .map(\.count)
            .max() ?? 0
        
        #expect(maxCell == 1, "Однозначная грамматика не должна давать многозначных ячеек")
    }
    
    /// Перенос по терминалу `n` ведет в состояние, сворачивающее `E → n`:
    /// проверяем согласованность shift и reduce через таблицу
    @Test func testShiftLeadsToReduceState() throws {
        let grammar = ambiguousExpressionGrammar()
        let table = try ParseTable(grammar, acceptsEmpty: false)
        
        /// Находим состояние-цель переноса по `n` из стартового состояния 0
        guard let shiftN = table.actions(state: 0, symbol: .terminal("n")).first,
              case .shift(let target) = shiftN
        else {
            Issue.record("Из состояния 0 нет переноса по n")
            return
        }
        
        /// Это состояние должно сворачивать продукцию `E → n`
        let reduces = table.actions(state: target, symbol: .end)
        let reducesToProduction = reduces.contains {
            if case .reduce = $0 { return true } else { return false }
        }
        
        #expect(reducesToProduction, "Состояние после переноса n должно сворачивать E → n")
    }
    
    /// GOTO по нетерминалу E из стартового состояния определен
    @Test func testGotoOnNonterminal() throws {
        let grammar = ambiguousExpressionGrammar()
        let table = try ParseTable(grammar, acceptsEmpty: false)
        
        #expect(table.nextState(state: 0, nonterminal: "E") != nil)
    }
    
    // MARK: - Private Methods
    
    /// Строит неоднозначную грамматику `E → E + E | n` с аксиомой E
    private func ambiguousExpressionGrammar() -> ExpandedGrammar {
        let e = Nonterm(name: "E")
        
        e.add([
            Alternative(
                elements: [
                    .nonterm(e),
                    .term("+"),
                    .nonterm(e)
                ]
            ),
            Alternative(
                elements: [
                    .term("n")
                ]
            )
        ])
        
        return ExpandedGrammar(axiom: e, nonterms: [e])
    }
}
