//
//  Method.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.03.2026.
//

/// Объявление метода, доступного для вызова из семантических действий
public struct Method {
    
    // MARK: - Public Properties
    
    /// Имя метода в том виде, как он записывается в семантических действиях
    public let name: String
    
    /// Тип возвращаемого значения, `nil` соответствует `void`
    public let returnType: Property.Kind?
    
    /// Упорядоченный список типов параметров
    public let arguments: [Property.Kind]
    
    // MARK: - Initializers
    
    public init(
        name: String,
        returnType: Property.Kind? = nil,
        arguments: [Property.Kind] = []
    ) {
        self.name = name
        self.returnType = returnType
        self.arguments = arguments
    }
}
