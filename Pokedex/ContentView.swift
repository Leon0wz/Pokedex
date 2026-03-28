//
//  ContentView.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import SwiftUI   // Für Views und State-Management
import SwiftData // Für den Datenbankzugriff über ModelContext

struct ContentView: View {

    // @Environment liest einen Wert aus der SwiftUI-Umgebung.
    // \.modelContext ist der Kontext zum Lesen/Schreiben in die SwiftData-Datenbank.
    @Environment(\.modelContext) private var modelContext

    // @State speichert den PokemonService als optionalen Wert.
    // Optional (?) bedeutet: kann nil sein (also "kein Wert").
    // Er wird erst beim ersten Erscheinen der View erzeugt.
    @State private var service: PokemonService?

    var body: some View {
        // PokemonListView zeigt die Liste aller Pokémon an.
        PokemonListView()
            // .task startet eine asynchrone Aufgabe wenn die View erscheint.
            // async/await = moderne Swift-Syntax für asynchronen Code (kein Callback-Chaos).
            .task {
                // guard...else = frühzeitiger Ausstieg falls Bedingung nicht erfüllt.
                // Hier: Service nur einmal erstellen, nicht bei jedem Neuzeichnen.
                guard service == nil else { return }

                // PokemonService benötigt einen API-Client und den Datenbankcontainer.
                service = PokemonService(
                    client: PokeAPIClient(),
                    modelContainer: modelContext.container
                )

                // await = "Warte hier, bis die asynchrone Funktion fertig ist."
                // ? = Optional Chaining: nur aufrufen, wenn service nicht nil ist.
                await service?.fetchAllIfNeeded()
            }
    }
}

// #Preview zeigt eine Vorschau im Xcode-Canvas (rechte Seite in Xcode).
// inMemory: true = Datenbank nur im Arbeitsspeicher, nichts wird gespeichert.
#Preview {
    ContentView()
        .modelContainer(for: Pokemon.self, inMemory: true)
}
