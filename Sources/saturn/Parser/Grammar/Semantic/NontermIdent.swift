//
//  NontermIdent.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

/// Идентификатор нетерминала: `[A-Za-z][A-Za-z0-9_]*` с обязательной строчной буквой
struct NontermIdent: Parser {
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, String> {
        BaseIdent(form: .mixedWithLowercase)
    }
}
