//
//  TreeBuildError.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.05.2026.
//

import Foundation

/// Ошибка свертки дерева
public enum TreeBuildError: Error, Equatable {
    
    /// У леса нет корня — разбор не был принят
    case missingRoot
    
    /// Узел нетерминала без семей — лес поврежден
    case emptyNode(symbol: String, start: Int, end: Int)
    
    /// Служебный нетерминал встретился там, где раскрутка его не ждет
    case unexpectedSupport(name: String)
}

// MARK: - Extensions

extension TreeBuildError: LocalizedError {
    
    // MARK: - Public Properties
    
    /// Описание ошибки свертки дерева
    public var errorDescription: String? {
        switch self {
        case .missingRoot:
            return "Лес разбора пуст: входная цепочка не была принята грамматикой"
            
        case .emptyNode(let symbol, let start, let end):
            return "Узел нетерминала «\(symbol)» во входе с позиции \(start) по \(end) не имеет ни одной семьи — лес поврежден"
            
        case .unexpectedSupport(let name):
            return "Служебный нетерминал «\(name)» встретился там, где раскрутка сахара его не ожидает"
        }
    }
}
