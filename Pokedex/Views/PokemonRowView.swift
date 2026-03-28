//
//  PokemonRowView.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import SwiftUI

struct PokemonRowView: View {
    let pokemon: Pokemon

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: pokemon.spriteURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure, .empty:
                    Image(systemName: "circle.dotted")
                        .foregroundStyle(.secondary)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(pokemon.name.capitalized)
                    .font(.body.weight(.semibold))

                HStack(spacing: 4) {
                    ForEach(pokemon.types, id: \.self) { typeName in
                        TypeBadge(typeName: typeName)
                    }
                }
            }

            Spacer()

            Text("#\(pokemon.id)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct TypeBadge: View {
    let typeName: String

    var body: some View {
        Text(typeName.capitalized)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color(for: typeName).opacity(0.2))
            .foregroundStyle(color(for: typeName))
            .clipShape(Capsule())
    }

    private func color(for type: String) -> Color {
        switch type.lowercased() {
        case "fire":     .orange
        case "water":    .blue
        case "grass":    .green
        case "electric": .yellow
        case "psychic":  .pink
        case "ice":      Color(red: 0.4, green: 0.8, blue: 1.0)
        case "dragon":   .indigo
        case "dark":     Color(red: 0.3, green: 0.2, blue: 0.2)
        case "fairy":    Color(red: 1.0, green: 0.4, blue: 0.7)
        case "fighting": .red
        case "poison":   .purple
        case "ground":   Color(red: 0.8, green: 0.6, blue: 0.3)
        case "flying":   Color(red: 0.5, green: 0.7, blue: 0.9)
        case "bug":      Color(red: 0.5, green: 0.7, blue: 0.1)
        case "rock":     Color(red: 0.7, green: 0.6, blue: 0.4)
        case "ghost":    Color(red: 0.4, green: 0.3, blue: 0.6)
        case "steel":    Color(red: 0.7, green: 0.7, blue: 0.8)
        default:         .gray
        }
    }
}
