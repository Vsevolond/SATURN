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
}
