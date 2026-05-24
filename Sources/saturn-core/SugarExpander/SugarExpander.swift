//
//  SugarExpander.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 24.05.2026.
//

import Foundation

/// Карта развёртки: имя служебного нетерминала → его описание
public typealias ExpansionMap = [String: SugarSite]

/// Разворачивает синтаксический сахар грамматики в рекурсивные правила
///
/// - `%rep(X)` : `A → X | X A`
/// - `%rep[X]` : `A → ε | X A`
/// - `[X]` : `A → X | ε`
///
/// На выходе грамматика может содержать ε-правила
public struct SugarExpander {
    
    // MARK: - Public Methods
    
    /// Разворачивает сахар грамматики, достижимой от аксиомы
    /// Результат развёртки: грамматика для парсера и карта для обратной свёртки
    public func expand(axiom: Nonterm) -> (grammar: ExpandedGrammar, map: ExpansionMap) {
        let counter = Counter()
        let context = Context(counter: counter)
        
        let newAxiom = context.visit(axiom)
        
        /// Пользовательские нетерминалы в порядке первого достижения,
        /// затем служебные в порядке порождения
        let nonterms = context.visitedOrder + context.produced
        
        /// Грамматика без сахара
        let grammar = ExpandedGrammar(axiom: newAxiom, nonterms: nonterms)
        
        return (grammar, context.map)
    }
}

// MARK: - Private Extensions

private extension SugarExpander {
    
    // MARK: - Type Entities
    
    /// Глобальный счётчик служебных нетерминалов
    final class Counter {
        
        // MARK: - Private Properties
        
        private var value = 0
        
        // MARK: - Internal Methods
        
        func next() -> Int {
            defer { value += 1 }
            return value
        }
    }
}

private extension SugarExpander {
    
    // MARK: - Type Entities
    
    /// Изменяемое состояние одной развёртки
    final class Context {
        
        // MARK: - Internal Properties
        
        /// Счётчик имён служебных нетерминалов
        let counter: Counter
        
        /// Пользовательские нетерминалы: имя → новый перевязанный объект
        var visited: [String: Nonterm] = [:]
        
        /// Те же нетерминалы в порядке первого достижения от аксиомы
        var visitedOrder: [Nonterm] = []
        
        /// Служебные нетерминалы в порядке порождения
        var produced: [Nonterm] = []
        
        /// Карта развёртки: имя служебного нетерминала → описание
        var map: ExpansionMap = [:]
        
        // MARK: - Initializers
        
        init(counter: Counter) { self.counter = counter }
        
        // MARK: - Internal Methods
        
        /// Перевязывает пользовательский нетерминал, разворачивая сахар
        /// во всех его альтернативах
        func visit(_ nonterm: Nonterm) -> Nonterm {
            /// Если уже посещен, то возвращаем его
            if let exist = visited[nonterm.name] { return exist }
            
            /// Создаем новый нетерминал
            let fresh = Nonterm(name: nonterm.name)
            
            /// Добавляем в посещенные
            visited[nonterm.name] = fresh
            visitedOrder.append(fresh)
            
            /// Проходим по всем альтернативам
            for alternative in nonterm.disclosures {
                /// Разворачиваем сахар и создаем новую альтернативу с теми же действиями
                let elements = alternative.elements.map { expand($0, parent: nonterm.name) }
                let disclosure = Alternative(elements: elements, actions: alternative.actions)
                
                fresh.add(disclosure)
            }
            
            return fresh
        }
        
        /// Разворачивает один элемент правой части
        func expand(_ production: Production, parent: String) -> Production {
            switch production {
            case .term:
                return production
                
            case .nonterm(let nonterm):
                let fresh = visit(nonterm)
                return .nonterm(fresh)
                
            case .repeat(let productions, let optional):
                return makeRepeat(productions, optional: optional, parent: parent)
                
            case .optional(let productions):
                return makeOptional(productions, parent: parent)
            }
        }
        
        // MARK: - Private Methods
        
        /// Порождает служебный нетерминал для `%rep`
        /// - `%rep(X)` : `A → X | X A`
        /// - `%rep[X]` : `A → ε | X A`
        private func makeRepeat(
            _ productions: [Production],
            optional: Bool,
            parent: String
        ) -> Production {
            /// Создаем служебный нетерминал
            let id = counter.next()
            let name = "\(parent)_rep_\(id)"
            
            let support = Nonterm(name: name)
            produced.append(support)
            
            /// Вложенный сахар внутри повторения разворачивается рекурсивно
            let nested = productions.map { expand($0, parent: name) }
            let recursive = nested + [.nonterm(support)]
            
            /// `A → ε | X A`
            if optional {
                support.add([
                    Alternative(),
                    Alternative(elements: recursive)
                ])
                
            /// `A → X | X A`
            } else {
                support.add([
                    Alternative(elements: nested),
                    Alternative(elements: recursive)
                ])
            }
            
            /// Устанавливаем описание для служебного нетерминала
            map[name] = SugarSite(
                type: optional ? .repeatZeroOrMore : .repeatOneOrMore,
                arity: nested.count
            )
            
            return .nonterm(support)
        }
        
        /// Порождает служебный нетерминал для опционала `[...]`: `A → X | ε`
        private func makeOptional(
            _ productions: [Production],
            parent: String
        ) -> Production {
            /// Создаем служебный нетерминал
            let id = counter.next()
            let name = "\(parent)_opt_\(id)"
            
            let support = Nonterm(name: name)
            produced.append(support)
            
            /// Вложенный сахар внутри опционала разворачивается рекурсивно
            let nested = productions.map { expand($0, parent: name) }
            
            support.add([
                Alternative(elements: nested),
                Alternative()
            ])
            
            /// Устанавливаем описание для служебного нетерминала
            map[name] = SugarSite(type: .optional, arity: nested.count)
            
            return .nonterm(support)
        }
    }
}
