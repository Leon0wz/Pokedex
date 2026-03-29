//
//  PokemonService.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import Foundation
import SwiftData

// "actor" ist wie eine Klasse (class), aber thread-sicher:
// Nur eine Task kann gleichzeitig auf die Eigenschaften eines Actors zugreifen.
// Das verhindert Datenwettläufe (Race Conditions) in async/concurrent Code.
actor PokemonService {
    // Der API-Client (über Protokoll eingebunden → austauschbar für Tests)
    private let client: PokeAPIClientProtocol
    // Der Datenbankcontainer von SwiftData
    private let modelContainer: ModelContainer

    // private(set): Von außen lesbar, aber nur innerhalb des Actors schreibbar.
    // Andere Teile der App können den Status beobachten, aber nicht direkt setzen.
    private(set) var isFetching = false      // Ist gerade ein Fetch aktiv?
    private(set) var fetchError: Error?      // Letzter aufgetretener Fehler (nil = kein Fehler)
    private(set) var fetchedCount = 0        // Wie viele Pokémon wurden bereits geladen?

    // Klassenkonstante: 20 Pokémon gleichzeitig laden (parallele API-Anfragen pro Batch)
    private static let batchSize = 20

    init(client: PokeAPIClientProtocol, modelContainer: ModelContainer) {
        self.client = client
        self.modelContainer = modelContainer
    }

    // MARK: - Public

    /// Fetches all Pokemon. Idempotent — skips already-fetched records on re-launch.
    /// Lädt alle Pokémon. Idempotent = kann mehrfach aufgerufen werden ohne doppelte Arbeit.
    /// Bereits geladene Pokémon werden beim nächsten App-Start übersprungen.
    func fetchAllIfNeeded() async {
        // Wenn bereits ein Fetch läuft: sofort zurückkehren (kein doppelter Fetch)
        guard !isFetching else { return }
        isFetching = true
        fetchError = nil

        // defer = dieser Block wird IMMER ausgeführt wenn die Funktion endet,
        // egal ob durch return, throw oder normales Ende. Ideal für Aufräumarbeiten.
        defer { isFetching = false }

        do {
            try await fetchListAndDetails()
        } catch {
            // Fehler speichern damit die UI ihn anzeigen kann
            fetchError = error
        }
    }

    // MARK: - Private

    /// Hauptorchestierung: Lädt zuerst die Liste, dann die fehlenden Details.
    private func fetchListAndDetails() async throws {
        // 1. Alle 1025 Pokémon-Namen + URLs von der API laden
        let listResponse = try await client.fetchPokemonList(limit: 1025, offset: 0)

        // Neuen ModelContext erstellen — jeder Kontext sollte auf einem Thread bleiben.
        let context = ModelContext(modelContainer)

        // Welche Pokémon-IDs sind bereits in der Datenbank?
        let existingIDs = try fetchExistingIDs(context: context)

        // compactMap = map + filtert nil-Werte heraus.
        // Hier: Nur Pokémon behalten, die noch NICHT in der DB sind.
        let missing = listResponse.results.compactMap { item -> (id: Int, name: String)? in
            guard let id = item.id, !existingIDs.contains(id) else { return nil }
            return (id, item.name)
        }

        // Fehlende Pokémon als "Platzhalter" in die Datenbank einfügen (nur id + name)
        for item in missing {
            context.insert(Pokemon(id: item.id, name: item.name))
        }
        // Nur speichern wenn es wirklich etwas Neues gibt
        if !missing.isEmpty {
            try context.save()
        }

        // 2. Welche Pokémon haben noch keine Details (Sprites, Typen, Stats)?
        let unfetchedIDs = try fetchUnfetchedIDs(context: context)
        guard !unfetchedIDs.isEmpty else { return }  // Alle Details schon vorhanden → fertig

        // 3. Details in Batches parallel laden
        try await fetchDetailsInBatches(ids: unfetchedIDs, context: context)
    }

    /// Lädt Details in Batches von je `batchSize` Pokémon gleichzeitig.
    /// Parallel loading = mehrere API-Anfragen gleichzeitig statt nacheinander (viel schneller).
    private func fetchDetailsInBatches(ids: [Int], context: ModelContext) async throws {
        // stride(from:to:by:) erzeugt Indizes: 0, 20, 40, 60, ...
        // Daraus entstehen Array-Abschnitte (Batches) der Größe batchSize.
        let batches = stride(from: 0, to: ids.count, by: Self.batchSize).map {
            Array(ids[$0 ..< min($0 + Self.batchSize, ids.count)])
        }

        for batch in batches {
            // withThrowingTaskGroup startet mehrere Tasks gleichzeitig (parallel).
            // Wenn eine Task einen Fehler wirft, bricht die Gruppe ab.
            try await withThrowingTaskGroup(of: PokemonDetailResponse.self) { group in
                for id in batch {
                    // Jede Pokémon-Detail-Anfrage läuft in ihrer eigenen parallelen Task
                    group.addTask { try await self.client.fetchPokemonDetail(id: id) }
                }
                // "for try await" iteriert über die Ergebnisse sobald sie ankommen
                for try await detail in group {
                    applyDetail(detail, context: context)
                    fetchedCount += 1  // Zähler hochzählen (nur innerhalb des Actors erlaubt)
                }
            }
            // Nach jedem Batch in die Datenbank schreiben
            try context.save()
        }
    }

    /// Überträgt die API-Daten eines Pokémon auf das gespeicherte Datenbankmodell.
    private func applyDetail(_ detail: PokemonDetailResponse, context: ModelContext) {
        let id = detail.id
        // FetchDescriptor beschreibt eine Datenbankabfrage.
        // #Predicate ist ein Makro für typsichere Abfragebedingungen (wie SQL WHERE).
        let descriptor = FetchDescriptor<Pokemon>(predicate: #Predicate { $0.id == id })

        // .first gibt das erste Ergebnis zurück — nil wenn kein Pokémon gefunden
        guard let pokemon = try? context.fetch(descriptor).first else { return }

        // Sprite- und Artwork-URLs setzen
        pokemon.spriteURL = detail.sprites.frontDefault
        pokemon.officialArtURL = detail.sprites.other?.officialArtwork?.frontDefault

        // Typen: nach Slot sortieren (Haupttyp zuerst), Namen extrahieren, mit Komma verbinden
        // \.type.name = KeyPath — greift auf die name-Eigenschaft des type-Felds zu
        pokemon.typesRaw = detail.types
            .sorted { $0.slot < $1.slot }
            .map(\.type.name)
            .joined(separator: ",")

        // Stats: API-Daten in interne Structs umwandeln und als JSON codieren
        let statEntries = detail.stats.map {
            Pokemon.StatEntry(name: $0.stat.name, baseStat: $0.baseStat)
        }
        // JSONEncoder kodiert Swift-Objekte zu JSON-Bytes (Data)
        pokemon.statsData = (try? JSONEncoder().encode(statEntries)) ?? Data()

        // Höhe, Gewicht und Fähigkeiten übernehmen
        pokemon.height = detail.height
        pokemon.weight = detail.weight
        pokemon.abilitiesRaw = detail.abilities
            .sorted { $0.slot < $1.slot }
            .map { $0.isHidden ? "\($0.ability.name)(H)" : $0.ability.name }
            .joined(separator: ",")

        pokemon.isDetailFetched = true
    }

    /// Lädt alle bereits in der DB vorhandenen Pokémon-IDs.
    private func fetchExistingIDs(context: ModelContext) throws -> Set<Int> {
        var descriptor = FetchDescriptor<Pokemon>()
        // Nur die id-Eigenschaft laden (nicht alles) → effizienter
        descriptor.propertiesToFetch = [\Pokemon.id]
        // Set<Int> = Menge ohne Duplikate; .contains() ist hier O(1) statt O(n)
        return try Set(context.fetch(descriptor).map(\.id))
    }

    /// Lädt die IDs aller Pokémon, für die noch keine Details abgerufen wurden.
    private func fetchUnfetchedIDs(context: ModelContext) throws -> [Int] {
        let descriptor = FetchDescriptor<Pokemon>(
            predicate: #Predicate { !$0.isDetailFetched },  // Nur die noch unfertigen
            sortBy: [SortDescriptor(\.id)]                  // Nach ID aufsteigend sortiert
        )
        return try context.fetch(descriptor).map(\.id)
    }
}
