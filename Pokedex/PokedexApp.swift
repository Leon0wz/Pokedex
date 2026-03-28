//
//  PokedexApp.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import SwiftUI   // SwiftUI ist Apples Framework zum Bauen von Benutzeroberflächen
import SwiftData // SwiftData ist Apples Framework zur lokalen Datenspeicherung

// @main markiert diese Struktur als den Einstiegspunkt der App.
// Jede SwiftUI-App braucht genau ein @main.
@main
struct PokedexApp: App {

    // @State speichert einen Wert, der sich ändern kann.
    // Ändert sich splashFinished, zeichnet SwiftUI betroffene Views neu.
    @State private var splashFinished = false

    // ModelContainer ist die "Datenbank" der App (SwiftData).
    // Er wird einmalig beim Start erstellt und dann weitergereicht.
    private let modelContainer: ModelContainer = Self.makeModelContainer()

    // Diese statische Hilfsfunktion erstellt den ModelContainer.
    // "static" bedeutet: Sie gehört zum Typ, nicht zu einer Instanz.
    private static func makeModelContainer() -> ModelContainer {
        // Schema beschreibt, welche Datenmodelle gespeichert werden sollen.
        let schema = Schema([Pokemon.self])

        // ModelConfiguration legt fest, wie und wo gespeichert wird.
        // isStoredInMemoryOnly: false → Daten bleiben nach App-Neustart erhalten.
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            // Normalfall: Container erfolgreich erstellen
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema changed — delete stale store so data is re-fetched from the API
            // Hat sich das Datenmodell geändert, schlägt die Erstellung fehl.
            // Dann löschen wir die alten Datenbankdateien, damit alles neu geladen wird.
            let base = config.url.deletingLastPathComponent()
            for name in ["default.store", "default.store-shm", "default.store-wal"] {
                try? FileManager.default.removeItem(at: base.appendingPathComponent(name))
            }
            // try! = "Ich bin sicher, dass das klappt." Nur nach dem Löschen sicher nutzbar.
            return try! ModelContainer(for: schema, configurations: [config])
        }
    }

    // body definiert was die App anzeigt. "some Scene" ist ein opaker Rückgabetyp –
    // SwiftUI kennt den genauen Typ, aber wir müssen ihn nicht explizit nennen.
    var body: some Scene {
        // WindowGroup ist der Container für das Hauptfenster der App.
        WindowGroup {
            // ZStack legt Views übereinander (Z-Achse = Tiefe).
            // Zuerst kommt ContentView, dann darüber ggf. der SplashScreen.
            ZStack {
                // ContentView ist die eigentliche Haupt-Ansicht der App.
                // .modelContainer(...) stellt die Datenbank allen Kind-Views bereit.
                // .opacity(...) steuert die Sichtbarkeit: 1 = sichtbar, 0 = unsichtbar.
                ContentView()
                    .modelContainer(modelContainer)
                    .opacity(splashFinished ? 1 : 0)  // Ternärer Ausdruck: wenn fertig → sichtbar

                // Solange der Splash noch läuft, zeigen wir SplashView darüber.
                // $splashFinished ist eine Binding: SplashView kann den Wert ändern.
                if !splashFinished {
                    SplashView(isFinished: $splashFinished)
                        .transition(.opacity)  // Beim Verschwinden wird die View weich ausgeblendet
                }
            }
            // .animation reagiert auf Änderungen von splashFinished und animiert sanft.
            .animation(.easeOut(duration: 0.4), value: splashFinished)
        }
    }
}
