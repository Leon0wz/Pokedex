//
//  GenerationFilterView.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import SwiftUI

/// Horizontale Leiste mit Liquid-Glass-Chips zur Generationsauswahl.
/// Verwendet iOS 26 GlassEffectContainer + .glassEffect() für den nativen Frosted-Glass-Look.
struct GenerationFilterView: View {

    // @Binding = Zwei-Wege-Verbindung zum Set in der Parent-View.
    // Änderungen hier werden direkt nach oben weitergegeben.
    @Binding var selectedGenerations: Set<Int>

    // Römische Ziffern für die Chip-Beschriftung
    private let romanNumerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]

    var body: some View {
        // Horizontales Scrollen erlaubt alle 10 Chips sichtbar zu machen
        ScrollView(.horizontal, showsIndicators: false) {
            // GlassEffectContainer lässt benachbarte Chips visuell ineinander fließen —
            // das ist das charakteristische Merkmal des iOS 26 Liquid Glass Designs.
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {

                    // "Alle"-Chip: hebt alle Generationsfilter auf
                    Button("Alle") {
                        selectedGenerations.removeAll()
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    // Ausgewählt (= kein Filter aktiv) → Akzentfarbe als Tint
                    .glassEffect(
                        .regular
                            .tint(selectedGenerations.isEmpty ? Color.accentColor : Color.clear)
                            .interactive()
                    )

                    // Gen I … Gen IX — ein Chip pro Generation
                    ForEach(0..<9, id: \.self) { index in
                        let generation = index + 1
                        let label = "Gen \(romanNumerals[index])"
                        let isSelected = selectedGenerations.contains(generation)

                        Button(label) {
                            // Toggle: bereits ausgewählt → entfernen, sonst hinzufügen
                            if isSelected {
                                selectedGenerations.remove(generation)
                            } else {
                                selectedGenerations.insert(generation)
                            }
                        }
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        // Ausgewählt → Akzentfarbe-Tint, sonst transparent
                        .glassEffect(
                            .regular
                                .tint(isSelected ? Color.accentColor : Color.clear)
                                .interactive()
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
        }
    }
}
