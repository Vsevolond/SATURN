//
//  Evaluator-Tests.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 27.05.2026.
//

import Testing

@testable import saturn_core

struct EvaluatorTests {
    
    /// Калькулятор складывает значения снизу вверх
    @Test func calculatorSumsBottomUp() throws {
        /// E = E + E | n, атрибут val, сложение через метод toInt и арифметику
        let expr = Nonterm(name: "E")
        expr.add(
            Alternative(
                elements: [
                    .nonterm(expr),
                    .term("plus"),
                    .nonterm(expr)
                ],
                actions: [
                    /// $0.val = $1.val + $3.val
                    .assignment(
                        reference: Reference(target: 0, attribute: "val"),
                        value: .binary(
                            left: .attribute(
                                reference: Reference(target: 1, attribute: "val")
                            ),
                            operation: .add,
                            right: .attribute(
                                reference: Reference(target: 3, attribute: "val")
                            )
                        )
                    )
                ]
            )
        )
        
        expr.add(
            Alternative(
                elements: [
                    .term("n")
                ],
                actions: [
                    /// $0.val = toInt($1.text)
                    .assignment(
                        reference: Reference(target: 0, attribute: "val"),
                        value: .call(
                            method: "toInt",
                            arguments: [
                                .attribute(
                                    reference: Reference(target: 1, attribute: "text")
                                )
                            ]
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "E": [
                    Attribute(
                        property: Property(name: "val", type: .int),
                        target: "E"
                    )
                ]
            ],
            methods: [
                "toInt": Method(
                    name: "toInt",
                    returnType: .int,
                    arguments: [.string]
                )
            ],
            axiom: expr
        )
        
        let script = "function toInt(s) { return parseInt(s, 10); }"
        
        /// Вход 2 + 3 + 4 — неоднозначен, дерево берет первую семью, сумма не зависит от группировки
        let input = [
            lexeme("n", "2", 0),
            lexeme("plus", "+", 1),
            lexeme("n", "3", 2),
            lexeme("plus", "+", 3),
            lexeme("n", "4", 4)
        ]
        
        let attributes = try evaluate(
            axiom: expr,
            specification: specification,
            script: script,
            input: input
        )
        
        guard case .int(let value) = attributes["val"] else {
            Issue.record("атрибут val не целочислен")
            return
        }
        
        #expect(value == 9)
    }
    
    /// Наследуемый атрибут течет от родителя к ребенку
    @Test func inheritedFlowsDown() throws {
        /// Type = kw { $0.name = $1.text; }
        /// Var  = id { $0.text = tag($0.kind, $1.text)); }  — читает наследуемый $0.kind
        /// Decl = Type Var { $2.kind = $1.name; $0.out = $2.text; }
        let type = Nonterm(name: "Type")
        type.add(
            Alternative(
                elements: [
                    .term("kw")
                ],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "name"),
                        value: .attribute(
                            reference: Reference(target: 1, attribute: "text")
                        )
                    )
                ]
            )
        )
        
        let variable = Nonterm(name: "Var")
        variable.add(
            Alternative(
                elements: [
                    .term("id")
                ],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "text"),
                        value: .call(
                            method: "tag",
                            arguments: [
                                .attribute(
                                    reference: Reference(target: 0, attribute: "kind")
                                ),
                                .attribute(
                                    reference: Reference(target: 1, attribute: "text")
                                )
                            ]
                        )
                    )
                ]
            )
        )
        
        let decl = Nonterm(name: "Decl")
        decl.add(
            Alternative(
                elements: [
                    .nonterm(type),
                    .nonterm(variable)
                ],
                actions: [
                    /// Наследуемый: Var.kind = Type.name
                    .assignment(
                        reference: Reference(target: 2, attribute: "kind"),
                        value: .attribute(
                            reference: Reference(target: 1, attribute: "name")
                        )
                    ),
                    /// Синтез: out = Var.text (спуск в Var после записи kind)
                    .assignment(
                        reference: Reference(target: 0, attribute: "out"),
                        value: .attribute(
                            reference: Reference(target: 2, attribute: "text")
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "Decl": [
                    Attribute(
                        property: Property(name: "out", type: .string),
                        target: "Decl"
                    )
                ],
                "Type": [
                    Attribute(
                        property: Property(name: "name", type: .string),
                        target: "Type"
                    )
                ],
                "Var": [
                    Attribute(
                        property: Property(name: "text", type: .string),
                        target: "Var"
                    ),
                    Attribute(
                        property: Property(name: "kind", type: .string),
                        target: "Var",
                        type: .inherited
                    )
                ]
            ],
            methods: [
                "tag": Method(
                    name: "tag",
                    returnType: .string,
                    arguments: [.string, .string]
                )
            ],
            axiom: decl
        )
        
        let script = "function tag(kind, name) { return kind + ':' + name; }"
        
        let input = [
            lexeme("kw", "int", 0),
            lexeme("id", "x", 1)
        ]
        
        let attributes = try evaluate(
            axiom: decl,
            specification: specification,
            script: script,
            input: input
        )
        
        guard case .string(let value) = attributes["out"] else {
            Issue.record("атрибут out не строка")
            return
        }
        
        #expect(value == "int:x")
    }
    
    /// Атрибут символа внутри `%rep` собирается в массив по виткам
    @Test func repetitionGivesArrayOverIterations() throws {
        /// List = n %rep(plus n) — список чисел через `+`
        /// $0.total = sumAll([toInt($1.text), ...по виткам toInt($3.text)])
        /// Через subscripts читаем 0-й виток: $3.text[0] и [1] — каждый виток свое n
        let list = Nonterm(name: "List")
        list.add(
            Alternative(
                elements: [
                    .term("n"),
                    .repeat(
                        productions: [
                            .term("plus"),
                            .term("n")
                        ],
                        optional: false
                    )
                ],
                actions: [
                    /// $0.total = toInt($1.text) + collect($3.text)
                    /// collect суммирует массив строк, представленных как числа
                    .assignment(
                        reference: Reference(target: 0, attribute: "total"),
                        value: .binary(
                            left: .call(
                                method: "toInt",
                                arguments: [
                                    .attribute(
                                        reference: Reference(target: 1, attribute: "text")
                                    )
                                ]
                            ),
                            operation: .add,
                            right: .call(
                                method: "sumArray",
                                arguments: [
                                    .attribute(
                                        reference: Reference(target: 3, attribute: "text")
                                    )
                                ]
                            )
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "List": [
                    Attribute(
                        property: Property(name: "total", type: .int),
                        target: "List"
                    )
                ]
            ],
            methods: [
                "toInt": Method(
                    name: "toInt",
                    returnType: .int,
                    arguments: [.string]
                ),
                "sumArray": Method(
                    name: "sumArray",
                    returnType: .int,
                    arguments: [.array(.string)]
                )
            ],
            axiom: list
        )
        
        let script = """
        function toInt(s) { return parseInt(s, 10); }
        function sumArray(arr) {
            var total = 0;
            for (var i = 0; i < arr.length; i++) { total += parseInt(arr[i], 10); }
            return total;
        }
        """
        
        /// Вход 1 + 2 + 3 — первый n=1, два витка по plus n с n=2 и n=3
        let input = [
            lexeme("n", "1", 0),
            lexeme("plus", "+", 1),
            lexeme("n", "2", 2),
            lexeme("plus", "+", 3),
            lexeme("n", "3", 4)
        ]
        
        let attributes = try evaluate(
            axiom: list,
            specification: specification,
            script: script,
            input: input
        )
        
        guard case .int(let total) = attributes["total"] else {
            Issue.record("атрибут total не целочислен")
            return
        }
        
        #expect(total == 6)
    }
    
    /// Пустой опционал дает пустое значение, читаемое в JS как null
    @Test func emptyOptionalReadsAsNull() throws {
        /// Greeting = sal [name] — опционал name
        /// $0.text = describe($1.text, $2.text)
        /// describe вторым аргументом получает массив строк (для опционала-сахара),
        /// при пустом опционале — пустой массив
        let greeting = Nonterm(name: "Greeting")
        greeting.add(
            Alternative(
                elements: [
                    .term("sal"),
                    .repeat(
                        productions: [.term("name")],
                        optional: true
                    )
                ],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "text"),
                        value: .call(
                            method: "describe",
                            arguments: [
                                .attribute(
                                    reference: Reference(target: 1, attribute: "text")
                                ),
                                .attribute(
                                    reference: Reference(target: 2, attribute: "text")
                                )
                            ]
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "Greeting": [
                    Attribute(
                        property: Property(name: "text", type: .string),
                        target: "Greeting"
                    )
                ]
            ],
            methods: [
                "describe": Method(
                    name: "describe",
                    returnType: .string,
                    arguments: [.string, .array(.string)]
                )
            ],
            axiom: greeting
        )
        
        let script = """
        function describe(sal, names) {
            if (!names || names.length === 0) { return sal + ' (нет имен)'; }
            return sal + ': ' + names.join(',');
        }
        """
        
        /// Вход без name — опционал пуст
        let attributes = try evaluate(
            axiom: greeting,
            specification: specification,
            script: script,
            input: [
                lexeme("sal", "Hi", 0)
            ]
        )
        
        guard case .string(let value) = attributes["text"] else {
            Issue.record("атрибут text не строка")
            return
        }
        
        #expect(value == "Hi (нет имен)")
    }
    
    /// Цикл атрибутов внутри одного правила распознается как ошибка
    @Test func cyclicAttributesAreDetected() throws {
        /// A = x — действие задает $0.p через $0.q и наоборот
        let a = Nonterm(name: "A")
        a.add(
            Alternative(
                elements: [
                    .term("x")
                ],
                actions: [
                    /// $0.p = $0.q + 0
                    .assignment(
                        reference: Reference(target: 0, attribute: "p"),
                        value: .attribute(
                            reference: Reference(target: 0, attribute: "q")
                        )
                    ),
                    /// $0.q = $0.p + 0
                    .assignment(
                        reference: Reference(target: 0, attribute: "q"),
                        value: .attribute(
                            reference: Reference(target: 0, attribute: "p")
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "A": [
                    Attribute(
                        property: Property(name: "p", type: .int),
                        target: "A"
                    ),
                    Attribute(
                        property: Property(name: "q", type: .int),
                        target: "A"
                    )
                ]
            ],
            axiom: a
        )
        
        /// Ожидаем ошибку циклической зависимости
        #expect(throws: EvaluateError.self) {
            try evaluate(
                axiom: a,
                specification: specification,
                script: "",
                input: [
                    lexeme("x", "x", 0)
                ]
            )
        }
    }
    
    /// Деление на ноль прерывает вычисление понятной ошибкой
    @Test func divisionByZeroFails() throws {
        /// E = a / b — действие делит две константы, второй операнд ноль
        let expr = Nonterm(name: "E")
        expr.add(
            Alternative(
                elements: [
                    .term("a"),
                    .term("slash"),
                    .term("b")
                ],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "result"),
                        value: .binary(
                            left: .int(10),
                            operation: .div,
                            right: .int(0)
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "E": [
                    Attribute(
                        property: Property(name: "result", type: .int),
                        target: "E"
                    )
                ]
            ],
            axiom: expr
        )
        
        let input = [
            lexeme("a", "10", 0),
            lexeme("slash", "/", 1),
            lexeme("b", "0", 2)
        ]
        
        #expect(throws: EvaluateError.self) {
            try evaluate(
                axiom: expr,
                specification: specification,
                script: "",
                input: input
            )
        }
    }
    
    /// Чтение атрибута выпавшего обычного нетерминала в арифметике дает ошибку
    @Test func undefinedInArithmeticFails() throws {
        /// Greeting = sal Name punct
        /// Name → id | ε (обычный обнуляемый, не сахар)
        /// Действие: $0.bad = $2.code + 1 — читает атрибут отсутствующего символа
        let name = Nonterm(name: "Name")
        name.add([
            Alternative(
                elements: [
                    .term("id")
                ],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "code"),
                        value: .int(1)
                    )
                ]
            ),
            /// Пустая альтернатива делает Name обнуляемым обычным нетерминалом
            Alternative()
        ])
        
        let greeting = Nonterm(name: "Greeting")
        greeting.add(
            Alternative(
                elements: [
                    .term("sal"),
                    .nonterm(name),
                    .term("punct")
                ],
                actions: [
                    /// $0.bad = $2.code + 1 — при выпавшем Name $2.code = undefined
                    .assignment(
                        reference: Reference(target: 0, attribute: "bad"),
                        value: .binary(
                            left: .attribute(
                                reference: Reference(target: 2, attribute: "code")
                            ),
                            operation: .add,
                            right: .int(1)
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "Greeting": [
                    Attribute(
                        property: Property(name: "bad", type: .int),
                        target: "Greeting"
                    )
                ],
                "Name": [
                    Attribute(
                        property: Property(name: "code", type: .int),
                        target: "Name"
                    )
                ]
            ],
            axiom: greeting
        )
        
        /// Вход без id — Name свернется в ε, выпадет из правила Greeting
        let input = [
            lexeme("sal", "hi", 0),
            lexeme("punct", "!", 1)
        ]
        
        #expect(throws: EvaluateError.self) {
            try evaluate(
                axiom: greeting,
                specification: specification,
                script: "",
                input: input
            )
        }
    }
    
    /// Чтение атрибута выпавшего нетерминала в аргументе метода легально через JS undefined
    @Test func undefinedInMethodCallIsLegal() throws {
        /// Действие передает $2.code в метод — JS получит undefined
        let name = Nonterm(name: "Name")
        name.add(
            Alternative(
                elements: [
                    .term("id")
                ],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "code"),
                        value: .int(1)
                    )
                ]
            )
        )
        name.add(Alternative())
        
        let greeting = Nonterm(name: "Greeting")
        greeting.add(
            Alternative(
                elements: [
                    .term("sal"),
                    .nonterm(name),
                    .term("punct")
                ],
                actions: [
                    /// $0.ok = describe($2.code) — undefined законен в аргументе
                    .assignment(
                        reference: Reference(target: 0, attribute: "ok"),
                        value: .call(
                            method: "describe",
                            arguments: [
                                .attribute(
                                    reference: Reference(target: 2, attribute: "code")
                                )
                            ]
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "Greeting": [
                    Attribute(
                        property: Property(name: "ok", type: .string),
                        target: "Greeting"
                    )
                ],
                "Name": [
                    Attribute(
                        property: Property(name: "code", type: .int),
                        target: "Name"
                    )
                ]
            ],
            methods: [
                "describe": Method(
                    name: "describe",
                    returnType: .string,
                    arguments: [.int]
                )
            ],
            axiom: greeting
        )
        
        let script = "function describe(code) { return code === undefined ? 'none' : 'code:' + code; }"
        
        let input = [
            lexeme("sal", "hi", 0),
            lexeme("punct", "!", 1)
        ]
        
        let attributes = try evaluate(
            axiom: greeting,
            specification: specification,
            script: script,
            input: input
        )
        
        guard case .string(let value) = attributes["ok"] else {
            Issue.record("атрибут ok не строка")
            return
        }
        
        #expect(value == "none")
    }
    
    /// Наследуемый атрибут без индекса раздается во ВСЕ витки `%rep`
    @Test func inheritedBroadcastsToEveryIteration() throws {
        /// List = %rep(Item)
        ///   List: $1.tag = "T"; $0.out = collect($1.text)   — tag во все витки
        /// Item = w { $0.text = tagWith($0.tag); }            — читает наследуемый tag
        let item = Nonterm(name: "Item")
        item.add(
            Alternative(
                elements: [.term("w")],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "text"),
                        value: .call(
                            method: "tagWith",
                            arguments: [
                                .attribute(reference: Reference(target: 0, attribute: "tag"))
                            ]
                        )
                    )
                ]
            )
        )
        
        let list = Nonterm(name: "List")
        list.add(
            Alternative(
                elements: [
                    .repeat(productions: [.nonterm(item)], optional: false)
                ],
                actions: [
                    /// Широковещание: каждый виток Item получает tag = "T"
                    .assignment(
                        reference: Reference(target: 1, attribute: "tag"),
                        value: .string("T")
                    ),
                    /// Синтез: собираем text всех витков в строку
                    .assignment(
                        reference: Reference(target: 0, attribute: "out"),
                        value: .call(
                            method: "collect",
                            arguments: [
                                .attribute(reference: Reference(target: 1, attribute: "text"))
                            ]
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "List": [
                    Attribute(property: Property(name: "out", type: .string), target: "List")
                ],
                "Item": [
                    Attribute(property: Property(name: "text", type: .string), target: "Item"),
                    Attribute(property: Property(name: "tag", type: .string), target: "Item", type: .inherited)
                ]
            ],
            methods: [
                "tagWith": Method(name: "tagWith", returnType: .string, arguments: [.string]),
                "collect": Method(name: "collect", returnType: .string, arguments: [.array(.string)])
            ],
            axiom: list
        )
        
        let script = """
        function tagWith(tag) { return tag === undefined ? '?' : tag; }
        function collect(arr) { return arr.join(','); }
        """
        
        /// Три витка w — все должны получить tag "T"
        let input = [
            lexeme("w", "a", 0),
            lexeme("w", "b", 1),
            lexeme("w", "c", 2)
        ]
        
        let attributes = try evaluate(
            axiom: list,
            specification: specification,
            script: script,
            input: input
        )
        
        guard case .string(let value) = attributes["out"] else {
            Issue.record("атрибут out не строка")
            return
        }
        
        /// Все три витка получили tag — иначе были бы "?"
        #expect(value == "T,T,T")
    }
    
    /// Индексное присваивание наследуемого переопределяет конкретный виток `%rep`
    @Test func inheritedIndexedTargetsOneIteration() throws {
        /// List = %rep(Item)
        ///   $1.tag = "-"       — широковещанием дефолт всем виткам
        ///   $1.tag[1] = "X"    — переопределяем только второй
        ///   $0.out = collect($1.text)
        /// Item = w { $0.text = $0.tag; }
        let item = Nonterm(name: "Item")
        item.add(
            Alternative(
                elements: [.term("w")],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "text"),
                        value: .attribute(reference: Reference(target: 0, attribute: "tag"))
                    )
                ]
            )
        )
        
        let list = Nonterm(name: "List")
        list.add(
            Alternative(
                elements: [
                    .repeat(productions: [.nonterm(item)], optional: false)
                ],
                actions: [
                    /// Дефолт во все витки
                    .assignment(
                        reference: Reference(target: 1, attribute: "tag"),
                        value: .string("-")
                    ),
                    /// Переопределяем только второй виток
                    .assignment(
                        reference: Reference(target: 1, attribute: "tag", subscripts: [.int(1)]),
                        value: .string("X")
                    ),
                    .assignment(
                        reference: Reference(target: 0, attribute: "out"),
                        value: .call(
                            method: "collect",
                            arguments: [
                                .attribute(reference: Reference(target: 1, attribute: "text"))
                            ]
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "List": [
                    Attribute(property: Property(name: "out", type: .string), target: "List")
                ],
                "Item": [
                    Attribute(property: Property(name: "text", type: .string), target: "Item"),
                    Attribute(property: Property(name: "tag", type: .string), target: "Item", type: .inherited)
                ]
            ],
            methods: [
                "collect": Method(name: "collect", returnType: .string, arguments: [.array(.string)])
            ],
            axiom: list
        )
        
        let script = "function collect(arr) { return arr.join(','); }"
        
        let input = [
            lexeme("w", "a", 0),
            lexeme("w", "b", 1),
            lexeme("w", "c", 2)
        ]
        
        let attributes = try evaluate(
            axiom: list,
            specification: specification,
            script: script,
            input: input
        )
        
        guard case .string(let value) = attributes["out"] else {
            Issue.record("атрибут out не строка")
            return
        }
        
        /// Дефолт "-" везде, второй виток переопределен на "X"
        #expect(value == "-,X,-")
    }
    
    /// Индекс витка вне границ при записи наследуемого дает subscriptOutOfBounds
    @Test func inheritedIndexOutOfBoundsFails() throws {
        let item = Nonterm(name: "Item")
        item.add(
            Alternative(
                elements: [.term("w")],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "text"),
                        value: .string("ok")
                    )
                ]
            )
        )
        
        let list = Nonterm(name: "List")
        list.add(
            Alternative(
                elements: [
                    .repeat(productions: [.nonterm(item)], optional: false)
                ],
                actions: [
                    /// Витков всего один (index 0), индекс 5 вне границ
                    .assignment(
                        reference: Reference(target: 1, attribute: "tag", subscripts: [.int(5)]),
                        value: .string("X")
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "List": [
                    Attribute(property: Property(name: "out", type: .string), target: "List")
                ],
                "Item": [
                    Attribute(property: Property(name: "text", type: .string), target: "Item"),
                    Attribute(property: Property(name: "tag", type: .string), target: "Item", type: .inherited)
                ]
            ],
            axiom: list
        )
        
        #expect {
            try evaluate(
                axiom: list,
                specification: specification,
                script: "",
                input: [lexeme("w", "a", 0)]
            )
        } throws: { error in
            guard case EvaluateError.subscriptOutOfBounds = error else { return false }
            return true
        }
    }
    
    /// Индексное присваивание в левую часть правит элемент массива-атрибута
    @Test func leftIndexedAssignmentUpdatesArrayElement() throws {
        /// A = w
        ///   $0.list = make()      — JS отдает массив [0,0,0]
        ///   $0.list[1] = 7        — правим второй элемент
        ///   $0.sum = sumArray($0.list)
        let a = Nonterm(name: "A")
        a.add(
            Alternative(
                elements: [.term("w")],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "list"),
                        value: .call(method: "make", arguments: [])
                    ),
                    .assignment(
                        reference: Reference(target: 0, attribute: "list", subscripts: [.int(1)]),
                        value: .int(7)
                    ),
                    .assignment(
                        reference: Reference(target: 0, attribute: "sum"),
                        value: .call(
                            method: "sumArray",
                            arguments: [
                                .attribute(reference: Reference(target: 0, attribute: "list"))
                            ]
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "A": [
                    Attribute(property: Property(name: "list", type: .array(.int)), target: "A"),
                    Attribute(property: Property(name: "sum", type: .int), target: "A")
                ]
            ],
            methods: [
                "make": Method(name: "make", returnType: .array(.int), arguments: []),
                "sumArray": Method(name: "sumArray", returnType: .int, arguments: [.array(.int)])
            ],
            axiom: a
        )
        
        let script = """
        function make() { return [0, 0, 0]; }
        function sumArray(arr) { var t = 0; for (var i = 0; i < arr.length; i++) t += arr[i]; return t; }
        """
        
        let attributes = try evaluate(
            axiom: a,
            specification: specification,
            script: script,
            input: [lexeme("w", "x", 0)]
        )
        
        guard case .int(let sum) = attributes["sum"] else {
            Issue.record("атрибут sum не целочислен")
            return
        }
        
        /// [0,7,0] → сумма 7, значит индексная запись попала во второй элемент
        #expect(sum == 7)
    }
    
    /// Чтение по индексу: атрибут витка `%rep` читается как элемент массива
    @Test func indexedReadPicksIterationValue() throws {
        /// List = n %rep(plus n)
        ///   $0.second = toInt($3.text[1])  — текст второго витка
        let list = Nonterm(name: "List")
        list.add(
            Alternative(
                elements: [
                    .term("n"),
                    .repeat(productions: [.term("plus"), .term("n")], optional: false)
                ],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "second"),
                        value: .call(
                            method: "toInt",
                            arguments: [
                                .attribute(reference: Reference(target: 3, attribute: "text", subscripts: [.int(1)]))
                            ]
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "List": [
                    Attribute(property: Property(name: "second", type: .int), target: "List")
                ]
            ],
            methods: [
                "toInt": Method(name: "toInt", returnType: .int, arguments: [.string])
            ],
            axiom: list
        )
        
        let script = "function toInt(s) { return parseInt(s, 10); }"
        
        /// 1 + 2 + 3 — витки plus n: текст n = "2" (виток 0) и "3" (виток 1)
        let input = [
            lexeme("n", "1", 0),
            lexeme("plus", "+", 1),
            lexeme("n", "2", 2),
            lexeme("plus", "+", 3),
            lexeme("n", "3", 4)
        ]
        
        let attributes = try evaluate(
            axiom: list,
            specification: specification,
            script: script,
            input: input
        )
        
        guard case .int(let value) = attributes["second"] else {
            Issue.record("атрибут second не целочислен")
            return
        }
        
        /// $3.text[1] = текст второго витка = "3"
        #expect(value == 3)
    }
    
    /// Вложенный сахар `%rep([C])` читается как массив опционалов
    @Test func nestedRepOfOptionalReadsAsArrayOfOptionals() throws {
        /// List = %rep( w [ tail ] )
        ///   $0.out = render($1.text, $2.text)
        /// первый виток с tail, второй — без; render видит [str, null]
        let list = Nonterm(name: "List")
        list.add(
            Alternative(
                elements: [
                    .repeat(
                        productions: [
                            .term("w"),
                            .optional(productions: [.term("tail")])
                        ],
                        optional: false
                    )
                ],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "out"),
                        value: .call(
                            method: "render",
                            arguments: [
                                .attribute(reference: Reference(target: 1, attribute: "text")),
                                .attribute(reference: Reference(target: 2, attribute: "text"))
                            ]
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "List": [
                    Attribute(property: Property(name: "out", type: .string), target: "List")
                ]
            ],
            methods: [
                /// $1.text — array<string> по виткам, $2.text — array<optional<string>>
                "render": Method(
                    name: "render",
                    returnType: .string,
                    arguments: [.array(.string), .array(.optional(.string))]
                )
            ],
            axiom: list
        )
        
        let script = """
        function render(words, tails) {
            var parts = [];
            for (var i = 0; i < words.length; i++) {
                parts.push(words[i] + ':' + (tails[i] === null ? 'NONE' : tails[i]));
            }
            return parts.join('|');
        }
        """
        
        /// виток 0: w "a" tail "t"; виток 1: w "b" без tail
        let input = [
            lexeme("w", "a", 0),
            lexeme("tail", "t", 1),
            lexeme("w", "b", 2)
        ]
        
        let attributes = try evaluate(
            axiom: list,
            specification: specification,
            script: script,
            input: input
        )
        
        guard case .string(let value) = attributes["out"] else {
            Issue.record("атрибут out не строка")
            return
        }
        
        #expect(value == "a:t|b:NONE")
    }
    
    /// Деление нацело дает int, неточное — float
    @Test func divisionTypingIntVsFloat() throws {
        /// E = a — два присваивания: точное деление и неточное
        let expr = Nonterm(name: "E")
        expr.add(
            Alternative(
                elements: [.term("a")],
                actions: [
                    /// $0.whole = 4 / 2 → int 2
                    .assignment(
                        reference: Reference(target: 0, attribute: "whole"),
                        value: .binary(left: .int(4), operation: .div, right: .int(2))
                    ),
                    /// $0.frac = 10 / 4 → float 2.5
                    .assignment(
                        reference: Reference(target: 0, attribute: "frac"),
                        value: .binary(left: .int(10), operation: .div, right: .int(4))
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "E": [
                    Attribute(property: Property(name: "whole", type: .int), target: "E"),
                    Attribute(property: Property(name: "frac", type: .float), target: "E")
                ]
            ],
            axiom: expr
        )
        
        let attributes = try evaluate(
            axiom: expr,
            specification: specification,
            script: "",
            input: [lexeme("a", "a", 0)]
        )
        
        guard case .int(let whole) = attributes["whole"] else {
            Issue.record("whole не int")
            return
        }
        guard case .float(let frac) = attributes["frac"] else {
            Issue.record("frac не float")
            return
        }
        
        #expect(whole == 2)
        #expect(frac == 2.5)
    }
    
    /// Сложение строк через оператор +
    @Test func stringConcatenation() throws {
        /// Pair = a b { $0.joined = $1.text + $2.text; }
        let pair = Nonterm(name: "Pair")
        pair.add(
            Alternative(
                elements: [.term("a"), .term("b")],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "joined"),
                        value: .binary(
                            left: .attribute(reference: Reference(target: 1, attribute: "text")),
                            operation: .add,
                            right: .attribute(reference: Reference(target: 2, attribute: "text"))
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "Pair": [
                    Attribute(property: Property(name: "joined", type: .string), target: "Pair")
                ]
            ],
            axiom: pair
        )
        
        let attributes = try evaluate(
            axiom: pair,
            specification: specification,
            script: "",
            input: [lexeme("a", "foo", 0), lexeme("b", "bar", 1)]
        )
        
        guard case .string(let value) = attributes["joined"] else {
            Issue.record("joined не строка")
            return
        }
        
        #expect(value == "foobar")
    }
    
    /// Цикл через спуск между двумя узлами распознается
    @Test func cyclicThroughDescentIsDetected() throws {
        /// A = B  { $0.s = $1.s; }
        /// B = A  { $0.s = $1.s; }   — взаимная рекурсия по спуску
        let a = Nonterm(name: "A")
        let b = Nonterm(name: "B")
        
        a.add(
            Alternative(
                elements: [.nonterm(b)],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "s"),
                        value: .attribute(reference: Reference(target: 1, attribute: "s"))
                    )
                ]
            )
        )
        b.add(
            Alternative(
                elements: [.nonterm(a)],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "s"),
                        value: .attribute(reference: Reference(target: 1, attribute: "s"))
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "A": [Attribute(property: Property(name: "s", type: .int), target: "A")],
                "B": [Attribute(property: Property(name: "s", type: .int), target: "B")]
            ],
            axiom: a
        )
        
        /// Грамматика A→B→A — единичный цикл; если разбор дойдет до приема,
        /// вычисление обязано упасть, а не зациклиться
        #expect(throws: (any Error).self) {
            try evaluate(
                axiom: a,
                specification: specification,
                script: "",
                input: [lexeme("a", "a", 0)]
            )
        }
    }
    
    /// Присваивание значения-undefined напрямую (не в арифметике) легально
    @Test func undefinedAssignedValueIsLegal() throws {
        /// Greeting = sal Name punct, Name → id | ε
        /// $0.bad = $2.code — при выпавшем Name значение undefined, запись проходит
        let name = Nonterm(name: "Name")
        name.add([
            Alternative(
                elements: [.term("id")],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "code"),
                        value: .int(1)
                    )
                ]
            ),
            Alternative()
        ])
        
        let greeting = Nonterm(name: "Greeting")
        greeting.add(
            Alternative(
                elements: [.term("sal"), .nonterm(name), .term("punct")],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "bad"),
                        value: .attribute(reference: Reference(target: 2, attribute: "code"))
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "Greeting": [Attribute(property: Property(name: "bad", type: .int), target: "Greeting")],
                "Name": [Attribute(property: Property(name: "code", type: .int), target: "Name")]
            ],
            axiom: greeting
        )
        
        let attributes = try evaluate(
            axiom: greeting,
            specification: specification,
            script: "",
            input: [lexeme("sal", "hi", 0), lexeme("punct", "!", 1)]
        )
        
        /// Значение записалось как отсутствующее
        #expect(attributes["bad"]?.isUndefined == true)
    }
    
    /// Граф зависимостей фиксирует ребра источник → цель
    @Test func dependencyGraphRecordsEdges() throws {
        /// E = a plus b { $0.sum = toInt($1.text) + toInt($3.text); }
        let expr = Nonterm(name: "E")
        expr.add(
            Alternative(
                elements: [.term("a"), .term("plus"), .term("b")],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "sum"),
                        value: .binary(
                            left: .call(
                                method: "toInt",
                                arguments: [.attribute(reference: Reference(target: 1, attribute: "text"))]
                            ),
                            operation: .add,
                            right: .call(
                                method: "toInt",
                                arguments: [.attribute(reference: Reference(target: 3, attribute: "text"))]
                            )
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "E": [
                    Attribute(property: Property(name: "sum", type: .int), target: "E")
                ]
            ],
            methods: [
                "toInt": Method(name: "toInt", returnType: .int, arguments: [.string])
            ],
            axiom: expr
        )
        
        let script = "function toInt(s) { return parseInt(s, 10); }"
        let input = [lexeme("a", "2", 0), lexeme("plus", "+", 1), lexeme("b", "3", 2)]
        
        let result = try evaluateAll(
            axiom: expr,
            specification: specification,
            script: script,
            input: input
        )
        
        /// Должны быть ребра от текстов токенов к синтезированному sum нетерминала E
        let edgesToSum = result.dependencyGraph.edges.filter {
            $0.to.attribute == "sum" && $0.to.kind == .synthesized
        }
        
        #expect(edgesToSum.count == 2)
        #expect(edgesToSum.allSatisfy { $0.from.kind == .token && $0.from.attribute == "text" })
    }
    
    /// `%rep[X]` дает пустой массив, когда витков ноль, но правило непусто
    @Test func repeatZeroOrMoreEmptyGivesEmptyArray() throws {
        /// Wrap = mark %rep[ w ]   — mark всегда есть, повторение пустое
        /// $0.out = collect($2.text)
        let wrap = Nonterm(name: "Wrap")
        wrap.add(
            Alternative(
                elements: [
                    .term("mark"),
                    .repeat(productions: [.term("w")], optional: true)
                ],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "out"),
                        value: .call(
                            method: "collect",
                            arguments: [
                                .attribute(reference: Reference(target: 2, attribute: "text"))
                            ]
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "Wrap": [Attribute(property: Property(name: "out", type: .string), target: "Wrap")]
            ],
            methods: [
                "collect": Method(name: "collect", returnType: .string, arguments: [.array(.string)])
            ],
            axiom: wrap
        )
        
        let script = "function collect(arr) { return arr.length === 0 ? 'EMPTY' : arr.join(','); }"
        
        /// Только mark — повторение дает ноль витков, но дерево есть (правило непусто)
        let attributes = try evaluate(
            axiom: wrap,
            specification: specification,
            script: script,
            input: [lexeme("mark", "#", 0)]
        )
        
        guard case .string(let value) = attributes["out"] else {
            Issue.record("атрибут out не строка")
            return
        }
        
        #expect(value == "EMPTY")
    }
    
    /// `%rep[X]` через обертку: непустой вход собирает витки в массив
    @Test func repeatZeroOrMoreNonEmptyCollectsIterations() throws {
        /// List = %rep[ w ]
        /// $0.out = collect($1.text)
        let list = Nonterm(name: "List")
        list.add(
            Alternative(
                elements: [
                    .repeat(productions: [.term("w")], optional: true)
                ],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "out"),
                        value: .call(
                            method: "collect",
                            arguments: [
                                .attribute(reference: Reference(target: 1, attribute: "text"))
                            ]
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "List": [
                    Attribute(property: Property(name: "out", type: .string), target: "List")
                ]
            ],
            methods: [
                "collect": Method(name: "collect", returnType: .string, arguments: [.array(.string)])
            ],
            axiom: list
        )
        
        let script = "function collect(arr) { return arr.join(','); }"
        
        /// Три витка — обертка делегирует в гребенку один-и-более
        let input = [
            lexeme("w", "a", 0),
            lexeme("w", "b", 1),
            lexeme("w", "c", 2)
        ]
        
        let attributes = try evaluate(
            axiom: list,
            specification: specification,
            script: script,
            input: input
        )
        
        guard case .string(let value) = attributes["out"] else {
            Issue.record("атрибут out не строка")
            return
        }
        
        #expect(value == "a,b,c")
    }
    
    /// Опционал внутри `%rep[...]`: `%rep[ w [tail] ]` — пустые витки не теряются
    @Test func repeatZeroOfWordWithOptionalTail() throws {
        /// List = %rep[ w [tail] ]
        /// $0.out = render($1.text, $2.text)
        /// проверяем, что обертка ноль-и-более не обрывает раскрутку на пустом tail
        let list = Nonterm(name: "List")
        list.add(
            Alternative(
                elements: [
                    .repeat(
                        productions: [
                            .term("w"),
                            .optional(productions: [.term("tail")])
                        ],
                        optional: true
                    )
                ],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "out"),
                        value: .call(
                            method: "render",
                            arguments: [
                                .attribute(reference: Reference(target: 1, attribute: "text")),
                                .attribute(reference: Reference(target: 2, attribute: "text"))
                            ]
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "List": [
                    Attribute(property: Property(name: "out", type: .string), target: "List")
                ]
            ],
            methods: [
                "render": Method(
                    name: "render",
                    returnType: .string,
                    arguments: [.array(.string), .array(.optional(.string))]
                )
            ],
            axiom: list
        )
        
        let script = """
        function render(words, tails) {
            var parts = [];
            for (var i = 0; i < words.length; i++) {
                parts.push(words[i] + ':' + (tails[i] === null ? 'NONE' : tails[i]));
            }
            return parts.join('|');
        }
        """
        
        /// виток 0: w "a" tail "t"; виток 1: w "b" без tail; виток 2: w "c" tail "u"
        /// пустой tail в среднем витке не должен оборвать раскрутку
        let input = [
            lexeme("w", "a", 0),
            lexeme("tail", "t", 1),
            lexeme("w", "b", 2),
            lexeme("w", "c", 3),
            lexeme("tail", "u", 4)
        ]
        
        let attributes = try evaluate(
            axiom: list,
            specification: specification,
            script: script,
            input: input
        )
        
        guard case .string(let value) = attributes["out"] else {
            Issue.record("атрибут out не строка")
            return
        }
        
        /// Три витка, средний с null — раскрутка не оборвалась на пустом tail
        #expect(value == "a:t|b:NONE|c:u")
    }
    
    /// Повторение внутри повторения: `%rep( w %rep(d) )`
    @Test func repeatInsideRepeat() throws {
        /// Group = %rep( w %rep(d) )
        /// $0.out = render($1.text, $2.text)
        /// $1.text — array<string> (слова), $2.text — array<array<string>> (цифры по виткам)
        let group = Nonterm(name: "Group")
        group.add(
            Alternative(
                elements: [
                    .repeat(
                        productions: [
                            .term("w"),
                            .repeat(productions: [.term("d")], optional: false)
                        ],
                        optional: false
                    )
                ],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "out"),
                        value: .call(
                            method: "render",
                            arguments: [
                                .attribute(reference: Reference(target: 1, attribute: "text")),
                                .attribute(reference: Reference(target: 2, attribute: "text"))
                            ]
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "Group": [
                    Attribute(property: Property(name: "out", type: .string), target: "Group")
                ]
            ],
            methods: [
                "render": Method(
                    name: "render",
                    returnType: .string,
                    arguments: [.array(.string), .array(.array(.string))]
                )
            ],
            axiom: group
        )
        
        let script = """
        function render(words, digits) {
            var parts = [];
            for (var i = 0; i < words.length; i++) {
                parts.push(words[i] + '[' + digits[i].join('') + ']');
            }
            return parts.join('|');
        }
        """
        
        /// виток 0: w "a", два d "1" "2"; виток 1: w "b", один d "3"
        let input = [
            lexeme("w", "a", 0),
            lexeme("d", "1", 1),
            lexeme("d", "2", 2),
            lexeme("w", "b", 3),
            lexeme("d", "3", 4)
        ]
        
        let attributes = try evaluate(
            axiom: group,
            specification: specification,
            script: script,
            input: input
        )
        
        guard case .string(let value) = attributes["out"] else {
            Issue.record("атрибут out не строка")
            return
        }
        
        /// Внутреннее повторение собирается в подмассив на каждый внешний виток
        #expect(value == "a[12]|b[3]")
    }
    
    /// Повторение внутри опционала: `[ %rep(d) ]`
    @Test func repeatInsideOptional() throws {
        /// Box = pre [ %rep(d) ] post
        /// $0.out = render($2.text) — $2 это опционал, внутри которого массив цифр
        let box = Nonterm(name: "Box")
        box.add(
            Alternative(
                elements: [
                    .term("pre"),
                    .optional(
                        productions: [
                            .repeat(productions: [.term("d")], optional: false)
                        ]
                    ),
                    .term("post")
                ],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "out"),
                        value: .call(
                            method: "render",
                            arguments: [
                                .attribute(reference: Reference(target: 2, attribute: "text"))
                            ]
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "Box": [
                    Attribute(property: Property(name: "out", type: .string), target: "Box")
                ]
            ],
            methods: [
                /// $2.text — optional<array<string>>: опционал вокруг массива витков
                "render": Method(
                    name: "render",
                    returnType: .string,
                    arguments: [.optional(.array(.string))]
                )
            ],
            axiom: box
        )
        
        let script = """
        function render(digits) {
            if (digits === null) { return 'NONE'; }
            return digits.join('');
        }
        """
        
        /// Опционал сработал: pre, два d "1" "2", post
        let input = [
            lexeme("pre", "(", 0),
            lexeme("d", "1", 1),
            lexeme("d", "2", 2),
            lexeme("post", ")", 3)
        ]
        
        let attributes = try evaluate(
            axiom: box,
            specification: specification,
            script: script,
            input: input
        )
        
        guard case .string(let value) = attributes["out"] else {
            Issue.record("атрибут out не строка")
            return
        }
        
        /// optional<array> сработал → массив "12"
        #expect(value == "12")
    }
    
    /// Опционал внутри опционала: `[ [x] ]` на отсутствующем входе
    @Test func optionalInsideOptionalAbsent() throws {
        /// Wrap = pre [ [x] ] post
        /// $0.out = render($2.text) — $2 это optional<optional<string>>
        let wrap = Nonterm(name: "Wrap")
        wrap.add(
            Alternative(
                elements: [
                    .term("pre"),
                    .optional(
                        productions: [
                            .optional(productions: [.term("x")])
                        ]
                    ),
                    .term("post")
                ],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "out"),
                        value: .call(
                            method: "render",
                            arguments: [
                                .attribute(reference: Reference(target: 2, attribute: "text"))
                            ]
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "Wrap": [
                    Attribute(property: Property(name: "out", type: .string), target: "Wrap")
                ]
            ],
            methods: [
                "render": Method(
                    name: "render",
                    returnType: .string,
                    arguments: [.optional(.optional(.string))]
                )
            ],
            axiom: wrap
        )
        
        let script = "function render(v) { return v === null ? 'NONE' : String(v); }"
        
        /// Внешний опционал не сработал: только pre post
        let input = [
            lexeme("pre", "(", 0),
            lexeme("post", ")", 1)
        ]
        
        let attributes = try evaluate(
            axiom: wrap,
            specification: specification,
            script: script,
            input: input
        )
        
        guard case .string(let value) = attributes["out"] else {
            Issue.record("атрибут out не строка")
            return
        }
        
        /// Пустой вложенный опционал → null
        #expect(value == "NONE")
    }
    
    /// Тройная вложенность: повторение в опционале в повторении
    /// `%rep( w [ %rep(d) ] )` — каждый виток слово и необязательный список цифр
    @Test func tripleRepeatOptionalRepeat() throws {
        /// Group = %rep( w [ %rep(d) ] )
        /// $1.text — array<string> (слова по виткам)
        /// $2.text — array<optional<array<string>>>:
        ///   внешний %rep → array, опционал [..] → optional, внутренний %rep → array
        let group = Nonterm(name: "Group")
        group.add(
            Alternative(
                elements: [
                    .repeat(
                        productions: [
                            .term("w"),
                            .optional(
                                productions: [
                                    .repeat(productions: [.term("d")], optional: false)
                                ]
                            )
                        ],
                        optional: false
                    )
                ],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "out"),
                        value: .call(
                            method: "render",
                            arguments: [
                                .attribute(reference: Reference(target: 1, attribute: "text")),
                                .attribute(reference: Reference(target: 2, attribute: "text"))
                            ]
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "Group": [
                    Attribute(property: Property(name: "out", type: .string), target: "Group")
                ]
            ],
            methods: [
                "render": Method(
                    name: "render",
                    returnType: .string,
                    arguments: [
                        .array(.string),
                        .array(.optional(.array(.string)))
                    ]
                )
            ],
            axiom: group
        )
        
        let script = """
        function render(words, lists) {
            var parts = [];
            for (var i = 0; i < words.length; i++) {
                var l = lists[i];
                var shown = (l === null) ? 'NONE' : '[' + l.join('') + ']';
                parts.push(words[i] + shown);
            }
            return parts.join('|');
        }
        """
        
        /// виток 0: w "a", [%rep(d)] = "1" "2"; виток 1: w "b" без списка
        let input = [
            lexeme("w", "a", 0),
            lexeme("d", "1", 1),
            lexeme("d", "2", 2),
            lexeme("w", "b", 3)
        ]
        
        let attributes = try evaluate(
            axiom: group,
            specification: specification,
            script: script,
            input: input
        )
        
        guard case .string(let value) = attributes["out"] else {
            Issue.record("атрибут out не строка")
            return
        }
        
        /// Первый виток со списком, второй без — опционал внутри дает null
        #expect(value == "a[12]|bNONE")
    }
    
    /// Тройная вложенность: опционал в повторении в опционале
    /// `[ %rep( [x] ) ]` — необязательный список необязательных x
    @Test func tripleOptionalRepeatOptional() throws {
        /// Box = pre [ %rep( [x] ) ] post
        /// $2.text — optional<array<optional<string>>>:
        ///   внешний [..] → optional, %rep → array, внутренний [x] → optional
        let box = Nonterm(name: "Box")
        box.add(
            Alternative(
                elements: [
                    .term("pre"),
                    .optional(
                        productions: [
                            .repeat(
                                productions: [
                                    .optional(productions: [.term("x")])
                                ],
                                optional: false
                            )
                        ]
                    ),
                    .term("post")
                ],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "out"),
                        value: .call(
                            method: "render",
                            arguments: [
                                .attribute(reference: Reference(target: 2, attribute: "text"))
                            ]
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "Box": [
                    Attribute(property: Property(name: "out", type: .string), target: "Box")
                ]
            ],
            methods: [
                "render": Method(
                    name: "render",
                    returnType: .string,
                    arguments: [.optional(.array(.optional(.string)))]
                )
            ],
            axiom: box
        )
        
        let script = """
        function render(v) {
            if (v === null) { return 'OUTER_NONE'; }
            var parts = [];
            for (var i = 0; i < v.length; i++) {
                parts.push(v[i] === null ? '_' : v[i]);
            }
            return '<' + parts.join(',') + '>';
        }
        """
        
        /// Внешний опционал сработал, %rep из двух витков [x]: первый "y", второй пустой
        /// pre, x "y", (пустой [x] не представлен токеном), post — но пустой виток
        /// внутри %rep требует, чтобы виток был; берем два x: "y" и "z"
        let input = [
            lexeme("pre", "(", 0),
            lexeme("x", "y", 1),
            lexeme("x", "z", 2),
            lexeme("post", ")", 3)
        ]
        
        let attributes = try evaluate(
            axiom: box,
            specification: specification,
            script: script,
            input: input
        )
        
        guard case .string(let value) = attributes["out"] else {
            Issue.record("атрибут out не строка")
            return
        }
        
        /// Внешний опционал есть, два витка с непустыми x
        #expect(value == "<y,z>")
    }
    
    /// Непокрытая комбинация: повторение внутри ноль-и-более
    /// `%rep[ w %rep(d) ]` — обертка rep0 над гребенкой, внутри которой еще одно повторение
    @Test func repeatZeroOfWordWithRepeat() throws {
        /// List = %rep[ w %rep(d) ]
        /// $1.text — array<string>, $2.text — array<array<string>>
        let list = Nonterm(name: "List")
        list.add(
            Alternative(
                elements: [
                    .repeat(
                        productions: [
                            .term("w"),
                            .repeat(productions: [.term("d")], optional: false)
                        ],
                        optional: true
                    )
                ],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "out"),
                        value: .call(
                            method: "render",
                            arguments: [
                                .attribute(reference: Reference(target: 1, attribute: "text")),
                                .attribute(reference: Reference(target: 2, attribute: "text"))
                            ]
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "List": [
                    Attribute(property: Property(name: "out", type: .string), target: "List")
                ]
            ],
            methods: [
                "render": Method(
                    name: "render",
                    returnType: .string,
                    arguments: [.array(.string), .array(.array(.string))]
                )
            ],
            axiom: list
        )
        
        let script = """
        function render(words, digits) {
            var parts = [];
            for (var i = 0; i < words.length; i++) {
                parts.push(words[i] + '[' + digits[i].join('') + ']');
            }
            return parts.join('|');
        }
        """
        
        /// виток 0: w "a" d "1" d "2"; виток 1: w "b" d "3"
        let input = [
            lexeme("w", "a", 0),
            lexeme("d", "1", 1),
            lexeme("d", "2", 2),
            lexeme("w", "b", 3),
            lexeme("d", "3", 4)
        ]
        
        let attributes = try evaluate(
            axiom: list,
            specification: specification,
            script: script,
            input: input
        )
        
        guard case .string(let value) = attributes["out"] else {
            Issue.record("атрибут out не строка")
            return
        }
        
        /// Обертка rep0 над гребенкой, внутренний %rep собирает цифры по витку
        #expect(value == "a[12]|b[3]")
    }
    
    /// Непокрытая комбинация: ноль-и-более внутри ноль-и-более
    /// `%rep[ w %rep[d] ]` — обертка над гребенкой, внутри еще одна обертка
    @Test func repeatZeroOfWordWithRepeatZero() throws {
        /// List = %rep[ w %rep[d] ]
        /// внутренний %rep[d] может дать ноль цифр в каком-то витке
        let list = Nonterm(name: "List")
        list.add(
            Alternative(
                elements: [
                    .repeat(
                        productions: [
                            .term("w"),
                            .repeat(productions: [.term("d")], optional: true)
                        ],
                        optional: true
                    )
                ],
                actions: [
                    .assignment(
                        reference: Reference(target: 0, attribute: "out"),
                        value: .call(
                            method: "render",
                            arguments: [
                                .attribute(reference: Reference(target: 1, attribute: "text")),
                                .attribute(reference: Reference(target: 2, attribute: "text"))
                            ]
                        )
                    )
                ]
            )
        )
        
        let specification = Specification(
            attributes: [
                "List": [
                    Attribute(property: Property(name: "out", type: .string), target: "List")
                ]
            ],
            methods: [
                "render": Method(
                    name: "render",
                    returnType: .string,
                    arguments: [.array(.string), .array(.array(.string))]
                )
            ],
            axiom: list
        )
        
        let script = """
        function render(words, digits) {
            var parts = [];
            for (var i = 0; i < words.length; i++) {
                var d = digits[i];
                parts.push(words[i] + '[' + (d.length === 0 ? '-' : d.join('')) + ']');
            }
            return parts.join('|');
        }
        """
        
        /// виток 0: w "a" d "1"; виток 1: w "b" без цифр (внутренний %rep[d] = ноль)
        let input = [
            lexeme("w", "a", 0),
            lexeme("d", "1", 1),
            lexeme("w", "b", 2)
        ]
        
        let attributes = try evaluate(
            axiom: list,
            specification: specification,
            script: script,
            input: input
        )
        
        guard case .string(let value) = attributes["out"] else {
            Issue.record("атрибут out не строка")
            return
        }
        
        /// Второй виток с пустым внутренним повторением → пустой массив, не потеря витка
        #expect(value == "a[1]|b[-]")
    }
    
    // MARK: - Private Methods
    
    /// Лексема с тривиальной позицией
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
    
    /// Прогоняет грамматику и вход через конвейер, возвращает атрибуты корня
    private func evaluate(
        axiom: Nonterm,
        specification: Specification,
        script: String,
        input: [Lexeme]
    ) throws -> [String: AttributeValue] {
        let (expanded, map) = SugarExpander().expand(axiom: axiom)
        let epsilonFree = try EpsilonEliminator().eliminate(expanded, map: map)
        let table = try ParseTable(epsilonFree.value, acceptsEmpty: epsilonFree.acceptsEmpty)
        
        let forest = try GLRParser(table: table, lexemes: input).parse()
        let tree = try TreeBuilder(map: map, productions: table.productions).build(from: forest)
        
        let runtime = try SemanticRuntime(script: script)
        let evaluator = Evaluator(
            specification: specification,
            productions: table.productions,
            runtime: runtime
        )
        
        return try evaluator.evaluate(tree)
    }
    
    /// Прогоняет грамматику и вход через конвейер, возвращает полный результат с графом
    private func evaluateAll(
        axiom: Nonterm,
        specification: Specification,
        script: String,
        input: [Lexeme]
    ) throws -> EvaluateResult {
        let (expanded, map) = SugarExpander().expand(axiom: axiom)
        let epsilonFree = try EpsilonEliminator().eliminate(expanded, map: map)
        let table = try ParseTable(epsilonFree.value, acceptsEmpty: epsilonFree.acceptsEmpty)
        
        let forest = try GLRParser(table: table, lexemes: input).parse()
        let tree = try TreeBuilder(map: map, productions: table.productions).build(from: forest)
        let nodeIndex = NodeIndex(root: tree)
        
        let runtime = try SemanticRuntime(script: script)
        let evaluator = Evaluator(
            specification: specification,
            productions: table.productions,
            runtime: runtime,
            nodeIndex: nodeIndex
        )
        
        return try evaluator.evaluateAll(tree)
    }
}
