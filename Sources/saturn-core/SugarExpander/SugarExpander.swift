//
//  SugarExpander.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 24.05.2026.
//

import Foundation

/// Карта развертки: имя служебного нетерминала → его описание
public typealias ExpansionMap = [String: SugarSite]

/// Разворачивает синтаксический сахар грамматики в рекурсивные правила
///
/// - `%rep(X)` : `A → X | X A`
/// - `%rep[X]` : `A → ε | B`, `B → X | X B`
/// - `[X]` : `A → X | ε`
///
/// На выходе грамматика может содержать ε-правила
public struct SugarExpander {
    
    // MARK: - Initializers
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Разворачивает сахар грамматики, достижимой от аксиомы
    /// Результат развертки: грамматика для парсера и карта для обратной свертки
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
    
    /// Глобальный счетчик служебных нетерминалов
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
    
    /// Изменяемое состояние одной развертки
    final class Context {
        
        // MARK: - Internal Properties
        
        /// Счетчик имен служебных нетерминалов
        let counter: Counter
        
        /// Пользовательские нетерминалы: имя → новый перевязанный объект
        var visited: [String: Nonterm] = [:]
        
        /// Те же нетерминалы в порядке первого достижения от аксиомы
        var visitedOrder: [Nonterm] = []
        
        /// Служебные нетерминалы в порядке порождения
        var produced: [Nonterm] = []
        
        /// Карта развертки: имя служебного нетерминала → описание
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
        /// - `%rep(X)` : один-и-более, `A → X | X A`
        /// - `%rep[X]` : ноль-и-более как обертка над один-и-более:
        ///       A → ε | B   (A — ноль-или-один блок повторения)
        ///       B → X | X B (B — один-и-более, как %rep(X))
        ///   Нерекурсивная база B = X делает раскрутку однозначной и не путает
        ///   пустой виток непустого повторения с базой, даже если X обнуляем
        private func makeRepeat(
            _ productions: [Production],
            optional: Bool,
            parent: String
        ) -> Production {
            /// Вложенный сахар внутри повторения разворачивается рекурсивно
            let nested = productions.map { expand($0, parent: parent) }
            
            /// Один-и-более: рекурсивная гребенка B → X | X B
            let oneOrMore = makeOneOrMore(nested, parent: parent)
            
            /// %rep(X) — это и есть один-и-более
            guard optional else { return oneOrMore }
            
            /// %rep[X] — обертка ноль-или-один над гребенкой: A → ε | B
            let id = counter.next()
            let name = "\(parent)_rep_zero_\(id)"
            
            let wrapper = Nonterm(name: name)
            produced.append(wrapper)
            
            wrapper.add([
                Alternative(),                       // ноль витков
                Alternative(elements: [oneOrMore])   // один-и-более через B
            ])
            
            /// Обертка несет тип ноль-и-более и арность 1: ее единственный
            /// «символ» — это вложенная гребенка один-и-более
            map[name] = SugarSite(type: .repeatZeroOrMore, arity: 1, isZeroWrapper: true)
            
            return .nonterm(wrapper)
        }
        
        /// Порождает гребенку повторения один-и-более: `B → X | X B`
        /// nested — уже развернутая группа X
        private func makeOneOrMore(
            _ nested: [Production],
            parent: String
        ) -> Production {
            let id = counter.next()
            let name = "\(parent)_rep_\(id)"
            
            let support = Nonterm(name: name)
            produced.append(support)
            
            let recursive = nested + [.nonterm(support)]
            
            support.add([
                Alternative(elements: nested), // база: одно вхождение X
                Alternative(elements: recursive) // X B
            ])
            
            map[name] = SugarSite(type: .repeatOneOrMore, arity: nested.count)
            
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
