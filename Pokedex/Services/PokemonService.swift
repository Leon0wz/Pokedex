//
//  PokemonService.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import Foundation
import SwiftData

actor PokemonService {
    private let client: PokeAPIClientProtocol
    private let modelContainer: ModelContainer

    private(set) var isFetching = false
    private(set) var fetchError: Error?
    private(set) var fetchedCount = 0

    private static let batchSize = 20

    init(client: PokeAPIClientProtocol, modelContainer: ModelContainer) {
        self.client = client
        self.modelContainer = modelContainer
    }

    // MARK: - Public

    /// Fetches all Pokemon. Idempotent — skips already-fetched records on re-launch.
    func fetchAllIfNeeded() async {
        guard !isFetching else { return }
        isFetching = true
        fetchError = nil
        defer { isFetching = false }

        do {
            try await fetchListAndDetails()
        } catch {
            fetchError = error
        }
    }

    // MARK: - Private

    private func fetchListAndDetails() async throws {
        let listResponse = try await client.fetchPokemonList(limit: 1025, offset: 0)

        let context = ModelContext(modelContainer)
        let existingIDs = try fetchExistingIDs(context: context)

        let missing = listResponse.results.compactMap { item -> (id: Int, name: String)? in
            guard let id = item.id, !existingIDs.contains(id) else { return nil }
            return (id, item.name)
        }

        for item in missing {
            context.insert(Pokemon(id: item.id, name: item.name))
        }
        if !missing.isEmpty {
            try context.save()
        }

        let unfetchedIDs = try fetchUnfetchedIDs(context: context)
        guard !unfetchedIDs.isEmpty else { return }

        try await fetchDetailsInBatches(ids: unfetchedIDs, context: context)
    }

    private func fetchDetailsInBatches(ids: [Int], context: ModelContext) async throws {
        let batches = stride(from: 0, to: ids.count, by: Self.batchSize).map {
            Array(ids[$0 ..< min($0 + Self.batchSize, ids.count)])
        }

        for batch in batches {
            try await withThrowingTaskGroup(of: PokemonDetailResponse.self) { group in
                for id in batch {
                    group.addTask { try await self.client.fetchPokemonDetail(id: id) }
                }
                for try await detail in group {
                    applyDetail(detail, context: context)
                    fetchedCount += 1
                }
            }
            try context.save()
        }
    }

    private func applyDetail(_ detail: PokemonDetailResponse, context: ModelContext) {
        let id = detail.id
        let descriptor = FetchDescriptor<Pokemon>(predicate: #Predicate { $0.id == id })
        guard let pokemon = try? context.fetch(descriptor).first else { return }

        pokemon.spriteURL = detail.sprites.frontDefault
        pokemon.officialArtURL = detail.sprites.other?.officialArtwork?.frontDefault
        pokemon.typesRaw = detail.types
            .sorted { $0.slot < $1.slot }
            .map(\.type.name)
            .joined(separator: ",")

        let statEntries = detail.stats.map {
            Pokemon.StatEntry(name: $0.stat.name, baseStat: $0.baseStat)
        }
        pokemon.statsData = (try? JSONEncoder().encode(statEntries)) ?? Data()
        pokemon.isDetailFetched = true
    }

    private func fetchExistingIDs(context: ModelContext) throws -> Set<Int> {
        var descriptor = FetchDescriptor<Pokemon>()
        descriptor.propertiesToFetch = [\Pokemon.id]
        return try Set(context.fetch(descriptor).map(\.id))
    }

    private func fetchUnfetchedIDs(context: ModelContext) throws -> [Int] {
        let descriptor = FetchDescriptor<Pokemon>(
            predicate: #Predicate { !$0.isDetailFetched },
            sortBy: [SortDescriptor(\.id)]
        )
        return try context.fetch(descriptor).map(\.id)
    }
}
