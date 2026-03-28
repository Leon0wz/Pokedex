//
//  PokemonRowView.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import SwiftUI

/// Zeigt eine einzelne Zeile in der Pokémon-Liste an.
/// Enthält: Sprite-Bild | Name + Typ-Badges | Pokédex-Nummer
struct PokemonRowView: View {
    let pokemon: Pokemon   // Das anzuzeigende Pokémon (von außen übergeben)

    var body: some View {
        // HStack = Horizontal Stack: ordnet Views nebeneinander an.
        // spacing: 12 = 12 Punkte Abstand zwischen den Kindelementen.
        HStack(spacing: 12) {

            // AsyncImage lädt ein Bild asynchron von einer URL.
            // Asynchron = der Rest der App friert nicht ein während das Bild lädt.
            AsyncImage(url: URL(string: pokemon.spriteURL ?? "")) { phase in
                // phase = aktueller Ladezustand
                switch phase {
                case .success(let image):
                    // Bild erfolgreich geladen: anzeigen und auf den Frame skalieren
                    image.resizable().scaledToFit()
                case .failure, .empty:
                    // Fehler oder noch kein Bild: Platzhalter-Icon anzeigen
                    Image(systemName: "circle.dotted")  // SF Symbol (eingebautes Apple-Icon)
                        .foregroundStyle(.secondary)     // Grau eingefärbt
                @unknown default:
                    // Zukunftssicher: unbekannte Zustände ignorieren
                    EmptyView()
                }
            }
            .frame(width: 56, height: 56)   // Feste Bildgröße in Punkten

            // VStack = Vertical Stack: ordnet Views untereinander an.
            VStack(alignment: .leading, spacing: 4) {
                // .capitalized macht den ersten Buchstaben groß (z. B. "bulbasaur" → "Bulbasaur")
                Text(pokemon.name.capitalized)
                    .font(.body.weight(.semibold))   // Halbfett

                // Typ-Badges nebeneinander anzeigen
                HStack(spacing: 4) {
                    // ForEach iteriert über die Typen-Liste und erstellt für jeden einen Badge.
                    // id: \.self = jeder String dient als eindeutige ID
                    ForEach(pokemon.types, id: \.self) { typeName in
                        TypeBadge(typeName: typeName)
                    }
                }
            }

            // Spacer() dehnt sich auf den gesamten verfügbaren Platz aus
            // und schiebt dadurch die Pokédex-Nummer an den rechten Rand.
            Spacer()

            // Pokédex-Nummer rechtsbündig anzeigen
            Text("#\(pokemon.id)")
                .font(.caption.monospacedDigit())  // Monospaced = alle Ziffern gleich breit
                .foregroundStyle(.secondary)        // Grau eingefärbt
        }
        .padding(.vertical, 4)   // Kleiner vertikaler Innenabstand für bessere Lesbarkeit
    }
}

/// Zeigt einen farbigen Typ-Badge für einen Pokémon-Typ an (z. B. "Fire", "Water").
struct TypeBadge: View {
    let typeName: String   // Name des Typs in Kleinbuchstaben, z. B. "fire"

    var body: some View {
        Text(typeName.capitalized)   // Ersten Buchstaben groß schreiben
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)     // Horizontaler Innenabstand
            .padding(.vertical, 3)       // Vertikaler Innenabstand
            // .opacity(0.2) = halb-transparente Hintergrundfarbe (pastellartig)
            .background(color(for: typeName).opacity(0.2))
            .foregroundStyle(color(for: typeName))   // Textfarbe = volle Typfarbe
            .clipShape(Capsule())        // Abgerundete Pillenform
    }

    /// Gibt die passende Farbe für jeden der 18 Pokémon-Typen zurück.
    /// switch = Vergleich mit mehreren Fällen (wie if/else if, aber übersichtlicher).
    private func color(for type: String) -> Color {
        switch type.lowercased() {   // .lowercased() = immer in Kleinbuchstaben vergleichen
        case "fire":     .orange
        case "water":    .blue
        case "grass":    .green
        case "electric": .yellow
        case "psychic":  .pink
        case "ice":      Color(red: 0.4, green: 0.8, blue: 1.0)   // Hellblau
        case "dragon":   .indigo
        case "dark":     Color(red: 0.3, green: 0.2, blue: 0.2)   // Dunkelbraun
        case "fairy":    Color(red: 1.0, green: 0.4, blue: 0.7)   // Rosa
        case "fighting": .red
        case "poison":   .purple
        case "ground":   Color(red: 0.8, green: 0.6, blue: 0.3)   // Sandbraun
        case "flying":   Color(red: 0.5, green: 0.7, blue: 0.9)   // Hellblau-Grau
        case "bug":      Color(red: 0.5, green: 0.7, blue: 0.1)   // Gelbgrün
        case "rock":     Color(red: 0.7, green: 0.6, blue: 0.4)   // Steingrau-Braun
        case "ghost":    Color(red: 0.4, green: 0.3, blue: 0.6)   // Violett
        case "steel":    Color(red: 0.7, green: 0.7, blue: 0.8)   // Silbergrau
        default:         .gray   // Unbekannte Typen: grau
        }
    }
}
