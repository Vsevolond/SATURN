//
//  saturn.swift
//  saturn
//
//  Created by Vsevolod Donchenko on 18.03.2026.
//

import Foundation
import ArgumentParser

import saturn_core

@main
struct SaturnCLI: ParsableCommand {
    
    // MARK: - Arguments
    
    @Option(name: .shortAndLong) var path: String
    
    // MARK: - Main
    
    mutating func run() throws {
        let directory = URL(fileURLWithPath: path, isDirectory: true)
        
        let configurationURL = directory.appendingPathComponent("configuration.spec")
        let semanticsURL = directory.appendingPathComponent("semantics.js")
        let inputURL = directory.appendingPathComponent("input.txt")
        let treeOutputURL = directory.appendingPathComponent("tree.json")
        let graphOutputURL = directory.appendingPathComponent("graph.dot")
        
        /// Проверка наличия спецификации
        guard FileManager.default.fileExists(atPath: configurationURL.path) else {
            throw CleanExit.message(
                "Файл configuration.spec не найден в \(directory.path)"
            )
        }
        
        let specificationSource = try String(contentsOf: configurationURL, encoding: .utf8)
        
        /// Парсинг спецификации в структуру Specification
        let specification: Specification
        
        do {
            specification = try Specification.parse(specificationSource)
            
        } catch {
            throw CleanExit.message(
                "Ошибка разбора спецификации:\n \(error)"
            )
        }
        
        /// Валидация спецификации — собираем все семантические ошибки и выводим разом
        let semanticErrors = specification.validate()
        
        if !semanticErrors.isEmpty {
            print("Найдены ошибки спецификации:")
            
            for error in semanticErrors {
                print("  • \(error.description)")
            }
            
            throw CleanExit.message(
                "Трансляция прервана из-за ошибок спецификации"
            )
        }
        
        /// Проверка входного текста
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw CleanExit.message(
                "Файл input.txt не найден в \(directory.path)"
            )
        }
        
        let inputText = try String(contentsOf: inputURL, encoding: .utf8)
        
        /// Файл семантики опционален
        let semanticsScript: String
        
        if FileManager.default.fileExists(atPath: semanticsURL.path) {
            semanticsScript = try String(contentsOf: semanticsURL, encoding: .utf8)
            
        } else {
            semanticsScript = ""
            print("Файл semantics.js не найден — используется пустая среда выполнения")
        }
        
        /// Лексический анализ
        let lexemes: [Lexeme]
        
        do {
            let lexer = Scanner(tokens: specification.tokens)
            lexemes = try lexer.scan(inputText)
            
        } catch {
            throw CleanExit.message(
                "Ошибка лексического анализа:\n \(error.description)"
            )
        }
        
        /// Разворачивание сахара
        let (expanded, expansionMap) = SugarExpander().expand(axiom: specification.axiom)
        
        /// Устранение ε-правил
        let epsilonFree: EpsilonFreeGrammar
        
        do {
            epsilonFree = try EpsilonEliminator().eliminate(expanded, map: expansionMap)
            
        } catch {
            throw CleanExit.message(
                "Ошибка устранения ε-правил:\n \(error.localizedDescription)"
            )
        }
        
        /// Таблица разбора
        let parseTable: ParseTable
        
        do {
            parseTable = try ParseTable(epsilonFree.value, acceptsEmpty: epsilonFree.acceptsEmpty)
            
        } catch {
            throw CleanExit.message(
                "Ошибка построения таблицы разбора:\n \(error.localizedDescription)"
            )
        }
        
        /// Синтаксический разбор
        let forest: SPPForest
        
        do {
            let parser = try GLRParser(table: parseTable, lexemes: lexemes)
            forest = try parser.parse()
            
        } catch {
            throw CleanExit.message(
                "Ошибка синтаксического анализа:\n \(error.description)"
            )
        }
        
        /// Свертка леса в дерево разбора с восстановлением сахара
        let tree: ParseTree
        
        do {
            let builder = TreeBuilder(map: expansionMap, productions: parseTable.productions)
            tree = try builder.build(from: forest)
            
        } catch {
            throw CleanExit.message(
                "Ошибка свертки дерева разбора:\n \(error.localizedDescription)"
            )
        }
        
        /// Индекс имен для согласованной нумерации в графе зависимостей
        let nodeIndex = NodeIndex(root: tree)
        
        /// Среда выполнения пользовательской логики из semantics.js
        let runtime: SemanticRuntime
        
        do {
            runtime = try SemanticRuntime(script: semanticsScript)
            
        } catch {
            throw CleanExit.message(
                "Ошибка загрузки semantics.js:\n \(error.localizedDescription)"
            )
        }
        
        /// Вычислитель атрибутов с попутным построением графа зависимостей
        let evaluator = Evaluator(
            specification: specification,
            productions: parseTable.productions,
            runtime: runtime,
            nodeIndex: nodeIndex
        )
        
        /// Вычисление: атрибуты всех узлов и граф зависимостей
        let result: EvaluateResult
        
        do {
            result = try evaluator.evaluateAll(tree)
            
        } catch {
            throw CleanExit.message(
                "Ошибка вычисления атрибутов:\n \(error.localizedDescription)"
            )
        }
        
        /// Сериализация дерева с атрибутами в JSON
        do {
            let data = try result.treeJSON(tree: tree, context: runtime.context)
            try data.write(to: treeOutputURL)
            
        } catch {
            throw CleanExit.message(
                "Ошибка записи tree.json: \(error.localizedDescription)"
            )
        }
        
        /// Сериализация графа зависимостей в формат DOT
        let dot = result.dependenciesDOT()
        
        do {
            try dot.write(to: graphOutputURL, atomically: true, encoding: .utf8)
            
        } catch {
            throw CleanExit.message(
                "Ошибка записи graph.dot: \(error)"
            )
        }
        
        /// Атрибуты аксиомы
        if !result.rootAttributes.isEmpty {
            print("Атрибуты аксиомы:\n")
            
            for (name, value) in result.rootAttributes {
                print("\(name) = \(value)")
            }
        }
    }
}
