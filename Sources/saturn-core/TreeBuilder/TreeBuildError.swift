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
