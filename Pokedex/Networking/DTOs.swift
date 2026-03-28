//
//  DTOs.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import Foundation

// DTOs = Data Transfer Objects
// Diese Structs spiegeln exakt die JSON-Struktur der PokeAPI wider.
// Sie werden nur zum Empfangen von API-Daten verwendet, nicht zur Datenspeicherung.
//
// Codable = Encodable + Decodable
//   → Decodable: JSON kann automatisch in diese Swift-Structs umgewandelt werden
//   → Encodable: Structs können zu JSON umgewandelt werden (hier nicht benötigt, aber dabei)
//
// Sendable = dieser Typ kann sicher zwischen verschiedenen Threads/Tasks übergeben werden.
// Wichtig für Swift's Concurrency-System (async/await, actors).

// MARK: - List endpoint
// Antwort der API auf: GET /api/v2/pokemon?limit=1025&offset=0

/// Antwort der API wenn eine Liste von Pokémon abgerufen wird.
struct PokemonListResponse: Codable, Sendable {
    let count: Int                    // Gesamtanzahl aller Pokémon in der API
    let results: [PokemonListItem]    // Array mit Name und URL für jedes Pokémon
}

/// Ein einzelner Eintrag in der Pokémon-Liste (Name + URL zum Detail-Endpunkt).
struct PokemonListItem: Codable, Sendable {
    let name: String  // Pokémon-Name, z. B. "bulbasaur"
    let url: String   // URL zum Detail-Endpunkt, z. B. "https://pokeapi.co/api/v2/pokemon/1/"

    /// Extracts the numeric ID from the trailing path component of the URL.
    /// Liest die numerische ID aus dem letzten Teil der URL heraus.
    /// Beispiel: "https://pokeapi.co/api/v2/pokemon/1/" → 1
    var id: Int? {
        // split(separator:) trennt die URL an "/" auf → letztes Element ist die ID.
        // Int(...) versucht den String in eine Zahl umzuwandeln — gibt nil zurück wenn es fehlschlägt.
        Int(url.split(separator: "/").last ?? "")
    }
}

// MARK: - Detail endpoint
// Antwort der API auf: GET /api/v2/pokemon/{id}

/// Vollständige Detailinformationen eines Pokémon von der API.
struct PokemonDetailResponse: Codable, Sendable {
    let id: Int               // Pokédex-Nummer
    let name: String          // Name des Pokémon
    let sprites: Sprites      // BildURLs
    let types: [TypeSlot]     // Typ(en) des Pokémon (z. B. Feuer, Wasser)
    let stats: [StatSlot]     // Basis-Stats (KP, Angriff, Verteidigung usw.)

    /// Enthält die URLs zu den verschiedenen Sprite-Bildern des Pokémon.
    struct Sprites: Codable, Sendable {
        let frontDefault: String?   // URL zum Standard-Sprite (Pixelgrafik)
        let other: OtherSprites?    // Optionaler Block mit weiteren Artwork-Varianten

        // CodingKeys mappt Swift-Eigenschaftsnamen auf JSON-Schlüssel.
        // Die API verwendet snake_case ("front_default"), Swift bevorzugt camelCase.
        enum CodingKeys: String, CodingKey {
            case frontDefault = "front_default"
            case other
        }

        /// Weitere Sprite-Varianten außerhalb der Standard-Sprites.
        struct OtherSprites: Codable, Sendable {
            let officialArtwork: OfficialArtwork?   // Das hochauflösende offizielle Artwork

            // JSON-Schlüssel "official-artwork" (mit Bindestrich!) → Swift-Name officialArtwork
            enum CodingKeys: String, CodingKey {
                case officialArtwork = "official-artwork"
            }

            /// Das offizielle Artwork-Bild des Pokémon (hochauflösend).
            struct OfficialArtwork: Codable, Sendable {
                let frontDefault: String?   // URL zum offiziellen Artwork
                enum CodingKeys: String, CodingKey {
                    case frontDefault = "front_default"
                }
            }
        }
    }

    /// Ein Typ-Slot: Pokémon können bis zu zwei Typen haben (slot 1 und slot 2).
    struct TypeSlot: Codable, Sendable {
        let slot: Int              // Position (1 = primär, 2 = sekundär)
        let type: NamedResource    // Der eigentliche Typ (Name + URL)
    }

    /// Ein Stat-Slot: enthält den Basiswert und den Namen des Stats.
    struct StatSlot: Codable, Sendable {
        let baseStat: Int          // Der Basiswert des Stats (z. B. 45 für KP)
        let stat: NamedResource    // Der Name des Stats (z. B. "hp", "attack")

        // JSON verwendet "base_stat" (snake_case), Swift "baseStat" (camelCase)
        enum CodingKeys: String, CodingKey {
            case baseStat = "base_stat"
            case stat
        }
    }
}

/// Allgemeines Objekt der PokeAPI für benannte Ressourcen mit Referenz-URL.
/// Wird für Typen, Stats und andere verlinkbare Ressourcen verwendet.
struct NamedResource: Codable, Sendable {
    let name: String   // Name der Ressource, z. B. "fire" oder "attack"
    let url: String    // Link zur Detailseite der Ressource in der API
}
