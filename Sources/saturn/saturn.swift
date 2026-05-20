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
    
    mutating func run() throws {
        let url = URL(fileURLWithPath: path, isDirectory: true)
        
        let configUrl = url.appendingPathComponent("configuration.spec")
        
        guard FileManager.default.fileExists(atPath: configUrl.path) else {
            throw CleanExit.message("Configuration file not exists")
        }
        
        let semanticsUrl = url.appendingPathComponent("semantics.js")
        
        if FileManager.default.fileExists(atPath: semanticsUrl.path) {
            print("semantics exist")
            
        } else {
            print("semantics not exist")
        }
        
        let string = try String(contentsOf: configUrl, encoding: .utf8)
        let spec = try Specification.parse(string)
        
        dump(spec)
    }
}
