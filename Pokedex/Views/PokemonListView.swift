//
//  PokemonListView.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import SwiftUI
import SwiftData

struct PokemonListView: View {

    // @Query ist ein SwiftData-Makro das eine Datenbankabfrage definiert.
    // SwiftUI aktualisiert die View automatisch, sobald sich die Daten ändern (reaktiv).
    // sort: \Pokemon.id → Sortiere nach Pokédex-Nummer aufsteigend.
    // animation: .default → Neue Einträge erscheinen mit einer sanften Animation.
    @Query(sort: \Pokemon.id, animation: .default)
    private var pokemon: [Pokemon]   // Enthält alle Pokémon aus der Datenbank

    var body: some View {
        // NavigationStack ermöglicht Push-Navigation (z. B. Detailansicht öffnen).
        // Alle Views innerhalb können .navigationTitle setzen.
        NavigationStack {
            // List zeigt eine scrollbare Liste von Views an.
            // Identifiable: Pokemon braucht eine eindeutige id-Eigenschaft (hat sie durch @Attribute(.unique)).
            List(pokemon) { mon in
                // Für jedes Pokémon eine Zeile anzeigen
                PokemonRowView(pokemon: mon)
            }
            // .plain entfernt den Standard-iOS-Listenstil (kein Trennstrich, kein Gruppenrahmen)
            .listStyle(.plain)
            .navigationTitle("Pokédex")
            // .overlay legt eine zusätzliche View oben drüber, wenn eine Bedingung zutrifft
            .overlay {
                // Solange noch keine Pokémon geladen sind, Ladehinweis anzeigen
                if pokemon.isEmpty {
                    // ContentUnavailableView ist Apples eingebaute "leer"-Ansicht (ab iOS 17)
                    ContentUnavailableView(
                        "Loading Pokédex...",
                        systemImage: "arrow.down.circle",      // SF Symbol Name
                        description: Text("Fetching all 1025 Pokémon")
                    )
                }
            }
        }
    }
}
