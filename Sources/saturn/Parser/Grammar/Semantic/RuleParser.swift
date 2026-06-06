//
//  RuleParser.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing
import Foundation

import saturn_core

/// Парсит правило грамматики: `Nonterminal = Alt1 | Alt2 | ... ;`
struct RuleParser: Parser {
    
    // MARK: - Internal Properties
    
    /// Нетерминалы грамматики по именам
    let nonterms: HashMap<String, Nonterm>
    
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, Void> {
        Parse {
            /// Имя нетерминала левой части
            NontermIdent()
            
            /// Пробелы перед `=`
            Skipper(.horizontal)
            
            /// Разделитель левой и правой части
            "="
            
            /// Пробелы после `=`
            Skipper(.horizontal)
            
            /// Альтернативы через `|`
            Many(1...) {
                AlternativeParser(nonterms: nonterms)
                
            } separator: {
                Skipper(comments: true)
                "|"
                Skipper(.horizontal)
            }
        }
        .map { name, alternatives in
            /// Если нетерминал уже есть — добавляем к нему альтернативы
            if let nonterm = nonterms[name] {
                nonterm.add(alternatives)
            
            /// Иначе — создаем новый нетерминал с альтернативами
            } else {
                let nonterm = Nonterm(name: name)
                nonterm.add(alternatives)
                
                nonterms[name] = nonterm
            }
        }
    }
}
