//
//  PokeAPIClient.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import Foundation

// MARK: - Protocol

// Ein Protocol definiert einen "Vertrag" — es legt fest, welche Methoden ein Typ
// haben MUSS, ohne die konkrete Implementierung vorzugeben.
// Vorteil: Im Test können wir eine Fake-Implementierung einsetzen (Dependency Injection).
// Sendable: Sicher über Thread-/Task-Grenzen hinweg nutzbar.
protocol PokeAPIClientProtocol: Sendable {
    /// Lädt eine paginierte Liste aller Pokémon.
    /// - limit:  Anzahl der Ergebnisse pro Anfrage
    /// - offset: Ab welchem Eintrag gestartet wird (für Paginierung)
    /// async throws = asynchron (wartet auf Netzwerkantwort) und kann Fehler werfen
    func fetchPokemonList(limit: Int, offset: Int) async throws -> PokemonListResponse

    /// Lädt die Detaildaten eines einzelnen Pokémon anhand seiner ID.
    func fetchPokemonDetail(id: Int) async throws -> PokemonDetailResponse
}

// MARK: - Errors

// enum für Fehlertypen: Jeder case steht für einen möglichen Fehler.
// Error = kann als Swift-Fehler geworfen/gefangen werden.
// LocalizedError = liefert eine lesbare Fehlermeldung über errorDescription.
// Equatable = zwei Fehler können mit == verglichen werden.
enum PokeAPIError: Error, LocalizedError, Equatable {
    case invalidURL                     // Die URL konnte nicht aufgebaut werden
    case httpError(statusCode: Int)     // Der Server antwortete mit einem Fehler-Statuscode
    case decodingError(underlying: Error) // Das JSON konnte nicht verarbeitet werden

    // errorDescription liefert einen menschenlesbaren Fehlertext.
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .httpError(let code):
            return "HTTP error \(code)"     // \(...) = String-Interpolation
        case .decodingError(let error):
            return "Decoding failed: \(error.localizedDescription)"
        }
    }

    // Eigene Implementierung von == (Gleichheitsvergleich), weil decodingError
    // einen assoziierten Error-Wert hat, der selbst kein Equatable ist.
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

// Dies ist die echte Implementierung des Protokolls.
// struct statt class: Structs sind Werttypen (kopiert, nicht referenziert) — effizienter.
struct PokeAPIClient: PokeAPIClientProtocol {

    // let properties are Sendable — safe to access from nonisolated methods
    // Konstante Eigenschaften können sicher von beliebigen Threads gelesen werden.
    private let baseURL = URL(string: "https://pokeapi.co/api/v2")! // Basis-URL der PokéAPI
    private let session: URLSession  // URLSession ist Apples eingebauter Netzwerk-Client

    // Initializer mit Standardwert: Wenn kein session übergeben wird, nutzen wir .shared.
    // .shared = die globale Standard-URLSession-Instanz
    init(session: URLSession = .shared) {
        self.session = session
    }

    // nonisolated required: SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor would otherwise
    // make these @MainActor, preventing conformance to the nonisolated protocol requirement.
    //
    // nonisolated = Diese Methode läuft NICHT auf einem bestimmten Actor (z. B. MainActor).
    // Das ist nötig, damit die Methode dem Protokoll entspricht, das ebenfalls nonisolated ist.
    nonisolated func fetchPokemonList(limit: Int, offset: Int) async throws -> PokemonListResponse {
        // URLComponents baut URLs sicher zusammen — kein manuelles String-Basteln.
        var components = URLComponents(
            url: baseURL.appending(path: "pokemon"),
            resolvingAgainstBaseURL: false
        )!
        // URLQueryItem fügt Query-Parameter hinzu: ?limit=1025&offset=0
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        // guard...else = frühzeitiger Ausstieg mit Fehler wenn die URL nicht gebaut werden konnte
        guard let url = components.url else { throw PokeAPIError.invalidURL }
        // Weiterleitung an die generische fetch-Methode
        return try await fetch(url: url, as: PokemonListResponse.self)
    }

    nonisolated func fetchPokemonDetail(id: Int) async throws -> PokemonDetailResponse {
        // appending(path:) hängt einen Pfad-Abschnitt an die Basis-URL an
        let url = baseURL.appending(path: "pokemon/\(id)")
        return try await fetch(url: url, as: PokemonDetailResponse.self)
    }

    // Generische Hilfsmethode für alle HTTP-GET-Anfragen.
    // <T: Decodable & Sendable> — Sendable ist nötig damit der Wert sicher von MainActor
    // zurück in den nonisolated Kontext übergeben werden kann (Swift 6 Concurrency).
    // Der Aufrufer bestimmt welchen Typ er zurückbekommen möchte (z. B. PokemonListResponse).
    nonisolated private func fetch<T: Decodable & Sendable>(url: URL, as type: T.Type) async throws -> T {
        // session.data(from:) führt den Netzwerkaufruf durch und liefert Rohdaten + Antwort.
        // await = warte bis die Antwort da ist (blockiert nicht den Thread)
        let (data, response) = try await session.data(from: url)

        // response als HTTPURLResponse casten um den Statuscode lesen zu können
        guard let http = response as? HTTPURLResponse else {
            throw PokeAPIError.invalidURL
        }

        // HTTP-Statuscodes 200–299 = Erfolg. Alles andere ist ein Fehler.
        guard (200..<300).contains(http.statusCode) else {
            throw PokeAPIError.httpError(statusCode: http.statusCode)
        }

        // JSONDecoder wandelt die rohen JSON-Bytes in ein Swift-Objekt vom Typ T um.
        // MainActor.run: Mit SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor werden die
        // synthesized Decodable-Initializer @MainActor-isoliert. Durch explizites
        // Hopping auf den MainActor für den Decode-Call wird der Swift 6 Fehler behoben.
        do {
            return try await MainActor.run {
                try JSONDecoder().decode(T.self, from: data)
            }
        } catch {
            // Dekodierungsfehler in unseren eigenen Fehlertyp einwickeln
            throw PokeAPIError.decodingError(underlying: error)
        }
    }
}
