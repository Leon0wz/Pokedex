//
//  PokeAPIClient.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import Foundation

// MARK: - Protocol

protocol PokeAPIClientProtocol: Sendable {
    func fetchPokemonList(limit: Int, offset: Int) async throws -> PokemonListResponse
    func fetchPokemonDetail(id: Int) async throws -> PokemonDetailResponse
}

// MARK: - Errors

enum PokeAPIError: Error, LocalizedError, Equatable {
    case invalidURL
    case httpError(statusCode: Int)
    case decodingError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .httpError(let code):
            return "HTTP error \(code)"
        case .decodingError(let error):
            return "Decoding failed: \(error.localizedDescription)"
        }
    }

    static func == (lhs: PokeAPIError, rhs: PokeAPIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL): true
        case (.httpError(let l), .httpError(let r)): l == r
        case (.decodingError, .decodingError): true
        default: false
        }
    }
}

// MARK: - Live Implementation

struct PokeAPIClient: PokeAPIClientProtocol {
    // let properties are Sendable — safe to access from nonisolated methods
    private let baseURL = URL(string: "https://pokeapi.co/api/v2")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // nonisolated required: SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor would otherwise
    // make these @MainActor, preventing conformance to the nonisolated protocol requirement.
    nonisolated func fetchPokemonList(limit: Int, offset: Int) async throws -> PokemonListResponse {
        var components = URLComponents(
            url: baseURL.appending(path: "pokemon"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        guard let url = components.url else { throw PokeAPIError.invalidURL }
        return try await fetch(url: url, as: PokemonListResponse.self)
    }

    nonisolated func fetchPokemonDetail(id: Int) async throws -> PokemonDetailResponse {
        let url = baseURL.appending(path: "pokemon/\(id)")
        return try await fetch(url: url, as: PokemonDetailResponse.self)
    }

    nonisolated private func fetch<T: Decodable>(url: URL, as type: T.Type) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw PokeAPIError.invalidURL
        }
        guard (200..<300).contains(http.statusCode) else {
            throw PokeAPIError.httpError(statusCode: http.statusCode)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw PokeAPIError.decodingError(underlying: error)
        }
    }
}
