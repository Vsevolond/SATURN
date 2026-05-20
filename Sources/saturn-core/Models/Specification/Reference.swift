//
//  Reference.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 30.03.2026.
//

/// Ссылка на атрибут символа внутри семантического действия
public struct Reference: Equatable {
    
    // MARK: - Public Properties
    
    /// Позиция символа в правиле (`$0`, `$1`, ...)
    public let target: Int
    
    /// Имя атрибута, на который ссылаются
    public let attribute: String
    
    /// Цепочка индексов для атрибута-массива: `.<attribute>[i][j]...`
    /// Пустая для атрибутов, не являющихся массивами
    public let subscripts: [Expression]
    
    // MARK: - Initializers
    
    public init(
        target: Int,
        attribute: String,
        subscripts: [Expression] = []
    ) {
        self.target = target
        self.attribute = attribute
        self.subscripts = subscripts
    }
}
