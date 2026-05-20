//
//  HashMap.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 20.05.2026.
//

/// Вспомогательный класс, обертка над словарем
final class HashMap<Key: Hashable, Value> {
    
    // MARK: - Private Properties
    
    private var storage: [Key: Value] = [:]
    
    // MARK: - Internal Properties
    
    var wrapped: [Key: Value] { storage }
    
    // MARK: - Subscripts
    
    subscript(key: Key) -> Value? {
        get { storage[key] }
        set { storage[key] = newValue }
    }
}
