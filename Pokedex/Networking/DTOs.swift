//
//  DTOs.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import Foundation

// MARK: - List endpoint

struct PokemonListResponse: Codable, Sendable {
    let count: Int
    let results: [PokemonListItem]
}

struct PokemonListItem: Codable, Sendable {
    let name: String
    let url: String

    /// Extracts the numeric ID from the trailing path component of the URL.
    var id: Int? {
        Int(url.split(separator: "/").last ?? "")
    }
}

// MARK: - Detail endpoint

struct PokemonDetailResponse: Codable, Sendable {
    let id: Int
    let name: String
    let sprites: Sprites
    let types: [TypeSlot]
    let stats: [StatSlot]

    struct Sprites: Codable, Sendable {
        let frontDefault: String?
        let other: OtherSprites?

        enum CodingKeys: String, CodingKey {
            case frontDefault = "front_default"
            case other
        }

        struct OtherSprites: Codable, Sendable {
            let officialArtwork: OfficialArtwork?

            enum CodingKeys: String, CodingKey {
                case officialArtwork = "official-artwork"
            }

            struct OfficialArtwork: Codable, Sendable {
                let frontDefault: String?
                enum CodingKeys: String, CodingKey {
                    case frontDefault = "front_default"
                }
            }
        }
    }

    struct TypeSlot: Codable, Sendable {
        let slot: Int
        let type: NamedResource
    }

    struct StatSlot: Codable, Sendable {
        let baseStat: Int
        let stat: NamedResource
        enum CodingKeys: String, CodingKey {
            case baseStat = "base_stat"
            case stat
        }
    }
}

struct NamedResource: Codable, Sendable {
    let name: String
    let url: String
}
