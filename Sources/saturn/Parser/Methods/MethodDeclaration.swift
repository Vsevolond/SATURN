//
//  MethodDeclaration.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

import saturn_core

/// Парсит одно объявление метода:
/// `ReturnType/void name(Type1, Type2, ...);`
struct MethodDeclaration: Parser {
    
    // MARK: - Type Entities
    
    typealias ReturnType = Property.Kind?
    
    // MARK: - Internal Properties
    
    var body: some Parser<Substring, Method> {
        Parse {
            /// Тип возвращаемого значения: `void` или обычный тип
            OneOf {
                "void".map { ReturnType.none }
                AttributeType().map { ReturnType.some($0) }
            }
            
            /// Пробелы между типом и именем
            Skipper(.horizontal)
            
            /// Имя метода
            BaseIdent(form: .mixed)
            
            /// Пробелы перед открывающей скобкой
            Skipper(.horizontal)
            
            /// Открывающая скобка списка параметров
            "("
            
            /// Пробелы внутри скобок перед параметрами
            Skipper()
            
            /// Список типов параметров через запятую, может отсутствовать
            Many {
                AttributeType()
                
            } separator: {
                Skipper(.horizontal)
                ","
                Skipper()
            }
            
            /// Пробелы перед закрывающей скобкой
            Skipper()
            
            /// Закрывающая скобка
            ")"
            
            /// Пробелы перед `;`
            Skipper(.horizontal)
            
            /// Завершающая точка с запятой
            ";"
        }
        .map { returnType, name, parameters in
            Method(name: name, returnType: returnType, arguments: parameters)
        }
    }
}
