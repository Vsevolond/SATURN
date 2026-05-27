//
//  EpsilonEliminator.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 25.05.2026.
//

import Foundation

/// Устраняет ε-правила грамматики, переводя ее в форму БНФ
///
/// Преобразование состоит из трех шагов:
/// - Найти множество обнуляемых нетерминалов `Nullable` по неподвижной точке
/// - Для каждой продукции построить все альтернативы, получаемые удалением
///    произвольного подмножества обнуляемых символов из правой части
/// - Удалить продукции с пустой правой частью. Если обнуляема аксиома,
///    ввести свежую аксиому `S* → S | ε`, сохранив пустую цепочку флагом
public struct EpsilonEliminator {
    
    // MARK: - Initializers
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Устраняет ε-правила грамматики
    public func eliminate(_ grammar: ExpandedGrammar, map: ExpansionMap = [:]) throws -> EpsilonFreeGrammar {
        let nullable = try nullableSet(grammar)
        
        /// Свежий нетерминал-двойник на каждый исходный
        var eliminated: [String: Nonterm] = [:]
        
        for nonterm in grammar.nonterms {
            eliminated[nonterm.name] = Nonterm(name: nonterm.name)
        }
        
        /// Наполняем двойники альтернативами без обнуляемых символов
        for nonterm in grammar.nonterms {
            guard let target = eliminated[nonterm.name] else { continue }
            
            for alternative in nonterm.disclosures {
                let variants = try expandNullable(
                    alternative,
                    nullable: nullable,
                    eliminated: eliminated,
                    map: map
                )
                
                for variant in variants {
                    /// Пустая правая часть (все удалено) в грамматику не идет
                    guard !variant.elements.isEmpty else { continue }
                    
                    target.add(variant)
                }
            }
        }
        
        /// Двойники в исходном порядке нетерминалов
        let nonterms = grammar.nonterms.compactMap { eliminated[$0.name] }
        
        guard let axiom = eliminated[grammar.axiom.name] else {
            throw EpsilonEliminateError.axiomNotFound
        }
        
        let acceptsEmpty = nullable.contains(grammar.axiom.name)
        
        /// Аксиома необнуляема — грамматика готова как есть
        guard acceptsEmpty else {
            let grammar = ExpandedGrammar(axiom: axiom, nonterms: nonterms)
            return EpsilonFreeGrammar(value: grammar, acceptsEmpty: false)
        }
        
        /// Обнуляемую аксиому оборачиваем в свежую `S* → S`
        /// Пустую цепочку несет флаг `acceptsEmpty`
        let name = startName(taken: Set(eliminated.keys))
        let start = Nonterm(name: name)
        start.add(Alternative(elements: [.nonterm(axiom)]))
        
        /// Новая аксиома идет первой, сохраняя детерминированный порядок
        let extended = [start] + nonterms
        let grammar = ExpandedGrammar(axiom: start, nonterms: extended)
        
        return EpsilonFreeGrammar(value: grammar, acceptsEmpty: true)
    }
    
    // MARK: - Private Methods
    
    /// Множество обнуляемых нетерминалов по неподвижной точке
    private func nullableSet(_ grammar: ExpandedGrammar) throws -> Set<String> {
        var nullable: Set<String> = []
        
        /// Базис: нетерминалы с явным правилом `A → ε`
        for nonterm in grammar.nonterms
        where nonterm.disclosures.contains(where: { $0.elements.isEmpty })
        {
            nullable.insert(nonterm.name)
        }
        
        /// Расширяем множество, пока на очередном проходе что-то добавляется
        var changed = true
        
        while changed {
            changed = false
            
            for nonterm in grammar.nonterms where !nullable.contains(nonterm.name) {
                /// Обнуляем, если есть альтернатива из одних обнуляемых символов
                let isNullable = try nonterm.disclosures.contains { alternative in
                    try !alternative.elements.isEmpty
                    && alternative.elements.allSatisfy { try self.isNullable($0, nullable) }
                }
                
                if isNullable {
                    nullable.insert(nonterm.name)
                    changed = true
                }
            }
        }
        
        return nullable
    }
    
    /// Обнуляем ли символ: терминал — никогда, нетерминал — если он в `nullable`
    private func isNullable(
        _ production: Production,
        _ nullable: Set<String>
    ) throws(EpsilonEliminateError) -> Bool {
        switch production {
        case .term:
            return false
            
        case .nonterm(let nonterm):
            return nullable.contains(nonterm.name)
            
        case .repeat, .optional:
            throw .sugarNotExpanded
        }
    }
    
    /// Все альтернативы, получаемые удалением подмножеств обнуляемых символов
    private func expandNullable(
        _ alternative: Alternative,
        nullable: Set<String>,
        eliminated: [String: Nonterm],
        map: ExpansionMap
    ) throws -> [Alternative] {
        let elements = alternative.elements
        
        /// Позиции обнуляемых символов — только их и удаляем в разных сочетаниях
        let nullableIndices = try elements.indices.filter { try isNullable(elements[$0], nullable) }
        let count = nullableIndices.count
        
        var results: [Alternative] = []
        
        /// Уже встреченные формы вариантов — для отсева совпавших целиком
        var seen: Set<[String]> = []
        
        /// Каждая битовая маска задает свое подмножество удаляемых позиций
        for mask in 0..<(1 << count) {
            var dropped: Set<Int> = []
            
            for bit in 0..<count where mask & (1 << bit) != 0 {
                dropped.insert(nullableIndices[bit])
            }
            
            /// Оставшиеся символы, перевязанные на двойники ε-свободной грамматики
            let remaining = try elements.enumerated()
                .filter { !dropped.contains($0.offset) }
                .map { try rebind($0.element, eliminated: eliminated) }
            
            /// Форма варианта — вся последовательность ключей символов целиком
            let shape = try remaining.map { try $0.symbolKey }
            
            guard !seen.contains(shape) else { continue }
            seen.insert(shape)
            
            /// Метки выпавших обнуляемых символов: исходная позиция, имя и признак сахара
            let droppedSymbols = try dropped.sorted()
                .map { index in
                    let name = try elements[index].symbolKey
                    let isSugar = (map[name] != nil)
                    
                    return Alternative.DroppedSymbol(
                        position: index,
                        name: name,
                        isSugar: isSugar
                    )
                }
            
            let alternative = Alternative(
                elements: remaining,
                actions: alternative.actions,
                dropped: droppedSymbols
            )
            
            results.append(alternative)
        }
        
        return results
    }
    
    /// Перевязывает нетерминал на его двойник; терминал оставляет как есть
    private func rebind(
        _ production: Production,
        eliminated: [String: Nonterm]
    ) throws(EpsilonEliminateError) -> Production {
        switch production {
        case .term:
            return production
            
        case .nonterm(let nonterm):
            return .nonterm(eliminated[nonterm.name] ?? nonterm)
            
        case .repeat, .optional:
            throw .sugarNotExpanded
        }
    }
    
    /// Свободное имя для новой аксиомы, не совпадающее с существующими
    private func startName(taken nonterms: Set<String>) -> String {
        var name = "_Start"
        var index = 0
        
        while nonterms.contains(name) {
            name = "_Start_\(index)"
            index += 1
        }
        
        return name
    }
}

// MARK: - Private Extensions

private extension Production {
    
    // MARK: - Internal Properties
    
    /// Имя символа для сравнения форм
    var symbolKey: String {
        get throws(EpsilonEliminateError) {
            switch self {
            case .term(let name):
                return name
                
            case .nonterm(let nonterm):
                return nonterm.name
                
            case .repeat, .optional:
                throw .sugarNotExpanded
            }
        }
    }
}
