//
//  ElementParser.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing
import Foundation

import saturn_core

/// Парсит один элемент правой части альтернативы:
/// терминал, нетерминал, `%rep(...)`, `%rep[...]` или `[...]`
struct ElementParser: Parser {
    
    // MARK: - Internal Properties
    
    /// Нетерминалы грамматики по именам
    let nonterms: HashMap<String, Nonterm>
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, Production> {
        Lazy {
            OneOf {
                /// `%rep` — один/ноль или более повторов
                Parse {
                    "%rep"
                    Skipper(.horizontal)
                    
                    OneOf {
                        /// `%rep(...)` — один или более повторов
                        Parse {
                            "("
                            Skipper()
                            
                            ElementListParser(nonterms: nonterms)
                            
                            Skipper()
                            ")"
                        }
                        .map { Production.repeat(productions: $0, optional: false) }
                        
                        /// `%rep[...]` — ноль или более повторов
                        Parse {
                            "["
                            Skipper()
                            
                            ElementListParser(nonterms: nonterms)
                            
                            Skipper()
                            "]"
                        }
                        .map { Production.repeat(productions: $0, optional: true) }
                    }
                }
                
                /// `[...]` — опциональная группа, ноль или один раз
                Parse {
                    "["
                    Skipper()
                    
                    ElementListParser(nonterms: nonterms)
                    
                    Skipper()
                    "]"
                }
                .map { Production.optional(productions: $0) }
                
                /// Имя нетерминала
                NontermIdent().map {
                    /// Если объект нетерминала уже есть
                    if let nonterm = nonterms[$0] {
                        return Production.nonterm(nonterm)
                    
                    /// Иначе — создаем новый нетерминал
                    } else {
                        let nonterm = Nonterm(name: $0)
                        nonterms[$0] = nonterm
                        
                        return Production.nonterm(nonterm)
                    }
                }
                
                /// Имя токена
                TokenIdent().map { Production.term($0) }
            }
        }
    }
}
