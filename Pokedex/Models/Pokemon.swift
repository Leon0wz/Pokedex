//
//  Pokemon.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import SwiftData  // Für das @Model-Makro und Datenbankfunktionalität
import Foundation // Für grundlegende Typen wie Data, JSONDecoder

// @Model ist ein SwiftData-Makro, das diese Klasse zu einem persistierbaren Modell macht.
// SwiftData generiert automatisch den Code zum Speichern und Laden in/aus der Datenbank.
@Model
// "final" bedeutet: diese Klasse kann nicht als Basisklasse für Vererbung verwendet werden.
// Das verbessert die Performance, da der Compiler keine Polymorphie einplanen muss.
final class Pokemon {

    // @Attribute(.unique) stellt sicher, dass jede id in der Datenbank einmalig ist.
    // Doppelte Einträge mit der gleichen id werden abgelehnt.
    @Attribute(.unique) var id: Int

    var name: String

    // String? = optionaler String — kann nil sein, wenn die URL noch nicht geladen wurde.
    var spriteURL: String?       // URL zum kleinen Sprite-Bild (Pixel-Art)
    var officialArtURL: String?  // URL zum offiziellen hochauflösenden Artwork

    /// Kommagetrennte Typ-Namen, z. B. "fire,flying"
    /// Typen werden als einfacher String gespeichert, da SwiftData keine String-Arrays direkt unterstützt.
    var typesRaw: String

    /// JSON-kodiertes Array von StatEntry-Objekten.
    /// Data ist ein roher Byte-Puffer — hier genutzt um JSON-Daten platzsparend zu speichern.
    var statsData: Data

    // Bool-Flag: wurde das Detail dieses Pokémon schon von der API geladen?
    // false = nur Name+ID bekannt, true = Sprites, Typen und Stats sind vorhanden.
    var isDetailFetched: Bool

    // Initializer = Konstruktor. Wird aufgerufen wenn ein neues Pokemon-Objekt erstellt wird.
    // Beim ersten Anlegen (aus der Listen-API) kennen wir nur id und name.
    init(id: Int, name: String) {
        self.id = id
        self.name = name
        self.typesRaw = ""       // Noch leer, wird beim Detail-Fetch gefüllt
        self.statsData = Data()  // Leere Daten, werden beim Detail-Fetch gesetzt
        self.isDetailFetched = false
    }

    // Computed Property: wird jedes Mal neu berechnet wenn sie gelesen wird.
    // Wandelt den gespeicherten String "fire,flying" in ein Array ["fire", "flying"] um.
    var types: [String] {
        // isEmpty prüft ob der String leer ist.
        // split(separator:) teilt den String am Komma auf.
        // map(String.init) wandelt jeden SubString in einen vollwertigen String um.
        typesRaw.isEmpty ? [] : typesRaw.split(separator: ",").map(String.init)
    }

    // Verschachtelte Struktur für einen einzelnen Basis-Stat-Eintrag.
    // Codable = kann sowohl kodiert (zu JSON) als auch dekodiert (von JSON) werden.
    struct StatEntry: Codable {
        var name: String     // Name des Stats, z. B. "hp", "attack", "speed"
        var baseStat: Int    // Basiswert des Stats (0–255)
    }

    // Computed Property: dekodiert das gespeicherte JSON (statsData) zurück in ein Array.
    // try? gibt nil zurück wenn die Dekodierung fehlschlägt, statt einen Fehler zu werfen.
    // ?? [] = Fallback: leeres Array wenn nil zurückkommt.
    var stats: [StatEntry] {
        (try? JSONDecoder().decode([StatEntry].self, from: statsData)) ?? []
    }

    // Berechnet die Generation anhand der Pokédex-Nummer.
    // Die Grenzen entsprechen den offiziellen Generationsbereichen der Hauptreihe.
    var generation: Int {
        switch id {
        case 1...151:   return 1
        case 152...251: return 2
        case 252...386: return 3
        case 387...493: return 4
        case 494...649: return 5
        case 650...721: return 6
        case 722...809: return 7
        case 810...905: return 8
        default:        return 9
        }
    }
}
