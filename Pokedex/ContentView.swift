//
//  ContentView.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var service: PokemonService?

    var body: some View {
        PokemonListView()
            .task {
                guard service == nil else { return }
                service = PokemonService(
                    client: PokeAPIClient(),
                    modelContainer: modelContext.container
                )
                await service?.fetchAllIfNeeded()
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Pokemon.self, inMemory: true)
}
