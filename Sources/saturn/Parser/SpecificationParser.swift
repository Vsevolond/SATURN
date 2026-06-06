//
//  SpecificationParser.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

extension Specification {
    
    // MARK: - Public Methods
    
    /// Разбирает текст файла спецификации
    public static func parse(_ source: String) throws -> Specification {
        return try SpecificationParser().parse(source)
    }
}

/// Корневой парсер: собирает все секции спецификации в одну структуру
struct SpecificationParser: Parser {
    
    // MARK: - Internal Methods
    
    func parse(_ input: inout Substring) throws -> Specification {
        /// Пробелы и комментарии в начале файла
        try Skipper(comments: true).parse(&input)
        
        /// Обязательная секция токенов
        let tokens = try TokensSection().parse(&input)
        try Skipper(comments: true).parse(&input)
        
        /// Необязательная секция пользовательских типов
        let types: Set<String>
        
        if input.hasPrefix("%types") {
            types = try TypesSection().parse(&input)
            
        } else { types = [] }
        
        try Skipper(comments: true).parse(&input)
        
        /// Необязательная секция атрибутов
        let attributes: [String: [Attribute]]
        
        if input.hasPrefix("%attributes") {
            attributes = try AttributesSection().parse(&input)
            
        } else { attributes = [:] }
        
        try Skipper(comments: true).parse(&input)
        
        /// Необязательная секция методов
        let methods: [String: Method]
        
        if input.hasPrefix("%methods") {
            methods = try MethodsSection().parse(&input)
            
        } else { methods = [:] }
        
        try Skipper(comments: true).parse(&input)
        
        /// Обязательная секция грамматики
        let nonterms = HashMap<String, Nonterm>()
        
        try GrammarSection(nonterms: nonterms).parse(&input)
        try Skipper(comments: true).parse(&input)
        
        /// Обязательная секция аксиомы — имя стартового нетерминала
        let axiom = try AxiomSection().parse(&input)
        try Skipper(comments: true).parse(&input)
        
        /// Окончание файла
        try End().parse(&input)
        
        /// Находим объект нетерминала по имени аксиомы
        guard let axiom = nonterms[axiom] else {
            throw Specification.ParseError.invalidAxiom(name: axiom)
        }
        
        return Specification(
            tokens: tokens,
            types: types,
            attributes: attributes,
            methods: methods,
            axiom: axiom
        )
    }
}
