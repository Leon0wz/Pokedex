//
//  PokedexApp.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import SwiftUI
import SwiftData

@main
struct PokedexApp: App {
    @State private var splashFinished = false

    private let modelContainer: ModelContainer = Self.makeModelContainer()

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([Pokemon.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema changed — delete stale store so data is re-fetched from the API
            let base = config.url.deletingLastPathComponent()
            for name in ["default.store", "default.store-shm", "default.store-wal"] {
                try? FileManager.default.removeItem(at: base.appendingPathComponent(name))
            }
            return try! ModelContainer(for: schema, configurations: [config])
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .modelContainer(modelContainer)
                    .opacity(splashFinished ? 1 : 0)

                if !splashFinished {
                    SplashView(isFinished: $splashFinished)
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.4), value: splashFinished)
        }
    }
}
