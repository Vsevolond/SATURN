//
//  GLRParser.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.05.2026.
//

import Foundation

/// GLR-анализатор по схеме Алгоритма 1e Томиты
/// Ведет все ветви разбора одновременно поверх GSS и собирает результат в SPPF
public final class GLRParser {
    
    // MARK: - Private Properties
    
    /// Управляющая таблица SLR(1) с многозначными ячейками ACTION
    private let table: ParseTable
    
    /// Строящийся лес разбора
    private let forest: SPPForest
    
    /// Граф-структурированный стек
    private let stack: GSStack
    
    /// Поток лексем без маркера конца входа
    private let lexemes: [Lexeme]
    
    /// Имя пользовательской аксиомы — нетерминал в правой части стартовой продукции
    private let axiom: String
    
    // MARK: - Initializers
    
    /// Готовит анализатор к разбору потока лексем по таблице
    public init(table: ParseTable, lexemes: [Lexeme]) throws(GLRParseError) {
        self.table = table
        self.lexemes = lexemes
        
        self.forest = SPPForest()
        self.stack = GSStack()
        
        /// Стартовая продукция `_Axiom → A` добавлена при расширении грамматики
        /// Ее единственный символ справа — пользовательская аксиома A
        if let first = table.productions[0].rhs.first,
            case .nonterminal(let name) = first { self.axiom = name }
        else { throw .axiomNotFound }
    }
    
    // MARK: - Public Methods
    
    /// Разбирает вход и возвращает лес
    public func parse() throws(GLRParseError) -> SPPForest {
        /// Пустой вход — разбора нет, решает только флаг допустимости
        if lexemes.isEmpty {
            /// Язык не принимает пустую цепочку — ошибка
            guard table.acceptsEmpty else { throw .unexpectedEmptyInput }
            
            /// Пустая цепочка допустима — возвращаем пустой лес без корня
            return forest
        }
        
        /// Дно стека: стартовое состояние 0 на позиции перед первой лексемой
        stack.obtainVertex(state: 0, position: 0)
        
        let count = lexemes.count
        
        /// Идем по границам входа от 0 до count
        for position in 0...count {
            /// Символ предпросмотра определяет, какие действия таблицы применимы на уровне
            let lookahead = symbol(at: position)
            
            /// Сначала исчерпываем все свертки уровня — они не двигают позицию
            reduceToFixpoint(at: position, lookahead: lookahead)
            
            /// Затем переносим текущую лексему на следующий уровень, на конце входа ее нет
            if position < count {
                let lexeme = lexemes[position]
                try shift(at: position, lexeme: lexeme)
            }
        }
        
        /// Вход кончился — проверяем прием и фиксируем корень леса
        try acceptOrFail()
        
        return forest
    }
    
    // MARK: - Private Methods
    
    /// Символ предпросмотра на позиции: терминал лексемы или маркер конца входа
    private func symbol(at position: Int) -> GrammarSymbol {
        /// За последней лексемой стоит конец входа
        guard position < lexemes.count else { return .end }
        
        let lexeme = lexemes[position]
        /// Имя лексемы — имя терминала грамматики
        return .terminal(lexeme.name)
    }
    
    /// Выполняет все применимые свертки уровня до насыщения
    private func reduceToFixpoint(at position: Int, lookahead: GrammarSymbol) {
        /// Уже примененные пути, чтобы не свернуть один путь дважды за этот уровень
        var processed: Set<ReductionKey> = []
        
        /// Свертка порождает новую вершину или ребро на том же уровне, а это открывает новые пути спуска
        /// Поэтому пересобираем пути в цикле, пока они появляются
        while true {
            /// Собираем все еще не обработанные пути сверток с текущего уровня
            let pending = collectReductions(at: position, lookahead: lookahead, skipping: processed)
            
            /// Новых путей нет — уровень насыщен
            guard !pending.isEmpty else { break }
            
            for reduction in pending {
                /// Помечаем путь обработанным до применения — оно может добавить ребра
                processed.insert(reduction.key)
                
                /// Строим узел SPPF и переход GOTO для этой свертки
                apply(reduction, at: position)
            }
        }
    }
    
    /// Собирает необработанные пути сверток со всех вершин уровня
    private func collectReductions(
        at position: Int,
        lookahead: GrammarSymbol,
        skipping processed: Set<ReductionKey>
    ) -> [PendingReduction] {
        var pending: [PendingReduction] = []
        
        /// Перебираем все живые вершины уровня
        for vertex in stack.vertices(at: position) {
            /// Для вершины — все ее действия на символе предпросмотра
            for action in table.actions(state: vertex.state, symbol: lookahead) {
                /// Интересуют только свертки, перенос и прием обрабатываются отдельно
                guard case .reduce(let production) = action else { continue }
                
                /// Длина правой части задает, на сколько ребер спускаться по стеку назад
                let length = table.productions[production].rhs.count
                
                /// На развилках GSS таких путей несколько — каждый даст свою семью узла
                for path in walkBack(from: vertex, steps: length) {
                    /// Путь однозначно опознается первым ребром и продукцией
                    let key = ReductionKey(firstEdge: path.firstEdge, production: production)
                    
                    /// Этот путь уже свернут на текущем уровне — пропускаем
                    guard !processed.contains(key) else { continue }
                    
                    pending.append(
                        PendingReduction(
                            production: production,
                            children: path.children,
                            tail: path.tail,
                            key: key
                        )
                    )
                }
            }
        }
        
        return pending
    }
    
    /// Применяет свертку пути: строит узел SPPF и переход GOTO на том же уровне
    private func apply(_ reduction: PendingReduction, at position: Int) {
        let production = table.productions[reduction.production]
        
        /// От состояния хвоста делаем GOTO по левой части продукции
        guard let next = table.nextState(
            state: reduction.tail.state,
            nonterminal: production.lhs
        ) else {
            /// Недостижимо при согласованных таблице и грамматике
            return
        }
        
        /// Узел нетерминала над диапазоном [хвост, позиция)
        /// По ключу узел разделяется, поэтому разные пути одной свертки попадут в один и тот же узел
        let node = forest.nonterminalNode(
            symbol: .nonterminal(production.lhs),
            start: reduction.tail.position,
            end: position
        )
        
        /// Дети этого пути — еще одна семья узла, повтор семьи отсекается внутри add
        let family = SPPForest.Family(production: production.id, children: reduction.children)
        node.add(family)
        
        /// Вершина GOTO лежит на том же уровне — свертка позицию не двигает
        let target = stack.obtainVertex(state: next, position: position).vertex
        
        /// Ребро от новой вершины к хвостовой несет свернутый узел
        stack.connect(target, to: reduction.tail, carrying: node)
    }
    
    /// Все пути длины steps назад по GSS от вершины-истока свертки
    private func walkBack(
        from vertex: GSStack.Vertex,
        steps: Int
    ) -> [(children: [SPPForest.Node], tail: GSStack.Vertex, firstEdge: Int)] {
        /// Пустая правая часть не встречается
        guard steps > 0 else { return [([], vertex, -1)] }
        
        var result: [(children: [SPPForest.Node], tail: GSStack.Vertex, firstEdge: Int)] = []
        
        /// Каждое ребро истока — начало отдельного пути
        for edge in vertex.edges {
            /// Остаток пути проходим обычным спуском, без фиксации первого ребра
            for subpath in tailPaths(from: edge.target, steps: steps - 1) {
                /// Это ребро ближе всех к истоку, его узел стоит правее в правой части, поэтому дописываем его в конец
                let path = (subpath.children + [edge.node], subpath.tail, edge.id)
                result.append(path)
            }
        }
        
        return result
    }
    
    /// Хвостовая часть пути — без фиксации первого ребра
    private func tailPaths(
        from vertex: GSStack.Vertex,
        steps: Int
    ) -> [(children: [SPPForest.Node], tail: GSStack.Vertex)] {
        /// Спустились на нужную глубину — путь окончен
        guard steps > 0 else { return [([], vertex)] }
        
        var result: [(children: [SPPForest.Node], tail: GSStack.Vertex)] = []
        
        /// На каждой развилке путь множится по числу ребер
        for edge in vertex.edges {
            for subpath in tailPaths(from: edge.target, steps: steps - 1) {
                /// Узел текущего ребра правее уже собранных, поэтому дописывается в конец
                let path = (subpath.children + [edge.node], subpath.tail)
                result.append(path)
            }
        }
        
        return result
    }
    
    /// Переносит лексему со всех вершин уровня на следующий уровень
    private func shift(at position: Int, lexeme: Lexeme) throws (GLRParseError) {
        let lookahead = GrammarSymbol.terminal(lexeme.name)
        
        /// Терминальный узел один на лексему — сходящиеся переносы его разделят
        let terminalNode = forest.terminalNode(
            symbol: lookahead,
            lexeme: lexeme,
            start: position,
            end: position + 1
        )
        
        /// Перенесла ли лексему хоть одна вершина, иначе все ветви заглохли
        var shifted = false
        
        for vertex in stack.vertices(at: position) {
            for action in table.actions(state: vertex.state, symbol: lookahead) {
                /// Интересует только перенос, свертки уже отработаны на этом уровне
                guard case .shift(let next) = action else { continue }
                
                /// Цель переноса живет на следующем уровне, общее состояние сливает ветви
                let target = stack.obtainVertex(state: next, position: position + 1).vertex
                
                /// Ребро к исходной вершине несет общий терминальный узел
                stack.connect(target, to: vertex, carrying: terminalNode)
                shifted = true
            }
        }
        
        /// Ни одна ветвь не приняла лексему — ошибка
        guard shifted else {
            let expected = expectedTerminals(at: position)
            throw .unexpectedInput(lexeme: lexeme, expected: expected)
        }
    }
    
    /// Проверяет прием на последнем уровне и привязывает корень леса
    private func acceptOrFail() throws(GLRParseError) {
        let last = lexemes.count
        
        for vertex in stack.vertices(at: last) {
            /// Прием — действие accept вершины на маркере конца входа
            let accepts = table.actions(state: vertex.state, symbol: .end).contains(.accept)
            
            guard accepts else { continue }
            
            /// Корень — узел пользовательской аксиомы над всем входом
            forest.root = forest.node(symbol: .nonterminal(axiom), start: 0, end: last)
            
            return
        }
        
        let expected = expectedTerminals(at: last)
        /// Ни одна вершина не приняла вход — разбор не дошел до аксиомы
        throw .unexpectedInput(lexeme: nil, expected: expected)
    }
    
    /// Терминалы, которые ждала хотя бы одна вершина уровня
    private func expectedTerminals(at position: Int) -> [String] {
        var expected: Set<String> = []
        
        for vertex in stack.vertices(at: position) {
            /// Берем все символы, на которые у состояния вершины есть действие
            guard let cells = table.action[vertex.state] else { continue }
            
            for (symbol, _) in cells {
                /// В ожидаемые идут только терминалы
                if case .terminal(let name) = symbol { expected.insert(name) }
            }
        }
        
        return expected.sorted()
    }
}

// MARK: - Extensions

extension GLRParser {
    
    // MARK: - Type Entities
    
    /// Отложенная свертка по конкретному пути спуска
    private struct PendingReduction {
        
        // MARK: - Intrenal Properties
        
        let production: Int
        let children: [SPPForest.Node]
        let tail: GSStack.Vertex
        let key: ReductionKey
    }
}

extension GLRParser {
    
    // MARK: - Type Entities
    
    /// Ключ свертки: путь от истока однозначно задается первым ребром и продукцией
    /// Дедупликация идет по пути, а не по вершине
    private struct ReductionKey: Hashable {
        
        // MARK: - Internal Properties
        
        let firstEdge: Int
        let production: Int
    }
}
