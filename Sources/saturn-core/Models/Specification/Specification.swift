//
//  Specification.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.03.2026.
//

/// Полная спецификация грамматики, разобранная из файла `.spec`
public struct Specification {
    
    // MARK: - Public Properties
    
    /// Все токены секции `%tokens` по имени токена
    public var tokens: [String : Token]
    
    /// Имена пользовательских типов из секции `%types`
    public var types: Set<String>
    
    /// Атрибуты секции `%attributes`, сгруппированные по имени символа
    public var attributes: [String : [Attribute]]
    
    /// Все методы секции `%methods` по имени метода
    public var methods: [String : Method]
    
    /// Аксиома — начальный нетерминал грамматики
    public var axiom: Nonterm
    
    // MARK: - Initializers
    
    public init(
        tokens: [String : Token] = [:],
        types: Set<String> = [],
        attributes: [String : [Attribute]] = [:],
        methods: [String : Method] = [:],
        axiom: Nonterm
    ) {
        self.tokens = tokens
        self.types = types
        self.attributes = attributes
        self.methods = methods
        self.axiom = axiom
    }
}
