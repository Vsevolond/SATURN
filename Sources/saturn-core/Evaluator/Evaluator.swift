//
//  Evaluator.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 27.05.2026.
//

import Foundation
import JavaScriptCore

/// Вычислитель атрибутов синтаксически управляемого определения
/// Обходит дерево разбора и вычисляет атрибуты по семантическим действиям правил
/// Грамматика L-атрибутная:
/// - наследуемые атрибуты ребенка готовятся до спуска в него
/// - синтезированные читаются после.
/// Действия исполняются в порядке записи
public final class Evaluator {
    
    // MARK: - Private Properties
    
    /// Спецификация: объявления атрибутов, методов, типов
    private let specification: Specification
    
    /// Занумерованные продукции — по номеру правила доступны действия и выпавшие символы
    private let productions: [NumberedProduction]
    
    /// Среда выполнения пользовательской логики
    private let runtime: SemanticRuntime
    
    /// Синтезированные атрибуты узлов по идентичности
    private var synthesized: [ObjectIdentifier: [String: AttributeValue]] = [:]
    
    /// Наследуемые атрибуты узлов, записанные родителем до спуска
    private var inherited: [ObjectIdentifier: [String: AttributeValue]] = [:]
    
    /// Узлы, для которых спуск уже выполнен
    private var visited: Set<ObjectIdentifier> = []
    
    /// Узлы, спуск в которые сейчас идет — повторный вход означает цикл через спуск
    private var inProgress: Set<ObjectIdentifier> = []
    
    /// Атрибуты в процессе вычисления — повторный запрос означает цикл зависимости
    private var computing: Set<AttributeKey> = []
    
    // MARK: - Initializers
    
    public init(
        specification: Specification,
        productions: [NumberedProduction],
        runtime: SemanticRuntime
    ) {
        self.specification = specification
        self.productions = productions
        self.runtime = runtime
    }
    
    // MARK: - Public Methods
    
    /// Вычисляет атрибуты дерева и возвращает синтезированные атрибуты корня
    public func evaluate(_ tree: ParseTree) throws -> [String: AttributeValue] {
        try visit(tree)
        let identity = ObjectIdentifier(tree)
        
        return synthesized[identity] ?? [:]
    }
    
    // MARK: - Private Methods
    
    /// Выполняет действия правила узла, спускаясь в детей по мере чтения их атрибутов
    private func visit(_ node: ParseTree) throws {
        let identity = ObjectIdentifier(node)
        
        /// Узел уже обработан — повторный спуск не нужен
        guard !visited.contains(identity) else { return }
        
        /// Повторный вход в узел, спуск в который еще идет — цикл через зависимость
        guard !inProgress.contains(identity) else {
            throw EvaluateError.cyclicDependency(nonterm: node.symbol)
        }
        
        inProgress.insert(identity)
        
        let production = productions[node.production]
        let slots = buildSlots(node: node, production: production)
        
        /// Действия исполняются в порядке записи
        for statement in production.actions {
            try execute(statement, node: node, slots: slots)
        }
        
        /// Дети, чьи атрибуты не читались, все равно вычисляются
        try descendRemaining(slots: slots)
        
        inProgress.remove(identity)
        visited.insert(identity)
    }
    
    /// Строит плоскую нумерацию символов правой части
    private func buildSlots(node: ParseTree, production: NumberedProduction) -> [Slot] {
        /// Сначала разворачиваем фактических детей в плоские позиции
        var present: [Slot] = []
        
        for child in node.children {
            switch child {
            case .tree, .token:
                present.append(.single(child))
                
            case .repetition(let repetition):
                /// Символ на позиции column внутри витка дает значения по всем виткам
                for column in 0..<repetition.arity {
                    let values = repetition.items.map { $0[column] }
                    present.append(.repeated(values))
                }
            }
        }
        
        /// Без выпавших обычных символов плоский список совпадает с present
        let ordinaryDropped = production.dropped.filter { !$0.isSugar }
        
        guard !ordinaryDropped.isEmpty else { return present }
        
        /// Раскладываем present по исходным позициям, оставляя absent на местах выпавших
        let total = present.count + ordinaryDropped.count
        var droppedAt: Set<Int> = []
        
        for symbol in ordinaryDropped { droppedAt.insert(symbol.position) }
        
        var slots: [Slot] = []
        var next = 0
        
        for position in 0..<total {
            if droppedAt.contains(position) {
                slots.append(.absent)
                
            } else {
                slots.append(present[next])
                next += 1
            }
        }
        
        return slots
    }
    
    /// Спускается во всех детей-поддеревья, еще не посещенных при чтении атрибутов
    private func descendRemaining(slots: [Slot]) throws {
        for slot in slots {
            switch slot {
            case .single(let child):
                try descend(child)
                
            case .repeated(let children):
                for child in children { try descend(child) }
                
            case .absent:
                continue
            }
        }
    }
    
    /// Спускается в ребенка, если это непосещенное поддерево, токен значения не требует
    private func descend(_ child: ParseTree.Child) throws {
        guard case .tree(let subtree) = child else { return }
        try visit(subtree)
    }
    
    /// Исполняет один оператор семантического действия
    private func execute(
        _ statement: Statement,
        node: ParseTree,
        slots: [Slot]
    ) throws {
        switch statement {
        case .call(let method, let arguments):
            /// Самостоятельный вызов: результат отбрасывается, важны побочные эффекты
            _ = try invoke(method: method, arguments: arguments, node: node, slots: slots)
            
        case .assignment(let reference, let value):
            let identity = targetIdentity(reference, node: node, slots: slots)
            /// Помечаем цель вычисляемой
            let key = AttributeKey(
                node: identity,
                inherited: reference.target != 0,
                name: reference.attribute
            )
            
            computing.insert(key)
            let computed = try evaluate(value, node: node, slots: slots)
            computing.remove(key)
            
            try assign(computed, to: reference, node: node, slots: slots)
        }
    }
    
    /// Идентичность узла-владельца атрибута: текущий узел для `$0`, ребенок для `$N`
    private func targetIdentity(
        _ reference: Reference,
        node: ParseTree,
        slots: [Slot]
    ) -> ObjectIdentifier {
        guard reference.target != 0 else { return ObjectIdentifier(node) }
        
        /// Для наследуемого атрибута ребенка — его идентичность, иначе текущий узел
        let index = Int(reference.target) - 1
        
        if index >= 0, index < slots.count,
           case .single(let child) = slots[index],
           case .tree(let subtree) = child
        {
            return ObjectIdentifier(subtree)
        }
        
        return ObjectIdentifier(node)
    }
    
    /// Записывает значение по ссылке: в синтезированные левой части или наследуемые ребенка
    private func assign(
        _ value: AttributeValue,
        to reference: Reference,
        node: ParseTree,
        slots: [Slot]
    ) throws {
        /// Присваивание в левую часть — синтезированный атрибут текущего узла
        if reference.target == 0 {
            let identity = ObjectIdentifier(node)
            synthesized[identity, default: [:]][reference.attribute] = value
            
        /// Присваивание в правую часть — наследуемый атрибут конкретного ребенка
        } else {
            let slot = try resolveSlot(reference.target, in: slots, nonterm: node.symbol)
            
            /// Записывать наследуемый атрибут можно только обычному нетерминалу-ребенку
            guard case .single(let child) = slot,
                  case .tree(let subtree) = child
            else { return }
            
            let identity = ObjectIdentifier(subtree)
            inherited[identity, default: [:]][reference.attribute] = value
        }
    }
    
    /// Вычисляет выражение в значение атрибута
    private func evaluate(
        _ expression: Expression,
        node: ParseTree,
        slots: [Slot]
    ) throws -> AttributeValue {
        switch expression {
        case .int(let value):
            return .int(value)
            
        case .float(let value):
            return .float(value)
            
        case .string(let value):
            return .string(value)
            
        case .bool(let value):
            return .bool(value)
            
        case .attribute(let reference):
            return try read(reference, node: node, slots: slots)
            
        case .call(let method, let arguments):
            return try invoke(method: method, arguments: arguments, node: node, slots: slots)
            
        case .binary(let left, let operation, let right):
            let leftValue = try evaluate(left, node: node, slots: slots)
            let rightValue = try evaluate(right, node: node, slots: slots)
            
            return try apply(operation, leftValue, rightValue, nonterm: node.symbol)
        }
    }
    
    /// Читает значение по ссылке на атрибут с учетом оберток повторения и индексов
    private func read(
        _ reference: Reference,
        node: ParseTree,
        slots: [Slot]
    ) throws -> AttributeValue {
        /// Базовое значение символа без снятия индексов
        let base = try readBase(reference, node: node, slots: slots)
        
        /// Снимаем индексы subscripts: каждый шаг разыменовывает массив
        return try applySubscripts(reference, to: base, node: node, slots: slots)
    }
    
    /// Базовое значение символа: атрибут левой части, ребенка или массив значений по виткам
    private func readBase(
        _ reference: Reference,
        node: ParseTree,
        slots: [Slot]
    ) throws -> AttributeValue {
        /// Левая часть — свой синтезированный атрибут, либо наследуемый, записанный родителем
        if reference.target == 0 {
            let identity = ObjectIdentifier(node)
            
            /// Сначала вычисленный своими действиями, затем переданный сверху
            if let value = synthesized[identity]
                .flatMap({ $0[reference.attribute] })
            {
                return value
            }
            
            if let value = inherited[identity]
                .flatMap({ $0[reference.attribute] })
            {
                return value
            }
            
            /// Атрибут сейчас вычисляется или будет вычислен этим же правилом
            let synKey = AttributeKey(node: identity, inherited: false, name: reference.attribute)
            
            let isOwnTarget = production(of: node).actions
                .contains {
                    if case .assignment(let target, _) = $0 {
                        return target.target == 0 && target.attribute == reference.attribute
                    }
                    
                    return false
                }
            
            if computing.contains(synKey) || isOwnTarget {
                throw EvaluateError.cyclicDependency(
                    attribute: reference.attribute,
                    nonterm: node.symbol
                )
            }
            
            throw EvaluateError.attributeNotComputed(
                target: 0,
                attribute: reference.attribute,
                nonterm: node.symbol
            )
        }
        
        let slot = try resolveSlot(reference.target, in: slots, nonterm: node.symbol)
        
        switch slot {
        case .single(let child):
            return try value(
                of: child,
                attribute: reference.attribute,
                nonterm: node.symbol,
                target: reference.target
            )
            
        case .repeated(let children):
            /// Символ внутри повторения — массив атрибутов по виткам
            let values = try children.map {
                try value(
                    of: $0,
                    attribute: reference.attribute,
                    nonterm: node.symbol,
                    target: reference.target
                )
            }
            
            return .array(values)
            
        case .absent:
            /// Выпавший обычный символ не имеет значения
            return .undefined
        }
    }
    
    /// Значение атрибута одиночного символа: токен отдает текст, нетерминал — после спуска
    private func value(
        of child: ParseTree.Child,
        attribute: String,
        nonterm: String,
        target: UInt
    ) throws -> AttributeValue {
        switch child {
        case .token(let lexeme):
            /// У токена единственный атрибут — его текст
            return .string(lexeme.text)
            
        case .tree(let subtree):
            let identity = ObjectIdentifier(subtree)
            /// Атрибут ребенка сейчас вычисляется выше по стеку — цикл через спуск
            let key = AttributeKey(node: identity, inherited: false, name: attribute)
            
            if computing.contains(key) {
                throw EvaluateError.cyclicDependency(attribute: attribute, nonterm: nonterm)
            }
            
            /// Ленивый спуск: вычисляем ребенка перед чтением его синтезированного атрибута
            try visit(subtree)
            
            guard let value = synthesized[identity].flatMap({ $0[attribute] }) else {
                throw EvaluateError.attributeNotComputed(
                    target: target,
                    attribute: attribute,
                    nonterm: nonterm
                )
            }
            
            return value
            
        case .repetition:
            /// Повторение разворачивается в slots заранее, сюда не попадает
            return .undefined
        }
    }
    
    /// Снимает индексы subscripts, разыменовывая массив на каждом шаге
    private func applySubscripts(
        _ reference: Reference,
        to base: AttributeValue,
        node: ParseTree,
        slots: [Slot]
    ) throws -> AttributeValue {
        var current = base
        
        for index in reference.subscripts {
            let indexValue = try evaluate(index, node: node, slots: slots)
            
            guard case .int(let position) = indexValue else {
                /// Индекс не целочислен — несоответствие было бы отловлено валидатором
                throw EvaluateError.undefinedInExpression(nonterm: node.symbol)
            }
            
            guard case .array(let elements) = current else {
                throw EvaluateError.subscriptOutOfBounds(
                    target: reference.target,
                    attribute: reference.attribute
                )
            }
            
            guard position >= 0 && position < elements.count else {
                throw EvaluateError.subscriptOutOfBounds(
                    target: reference.target,
                    attribute: reference.attribute
                )
            }
            
            current = elements[position]
        }
        
        return current
    }
    
    /// Вызывает метод семантики, конвертируя аргументы и результат через движок
    private func invoke(
        method: String,
        arguments: [Expression],
        node: ParseTree,
        slots: [Slot]
    ) throws -> AttributeValue {
        /// Аргументы вычисляются и переводятся в значения движка
        let values = try arguments.map { try evaluate($0, node: node, slots: slots) }
        let jsArguments = values.map { $0.toJS(in: runtime.context) }
        
        let result = try runtime.call(method, arguments: jsArguments)
        
        /// Результат восстанавливаем по объявленному возвращаемому типу метода
        guard let declaration = specification.methods[method] else {
            throw EvaluateError.methodNotFound(name: method)
        }
        
        /// Метод без возвращаемого значения дает отсутствие значения
        guard let returnType = declaration.returnType else { return .undefined }
        
        return AttributeValue.fromJS(result, expected: returnType)
    }
    
    /// Применяет бинарную операцию к двум значениям атрибутов
    private func apply(
        _ operation: Operator,
        _ left: AttributeValue,
        _ right: AttributeValue,
        nonterm: String
    ) throws -> AttributeValue {
        /// Отсутствие в арифметике — ошибка выполнения
        if left.isUndefined || right.isUndefined {
            throw EvaluateError.undefinedInExpression(nonterm: nonterm)
        }
        
        /// Сложение строк
        if case .string(let leftText) = left,
           case .string(let rightText) = right,
           operation == .add
        {
            return .string(leftText + rightText)
        }
        
        /// Числовые операции: целые остаются целыми, вещественное заражает результат
        let leftNumber = number(of: left)
        let rightNumber = number(of: right)
        
        guard let leftNumber, let rightNumber else {
            throw EvaluateError.undefinedInExpression(nonterm: nonterm)
        }
        
        /// Проверяем деление на ноль
        if operation == .div, rightNumber == 0 {
            throw EvaluateError.divisionByZero(nonterm: nonterm)
        }
        
        let result = compute(operation, leftNumber, rightNumber)
        
        /// Целочисленный результат сохраняем целым, если оба операнда были целыми
        if case .int = left, case .int = right,
           operation != .div || result.truncatingRemainder(dividingBy: 1) == 0
        {
            let converted = Int(result)
            return .int(converted)
        }
        
        return .float(result)
    }
    
    /// Числовое значение операнда или `nil`, если он не число
    private func number(of value: AttributeValue) -> Double? {
        switch value {
        case .int(let number): return Double(number)
        case .float(let number): return number
        default: return nil
        }
    }
    
    /// Вычисляет арифметику над числами
    private func compute(_ operation: Operator, _ left: Double, _ right: Double) -> Double {
        switch operation {
        case .add: return left + right
        case .sub: return left - right
        case .mul: return left * right
        case .div: return left / right
        }
    }
    
    /// Возвращает слот символа по номеру или бросает ошибку выхода за границы
    private func resolveSlot(
        _ target: UInt,
        in slots: [Slot],
        nonterm: String
    ) throws -> Slot {
        let index = Int(target) - 1
        
        guard index >= 0 && index < slots.count else {
            throw EvaluateError.referenceOutOfBounds(target: target, nonterm: nonterm)
        }
        
        return slots[index]
    }
    
    /// Продукция, по которой свернут узел
    private func production(of node: ParseTree) -> NumberedProduction {
        productions[node.production]
    }
}

// MARK: - Private Extensions

private extension Evaluator {
    
    // MARK: - Type Entities
    
    /// Источник значения символа правой части в плоской нумерации
    enum Slot {
        
        /// Одиночный символ — поддерево или токен
        case single(ParseTree.Child)
        
        /// Символ внутри повторения — значения по виткам
        case repeated([ParseTree.Child])
        
        /// Символ выпал при устранении ε и не является сахаром
        case absent
    }
}

private extension Evaluator {
    
    // MARK: - Type Entities
    
    /// Ключ вычисляемого атрибута для обнаружения циклов
    struct AttributeKey: Hashable {
        
        /// Узел, которому принадлежит атрибут
        let node: ObjectIdentifier
        
        /// Синтезированный или наследуемый
        let inherited: Bool
        
        /// Имя атрибута
        let name: String
    }
}
