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

/// Zeigt einen farbigen Typ-Badge für einen Pokemon-Typ an.
struct TypeBadge: View {
    let typeName: String

    var body: some View {
        Text(typeName.capitalized)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.pokemonType(typeName).opacity(0.2))
            .foregroundStyle(Color.pokemonType(typeName))
            .clipShape(Capsule())
    }
}
