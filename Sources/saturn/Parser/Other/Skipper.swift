//
//  Skipper.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 19.05.2026.
//

import Parsing

/// Пропускает пробельные символы и, при необходимости, комментарии `# ...` между токенами
struct Skipper: Parser {
    
    // MARK: - Type Entities
    
    typealias Configuration = Whitespace<
        PartialRangeFrom<Int>,
        Conversions.Identity<Substring.UTF8View>
    >.Configuration
    
    // MARK: - Internal Properties
    
    /// Какие пробельные символы пропускать: все, только горизонтальные или только вертикальные
    let configuration: Configuration
    
    /// Учитывать ли комментарии `# ...` до конца строки
    let comments: Bool
    
    // MARK: - Initializers
    
    init(
        _ configuration: Configuration = .all,
        comments: Bool = false
    ) {
        self.configuration = configuration
        self.comments = comments
    }
    
    // MARK: - Body
    
    var body: some Parser<Substring, Void> {
        Skip {
            Many {
                OneOf {
                    /// Пробелы выбранной конфигурации
                    Parse { Whitespace(1..., configuration) }
                    
                    if comments {
                        /// Комментарий от `#` до конца строки, если разрешено
                        Parse {
                            "#"
                            Prefix { $0 != "\n" }
                        }
                        .map { _ in () }
                    }
                }
            }
        }
    }
}
