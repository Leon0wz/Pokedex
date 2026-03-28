//
//  Pokemon.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import SwiftData
import Foundation

@Model
final class Pokemon {
    @Attribute(.unique) var id: Int
    var name: String
    var spriteURL: String?
    var officialArtURL: String?
    /// Comma-separated type names, e.g. "fire,flying"
    var typesRaw: String
    /// JSON-encoded [StatEntry]
    var statsData: Data
    var isDetailFetched: Bool

    init(id: Int, name: String) {
        self.id = id
        self.name = name
        self.typesRaw = ""
        self.statsData = Data()
        self.isDetailFetched = false
    }

    var types: [String] {
        typesRaw.isEmpty ? [] : typesRaw.split(separator: ",").map(String.init)
    }

    struct StatEntry: Codable {
        var name: String
        var baseStat: Int
    }

    var stats: [StatEntry] {
        (try? JSONDecoder().decode([StatEntry].self, from: statsData)) ?? []
    }
}
