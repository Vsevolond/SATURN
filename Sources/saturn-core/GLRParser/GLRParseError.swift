//
//  GLRParseError.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 26.05.2026.
//

import Foundation
 
/// Ошибка синтаксического анализа GLR
public enum GLRParseError: Error, Equatable {
    
    /// Ни одна ветвь не приняла вход: на лексеме нет применимого действия
    ///
    /// - `lexeme` — лексема, на которой все ветви заглохли, `nil`, если разбор оборвался на конце входа
    /// - `expected` — терминалы, которые ожидались хотя бы одной живой ветвью
    case unexpectedInput(lexeme: Lexeme?, expected: [String])
    
    /// Вход пуст, но язык не допускает пустую цепочку
    case unexpectedEmptyInput
    
    /// Аксиома не найдена в таблице управления
    case axiomNotFound
}

// MARK: - Extensions

extension GLRParseError: CustomStringConvertible {
    
    // MARK: - Public Properties
    
    /// Описание ошибки синтаксического анализа
    public var description: String {
        switch self {
        case .unexpectedInput(let lexeme, let expected):
            let location = lexeme.map {
                "лексема «\($0.name)» («\($0.text)») в строке \($0.position.line), позиция \($0.position.column)"
            } ?? "конец входа"
            
            /// Ожидаемых терминалов может не быть совсем
            guard !expected.isEmpty else {
                return "Неожиданный вход: \(location)"
            }
            
            let list = expected.map { "«\($0)»" }.joined(separator: ", ")
            return "Неожиданный вход: \(location). Ожидалось одно из: \(list)"
            
        case .unexpectedEmptyInput:
            return "Вход пуст, но грамматика не допускает пустую цепочку"
            
        case .axiomNotFound:
            return "Аксиома не найдена в таблице управления"
        }
    }
}
