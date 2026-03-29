//
//  PokemonListView.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import SwiftUI
import SwiftData

struct PokemonListView: View {

    // @Query lädt alle Pokémon aus der Datenbank, sortiert nach Pokédex-Nummer.
    // Das Filtering erfolgt danach in-memory (1025 Einträge = vernachlässigbare Performance).
    @Query(sort: \Pokemon.id, animation: .default)
    private var pokemon: [Pokemon]

    // Suchtext aus der .searchable-Leiste
    @State private var searchText = ""

    // Ausgewählte Generationen; leeres Set = alle Generationen werden angezeigt
    @State private var selectedGenerations: Set<Int> = []

    // Pokémon-Namen der 9 Generationen für die Section-Header
    private let generationNames: [Int: String] = [
        1: "Generation I",
        2: "Generation II",
        3: "Generation III",
        4: "Generation IV",
        5: "Generation V",
        6: "Generation VI",
        7: "Generation VII",
        8: "Generation VIII",
        9: "Generation IX"
    ]

    /// Filtert die Pokémon-Liste nach aktiver Generationsauswahl und Suchtext.
    private var filteredPokemon: [Pokemon] {
        pokemon
            // Generationsfilter: leeres Set = alle durchlassen
            .filter { selectedGenerations.isEmpty || selectedGenerations.contains($0.generation) }
            // Namenssuche: case-insensitiv, Teilstring-Suche
            .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    /// Gruppiert die gefilterten Pokémon nach Generation und sortiert die Gruppen aufsteigend.
    private var groupedPokemon: [(generation: Int, pokemon: [Pokemon])] {
        let grouped = Dictionary(grouping: filteredPokemon, by: \.generation)
        return grouped.keys.sorted().map { (generation: $0, pokemon: grouped[$0]!) }
    }

    var body: some View {
        NavigationStack {
            List {
                // Liquid-Glass-Filterleiste ganz oben, ohne Listenstil-Rahmen
                GenerationFilterView(selectedGenerations: $selectedGenerations)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                // Pokémon in Sections, eine pro Generation
                ForEach(groupedPokemon, id: \.generation) { group in
                    Section(generationNames[group.generation] ?? "Generation \(group.generation)") {
                        ForEach(group.pokemon) { mon in
                            NavigationLink(value: mon) {
                                PokemonRowView(pokemon: mon)
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: Pokemon.self) { mon in
                PokemonDetailView(pokemon: mon)
            }
            .listStyle(.plain)
            // displayMode: .always → Suchleiste immer sichtbar, kein Einblend-Lag beim Tippen
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Pokémon suchen…"
            )
            .navigationTitle("Pokédex")
            .overlay {
                // Ladehinweis solange die Datenbank noch leer ist
                if pokemon.isEmpty {
                    ContentUnavailableView(
                        "Loading Pokédex...",
                        systemImage: "arrow.down.circle",
                        description: Text("Fetching all 1025 Pokémon")
                    )
                }
            }
        }
    }
}
