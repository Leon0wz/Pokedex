//
//  PokemonTypeColor.swift
//  Pokedex
//

import SwiftUI

extension Color {
    /// Gibt die passende Farbe für jeden der 18 Pokemon-Typen zurueck.
    static func pokemonType(_ name: String) -> Color {
        switch name.lowercased() {
        case "normal":   Color(red: 0.66, green: 0.65, blue: 0.56)
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
