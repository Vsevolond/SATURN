//
//  Optional-Extensions.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 25.05.2026.
//

import Foundation

extension Optional where Wrapped: Collection {
    
    // MARK: - Internal Properties
    
    var count: Int? {
        guard case .some(let wrapped) = self else {
            return nil
        }
        
        return wrapped.count
    }
}

extension Optional where Wrapped: SetAlgebra {
    
    // MARK: - Internal Methods
    
    mutating func formUnion(_ other: Wrapped) {
        guard var wrapped = self else { return }
        
        wrapped.formUnion(other)
        self = .some(wrapped)
    }
}
