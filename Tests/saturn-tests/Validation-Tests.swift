//
//  Validation-Tests.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 25.05.2026.
//

import Testing

@testable import saturn
@testable import saturn_core

// MARK: - Test Methods

struct ValidationTests {
    
    // MARK: - Tests
    
    /// `duplicateTokenName`: два токена с одинаковым именем
    @Test func testDuplicateTokenName() {
        let spec = """
        %tokens
        A = "a"
        A = "b"
        %grammar
        s = A
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .duplicateTokenName("A")
        )
    }

    /// `duplicateTokenValue`: два токена с одинаковым значением
    @Test func testDuplicateTokenValue() {
        let spec = """
        %tokens
        A = "x"
        B = "x"
        %grammar
        s = A
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .duplicateTokenValue(first: "A", second: "B")
        )
    }

    /// `unknownAttributeType`: тип атрибута ссылается на необъявленный пользовательский тип
    @Test func testUnknownAttributeType() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : Unknown ;
        %grammar
        s = A
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .unknownAttributeType(name: "Unknown", symbol: "s", attribute: "v")
        )
    }

    /// `unknownArgumentType`: тип аргумента метода — необъявленный пользовательский тип
    @Test func testUnknownArgumentType() {
        let spec = """
        %tokens
        A = "a"
        %methods
        void m(Unknown);
        %grammar
        s = A
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .unknownArgumentType(name: "Unknown", method: "m")
        )
    }

    /// `unknownReturnType`: возвращаемый тип метода — необъявленный пользовательский тип
    @Test func testUnknownReturnType() {
        let spec = """
        %tokens
        A = "a"
        %methods
        Unknown m();
        %grammar
        s = A
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .unknownReturnType(name: "Unknown", method: "m")
        )
    }

    /// `duplicateAttribute`: один атрибут объявлен у символа дважды
    @Test func testDuplicateAttribute() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        s.v : bool ;
        %grammar
        s = A
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .duplicateAttribute(name: "v", symbol: "s")
        )
    }

    /// `tokenAttributeNotAllowed`: атрибут объявлен для токена
    @Test func testTokenAttributeNotAllowed() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        A.v : int ;
        %grammar
        s = A
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .tokenAttributeNotAllowed(attribute: "v", token: "A")
        )
    }

    /// `unknownTerm`: в правиле использован терминал, не объявленный в секции токенов
    @Test func testUnknownTerm() {
        let spec = """
        %tokens
        A = "a"
        %grammar
        s = A B
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .unknownTerm(name: "B")
        )
    }

    /// `emptyNonterm`: достижимый нетерминал без альтернатив
    @Test func testEmptyNonterm() {
        let spec = """
        %tokens
        A = "a"
        %grammar
        s = A b
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .emptyNonterm(name: "b")
        )
    }

    /// `referenceOutOfBounds`: $2 при одном элементе в правой части
    @Test func testReferenceOutOfBounds() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        %grammar
        s = A { $0.v = $2.text; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .referenceOutOfBounds(target: 2, count: 1, nonterm: "s")
        )
    }

    /// `unknownAttribute`: ссылка на несуществующий атрибут левой части
    @Test func testUnknownAttribute() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        %grammar
        s = A { $0.v = $0.missing; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .unknownAttribute(target: 0, attribute: "missing", nonterm: "s")
        )
    }

    /// `subscriptOnNonArray`: индексация неиндексируемого типа (text токена)
    @Test func testSubscriptOnNonArray() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : string ;
        %grammar
        s = A { $0.v = $1.text[0]; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .subscriptOnNonArray(target: 1, attribute: "text", nonterm: "s")
        )
    }

    /// `subscriptIndexNotInt`: индекс subscript не int (строковый литерал)
    @Test func testSubscriptIndexNotInt() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.arr : int[] ;
        s.v : int ;
        %grammar
        s = A { $0.v = $0.arr["x"]; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .subscriptIndexNotInt(target: 0, attribute: "arr", nonterm: "s")
        )
    }

    /// `binaryTypeMismatch`: один операнд числовой, другой — нет (int + string)
    @Test func testBinaryTypeMismatch() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        %grammar
        s = A { $0.v = 1 + $1.text; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .binaryTypeMismatch(operator: "+", left: "int", right: "string", nonterm: "s")
        )
    }

    /// `operatorNotApplicable`: оператор неприменим (произведение двух string)
    @Test func testOperatorNotApplicable() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : string ;
        %grammar
        s = A { $0.v = $1.text * $1.text; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .operatorNotApplicable(operator: "*", left: "string", right: "string", nonterm: "s")
        )
    }

    /// `optionalInBinary`: операнд бинарной операции опционален
    @Test func testOptionalInBinary() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        b.v : int ;
        %grammar
        s = [ b ] { $0.v = $1.v + 1; }
        b = A { $0.v = 1; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .optionalInBinary(operator: "+", left: "optional<int>", right: "int", nonterm: "s")
        )
    }

    /// `unknownMethod`: вызов необъявленного метода
    @Test func testUnknownMethod() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        %grammar
        s = A { $0.v = unknownM(); }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .unknownMethod(name: "unknownM", nonterm: "s")
        )
    }

    /// `argumentCountMismatch`: метод вызван с неверным числом аргументов
    @Test func testArgumentCountMismatch() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        %methods
        int m(int);
        %grammar
        s = A { $0.v = m(); }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .argumentCountMismatch(method: "m", expected: 1, given: 0, nonterm: "s")
        )
    }

    /// `argumentTypeMismatch`: фактический тип аргумента несовместим с формальным
    @Test func testArgumentTypeMismatch() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        %methods
        int m(int);
        %grammar
        s = A { $0.v = m($1.text); }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .argumentTypeMismatch(method: "m", index: 0, expected: "int", given: "string", nonterm: "s")
        )
    }

    /// `voidMethodInExpression`: void-метод использован в выражении
    @Test func testVoidMethodInExpression() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        %methods
        void m();
        %grammar
        s = A { $0.v = m(); }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .voidMethodInExpression(method: "m", nonterm: "s")
        )
    }

    /// `illegalAssignment`: присваивание синтезированному атрибуту правой части
    @Test func testIllegalAssignment() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        b.v : int ;
        %grammar
        s = b { $1.v = 1; $0.v = 1 + $1.v; }
        b = A { $0.v = 1; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .illegalAssignment(target: 1, attribute: "v", nonterm: "s")
        )
    }

    /// `assignmentTypeMismatch`: тип значения несовместим с типом цели (int = string)
    @Test func testAssignmentTypeMismatch() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        %grammar
        s = A { $0.v = $1.text; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .assignmentTypeMismatch(target: 0, attribute: "v", expected: "int", given: "string", nonterm: "s")
        )
    }

    /// `float = int` — допустимо
    @Test func testFloatAcceptsInt() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.f : float ;
        s.i : int ;
        %grammar
        s = A { $0.f = 1; $0.i = 1.5; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            excludes: .assignmentTypeMismatch(target: 0, attribute: "f", expected: "float", given: "int", nonterm: "s")
        )
    }

    /// `int = float` — не допустимо
    @Test func testIntRejectsFloat() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.f : float ;
        s.i : int ;
        %grammar
        s = A { $0.f = 1; $0.i = 1.5; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .assignmentTypeMismatch(target: 0, attribute: "i", expected: "int", given: "float", nonterm: "s")
        )
    }

    /// `optional = non-optional` — допустимо
    @Test func testOptionalAcceptsNonOptional() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.opt : int? ;
        s.req : int ;
        b.v   : int ;
        %grammar
        s = [ b ] { $0.opt = 1; $0.req = $1.v; }
        b = A { $0.v = 1; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        /// int? = int
        assert(
            errors,
            excludes: .assignmentTypeMismatch(target: 0, attribute: "opt", expected: "optional<int>", given: "int", nonterm: "s")
        )
    }

    /// `non-optional = optional` — не допустимо
    @Test func testNonOptionalRejectsOptional() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.opt : int? ;
        s.req : int ;
        b.v   : int ;
        %grammar
        s = [ b ] { $0.opt = 1; $0.req = $1.v; }
        b = A { $0.v = 1; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        /// int = int? ($1.v под [ b ] становится optional<int>)
        assert(
            errors,
            contains: .assignmentTypeMismatch(target: 0, attribute: "req", expected: "int", given: "optional<int>", nonterm: "s")
        )
    }

    /// `unknownAttribute` для правой части `$N`: у нетерминала нет такого атрибута
    @Test func testUnknownAttributeRightNonterm() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        b.x : int ;
        %grammar
        s = b { $0.v = $1.missing; }
        b = A { $0.x = 1; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .unknownAttribute(target: 1, attribute: "missing", symbol: "b", nonterm: "s")
        )
    }

    /// `unknownAttribute` у токена: единственный доступный атрибут токена — `text`
    @Test func testUnknownAttributeToken() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : string ;
        %grammar
        s = A { $0.v = $1.foo; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .unknownAttribute(target: 1, attribute: "foo", symbol: "A", nonterm: "s")
        )
    }

    /// `subscriptOnNonArray` через избыток индексов: у `int[]` снимается один уровень,
    /// второй индекс упирается в `int` — неиндексируемый тип
    @Test func testSubscriptTooManyIndices() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.arr : int[] ;
        s.v : int ;
        %grammar
        s = A { $0.v = $0.arr[0][0]; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .subscriptOnNonArray(target: 0, attribute: "arr", nonterm: "s")
        )
    }

    /// `bool` запрещен в любой бинарной операции
    @Test func testBoolInBinary() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : bool ;
        %grammar
        s = A { $0.v = true + false; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .operatorNotApplicable(operator: "+", left: "bool", right: "bool", nonterm: "s")
        )
    }

    /// `optionalInBinary` для правого операнда (симметрично левому)
    @Test func testOptionalInBinaryRight() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        b.v : int ;
        %grammar
        s = [ b ] { $0.v = 1 + $1.v; }
        b = A { $0.v = 1; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .optionalInBinary(operator: "+", left: "int", right: "optional<int>", nonterm: "s")
        )
    }

    /// `argumentTypeMismatch`: метод ждет `int`, передан опционал `int?`
    @Test func testArgumentTypeMismatchOptional() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        b.v : int ;
        %methods
        int m(int);
        %grammar
        s = [ b ] { $0.v = m($1.v); }
        b = A { $0.v = 1; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .argumentTypeMismatch(method: "m", index: 0, expected: "int", given: "optional<int>", nonterm: "s")
        )
    }

    /// `%rep ( )` дает обертку `array`: чтение `$1.v` под повторением — `array<int>`,
    /// присваивание в `int`-цель некорректно
    @Test func testRepeatArrayMismatch() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        b.v : int ;
        %grammar
        s = %rep ( b ) { $0.v = $1.v; }
        b = A { $0.v = 1; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .assignmentTypeMismatch(target: 0, attribute: "v", expected: "int", given: "array<int>", nonterm: "s")
        )
    }

    /// `%rep ( )`: присваивание `array<int>` в цель `int[]` — корректно
    @Test func testRepeatArrayValid() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.arr : int[] ;
        b.v : int ;
        %grammar
        s = %rep ( b ) { $0.arr = $1.v; }
        b = A { $0.v = 1; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            excludes: .assignmentTypeMismatch(target: 0, attribute: "arr", expected: "array<int>", given: "array<int>", nonterm: "s")
        )
    }

    /// `%rep [ ]` дает `optional<array<...>>`: чтение под повторением-с-опционалом
    @Test func testRepeatOptionalArray() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        b.v : int ;
        %grammar
        s = %rep [ b ] { $0.v = $1.v; }
        b = A { $0.v = 1; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .assignmentTypeMismatch(target: 0, attribute: "v", expected: "int", given: "optional<array<int>>", nonterm: "s")
        )
    }

    /// Вложенные группировки `[ %rep ( b ) ]`: внутри `array`, снаружи `optional`
    @Test func testNestedWrappers() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        b.v : int ;
        %grammar
        s = [ %rep ( b ) ] { $0.v = $1.v; }
        b = A { $0.v = 1; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            contains: .assignmentTypeMismatch(target: 0, attribute: "v", expected: "int", given: "optional<array<int>>", nonterm: "s")
        )
    }

    /// Присваивание наследуемому атрибуту левой части `$0` (затенение) — допустимо
    @Test func testInheritedAssignmentToLeftAllowed() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.env : int (inherited) ;
        s.v : int ;
        %grammar
        s = A { $0.env = 1; $0.v = $0.env; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            excludes: .illegalAssignment(target: 0, attribute: "env", nonterm: "s")
        )
    }

    /// Присваивание наследуемому атрибуту правой части `$i` — допустимо
    @Test func testInheritedAssignmentToRightAllowed() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        b.env : int (inherited) ;
        b.v : int ;
        %grammar
        s = b { $1.env = 1; $0.v = $1.v; }
        b = A { $0.v = $0.env; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            excludes: .illegalAssignment(target: 1, attribute: "env", nonterm: "s")
        )
    }

    /// `string + string` — допустимо (единственная разрешенная операция над строками)
    @Test func testStringConcatenationValid() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : string ;
        %grammar
        s = A { $0.v = $1.text + $1.text; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            excludes: .operatorNotApplicable(operator: "+", left: "string", right: "string", nonterm: "s")
        )
    }

    /// `int + float → float`: продвижение типов в бинарной операции, присваивание в float — корректно
    @Test func testNumericPromotionValid() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : float ;
        %grammar
        s = A { $0.v = 1 + 2.0; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        assert(
            errors,
            excludes: .assignmentTypeMismatch(target: 0, attribute: "v", expected: "float", given: "float", nonterm: "s")
        )
    }

    /// Недостижимый нетерминал не обходится: ошибка внутри него не репортится
    @Test func testUnreachableNontermIgnored() {
        let spec = """
        %tokens
        A = "a"
        %grammar
        s = A
        unreachable = A B
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        /// B встречается только в недостижимом правиле — не должно репортиться
        assert(
            errors,
            excludes: .unknownTerm(name: "B")
        )
    }

    /// Рекурсивная грамматика не приводит к зацикливанию обхода
    @Test func testRecursiveGrammarTerminates() {
        let spec = """
        %tokens
        A = "a"
        %grammar
        s = s A | A
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        /// Корректная рекурсивная грамматика — ошибок быть не должно
        #expect(errors.isEmpty, "Рекурсивная грамматика должна проходить без ошибок. Получено: \(errors)")
    }

    /// Содержательная корректная спецификация проходит без ошибок
    @Test func testValidSpecification() {
        let spec = """
        %tokens
        NUMBER = /[0-9]+/
        PLUS = "+"
        STAR = "*"
        %attributes
        expr.val : int ;
        term.val : int ;
        %methods
        int toInt(string);
        int add(int, int);
        int mul(int, int);
        %grammar
        expr = expr PLUS term { $0.val = add($1.val, $3.val); }
             | term { $0.val = $1.val; }
        term = term STAR NUMBER { $0.val = mul($1.val, toInt($3.text)); }
             | NUMBER { $0.val = toInt($1.text); }
        %axiom
        expr
        """
        
        let errors = errors(spec)
        
        #expect(errors.isEmpty, "Корректная спецификация не должна давать ошибок. Получено: \(errors)")
    }

    /// Валидатор накапливает несколько ошибок, а не падает на первой
    @Test func testMultipleErrorsAccumulated() {
        let spec = """
        %tokens
        A = "a"
        %attributes
        s.v : int ;
        %grammar
        s = A B C { $0.v = $1.text; }
        %axiom
        s
        """
        
        let errors = errors(spec)
        
        /// Два неизвестных терминала + несовместимость типов — все должны присутствовать
        assert(errors, contains: .unknownTerm(name: "B"))
        assert(errors, contains: .unknownTerm(name: "C"))
        assert(errors, contains: .assignmentTypeMismatch(target: 0, attribute: "v", expected: "int", given: "string", nonterm: "s"))
    }

    // MARK: - Private Methods

    /// Возвращает семантические ошибки спецификации или ошибку парсинга
    private func errors(_ source: String) -> [Specification.ValidationError] {
        do {
            let spec = try Specification.parse(source)
            return spec.validate()
            
        } catch {
            Issue.record("Ошибка парсинга спецификации: \(error)")
            return []
        }
    }

    /// Проверяет содержание указанной ошибки в переданном массиве ошибок
    private func assert(
        _ errors: [Specification.ValidationError],
        contains error: Specification.ValidationError
    ) {
        #expect(
            errors.contains { $0 == error },
            "Ожидаемая ошибка не найдена. Получено: \(errors)"
        )
    }

    /// Проверяет отсутствие указанной ошибки в переданном массиве ошибок
    private func assert(
        _ errors: [Specification.ValidationError],
        excludes error: Specification.ValidationError
    ) {
        #expect(
            !errors.contains { $0 == error },
            "Найдена ошибка, которой быть не должно. Получено: \(errors)"
        )
    }

}
