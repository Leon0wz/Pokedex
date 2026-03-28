//
//  PokemonListView.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import SwiftUI
import SwiftData

struct PokemonListView: View {
    @Query(sort: \Pokemon.id, animation: .default)
    private var pokemon: [Pokemon]

    var body: some View {
        NavigationStack {
            List(pokemon) { mon in
                PokemonRowView(pokemon: mon)
            }
            .listStyle(.plain)
            .navigationTitle("Pokédex")
            .overlay {
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
