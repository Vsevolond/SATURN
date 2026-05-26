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
