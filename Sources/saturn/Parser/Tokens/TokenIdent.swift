//
//  TokenIdent.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

/// Идентификатор токена: `[A-Z][A-Z0-9_]*`
struct TokenIdent: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, String> {
        BaseIdent(form: .uppercase)
    }
}
