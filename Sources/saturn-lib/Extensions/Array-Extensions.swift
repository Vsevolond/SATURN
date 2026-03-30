//
//  Array-Extensions.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.03.2026.
//

extension Array {
    
    // MARK: - Internal Methods
    
    /// Returns an array with an element added to the end
    func appending(_ element: Element) -> Self {
        var result = self
        result.append(element)
        
        return result
    }
}
