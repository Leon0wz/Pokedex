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
    @Binding var selectedGenerations: Set<Int>

    private let romanNumerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            // GlassEffectContainer lässt benachbarte Chips visuell ineinander fließen —
            // das charakteristische Merkmal des iOS 26 Liquid Glass Designs.
            GlassEffectContainer(spacing: 6) {
                HStack(spacing: 6) {

                    // "Alle"-Chip: hebt alle Generationsfilter auf
                    chipButton(
                        label: "Alle",
                        isSelected: selectedGenerations.isEmpty
                    ) {
                        selectedGenerations.removeAll()
                    }

                    // Gen I … Gen IX
                    ForEach(0..<9, id: \.self) { index in
                        let generation = index + 1
                        chipButton(
                            label: "Gen \(romanNumerals[index])",
                            isSelected: selectedGenerations.contains(generation)
                        ) {
                            if selectedGenerations.contains(generation) {
                                selectedGenerations.remove(generation)
                            } else {
                                selectedGenerations.insert(generation)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }

    /// Gibt einen einzelnen Generations-Chip zurück.
    /// Ausgewählt: weißer Text auf Akzentfarbe-Tint.
    /// Nicht ausgewählt: primärer Text auf transparentem Glas.
    @ViewBuilder
    private func chipButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                // Explizites foregroundStyle verhindert unsichtbaren Text auf Tint-Hintergrund
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        // .buttonStyle(.plain) verhindert Default-Button-Styling das mit glassEffect kollidiert
        .buttonStyle(.plain)
        .glassEffect(
            .regular
                .tint(isSelected ? Color.accentColor : Color.clear)
                .interactive()
        )
    }
}
