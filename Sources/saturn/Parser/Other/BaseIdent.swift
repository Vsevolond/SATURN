//
//  BaseIdent.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

/// Базовый парсер идентификаторов с настраиваемой формой
struct BaseIdent: Parser {
    
    // MARK: - Type Entities
    
    enum Form {
        
        // MARK: - Cases
        
        /// Только заглавные буквы: `[A-Z][A-Z0-9_]*`
        case uppercase
        
        /// Любой регистр: `[A-Za-z][A-Za-z0-9_]*`
        case mixed
        
        /// Любой регистр с обязательной хотя бы одной строчной буквой
        case mixedWithLowercase
    }
    
    // MARK: - Internal Properties
    
    /// Форма идентификатора, задающая допустимые символы и требования
    let form: Form
    
    var body: some Parser<Substring, String> {
        Parse {
            /// Первый символ — обязательная латинская буква разрешенного регистра
            Prefix(1) { character in
                guard character.isASCII, character.isLetter else { return false }
                return form == .uppercase ? character.isUppercase : true
            }
            
            /// Хвост — латинские буквы разрешенного регистра, цифры и подчеркивания
            Prefix { character in
                guard character.isASCII else { return false }
                if character.isNumber || character == "_" { return true }
                
                guard character.isLetter else { return false }
                return form == .uppercase ? character.isUppercase : true
            }
        }
        .map { head, tail in String(head) + String(tail) }
        .filter { name in
            /// При форме с обязательной строчной — проверяем ее наличие
            form == .mixedWithLowercase ? name.contains { $0.isLowercase } : true
        }
    }
    
    // MARK: - Internal Methods
    
    /// Обертка над `body`, при неуспехе предиката откатывает вход
    func parse(_ input: inout Substring) throws -> String {
        let start = input
        
        do {
            return try body.parse(&input)
            
        } catch {
            input = start
            throw error
        }
    }
}
