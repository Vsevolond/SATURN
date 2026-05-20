//
//  TypeIdent.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

/// Идентификатор имени типа: `[A-Za-z][A-Za-z0-9_]*`
struct TypeIdent: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, String> {
        BaseIdent(form: .mixed)
    }
}
