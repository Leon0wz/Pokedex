//
//  SplashView.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import SwiftUI

// MARK: - SplashView

/// Animierter Ladebildschirm: Eine Pokéball öffnet sich und gibt die App frei.
/// Zeigt eine mehrstufige Animation (Erscheinen → Öffnen → Blitz → Fertig).
struct SplashView: View {

    // @Binding = Zwei-Wege-Verbindung zur Eltern-View (PokedexApp).
    // Wenn wir isFinished auf true setzen, weiß die Eltern-View dass der Splash fertig ist.
    @Binding var isFinished: Bool

    // @State = lokale Zustandsvariablen, die Animationen steuern.
    // Änderungen lösen ein Neuzeichnen der View aus.

    @State private var ballScale: CGFloat = 0       // Startgröße 0 = unsichtbar (wächst auf 1)
    @State private var buttonScale: CGFloat = 1      // Der mittlere Knopf skaliert beim Bounce
    @State private var topYScale: CGFloat = 1        // Obere Hälfte: 1 = normal, 0 = flachgequetscht
    @State private var bottomYScale: CGFloat = 1     // Untere Hälfte: 1 = normal, 0 = flachgequetscht
    @State private var topOffset: CGFloat = 0        // Verschiebung der oberen Hälfte nach oben
    @State private var bottomOffset: CGFloat = 0     // Verschiebung der unteren Hälfte nach unten
    @State private var detailsOpacity: Double = 1    // Sichtbarkeit von Band, Ring und Knopf
    @State private var flashOpacity: Double = 0      // Sichtbarkeit des weißen Blitzes
    @State private var hasStarted = false            // Verhindert dass die Animation zweimal startet
    @State private var ballSize: CGFloat = 0         // Tatsächliche Ballgröße (für Offset-Berechnung)

    var body: some View {
        // GeometryReader gibt Zugriff auf die verfügbare Größe (Breite/Höhe des Eltern-Containers).
        GeometryReader { geo in
            // Ballgröße = 55% der kleineren Seite (passt sich an verschiedene Bildschirmgrößen an)
            let size     = min(geo.size.width, geo.size.height) * 0.55
            let half     = size / 2      // Hälfte = Radius des Balls
            let cx       = geo.size.width  / 2   // Horizontale Mitte des Bildschirms
            let cy       = geo.size.height / 2   // Vertikale Mitte des Bildschirms

            // ZStack schichtet alle Elemente übereinander (wie Ebenen in einer Bildbearbeitung)
            ZStack {
                // Hintergrundfarbe — systemBackground passt sich hell/dunkel Modus an
                Color(uiColor: .systemBackground).ignoresSafeArea()

                // ── Pokéball ──────────────────────────────────────────
                ZStack {

                    // Drop shadow — Schatten unter dem Ball für Tiefenwirkung
                    Ellipse()
                        .fill(Color.black.opacity(0.18))
                        .frame(width: size * 0.75, height: size * 0.1)
                        .blur(radius: 14)        // Weicher Schatten durch Unschärfe
                        .offset(y: half + 18)    // Unter den Ball verschieben
                        .opacity(detailsOpacity)

                    // Outer ring (gives shape to bottom half in light mode)
                    // Äußerer Ring: dünner dunkler Kreis gibt dem Ball eine klare Kontur
                    Circle()
                        .strokeBorder(Color(white: 0.08), lineWidth: size * 0.018)
                        .frame(width: size, height: size)
                        .opacity(detailsOpacity)

                    // ── Top half (red) — circle clipped to upper half ─
                    // Obere Hälfte (rot): Ein Kreis der auf die obere Hälfte zugeschnitten wird.
                    ZStack {
                        Circle()
                            .fill(
                                // RadialGradient = Verlauf der von innen nach außen geht
                                RadialGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.44, blue: 0.44),  // Helles Rot (Mitte)
                                        Color(red: 0.84, green: 0.07, blue: 0.07), // Kräftiges Rot
                                        Color(red: 0.50, green: 0.00, blue: 0.00)  // Dunkles Rot (Rand)
                                    ],
                                    center: UnitPoint(x: 0.38, y: 0.7), // Lichtquelle leicht links
                                    startRadius: 0,
                                    endRadius: size * 0.58
                                )
                            )
                            .frame(width: size, height: size)
                            .offset(y: half / 2)   // circle center at bottom of clip frame = equator

                        // Specular shine — Glanzpunkt für einen 3D-Effekt (wie Lichtreflexion)
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [Color.white.opacity(0.52), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: size * 0.14
                                )
                            )
                            .frame(width: size * 0.32, height: size * 0.22)
                            .offset(x: -size * 0.12, y: -half * 0.28)
                    }
                    .frame(width: size, height: half)
                    .clipped()   // Schneidet alles ab was außerhalb des Frames liegt
                    // scaleEffect skaliert nur in Y-Richtung → Hälfte klappt ein bei topYScale = 0
                    .scaleEffect(x: 1, y: topYScale)
                    // offset verschiebt die Hälfte nach oben wenn topOffset negativ wird
                    .offset(y: -half / 2 + topOffset)

                    // ── Bottom half (white) — circle clipped to lower half
                    // Untere Hälfte (weiß): gleiche Technik, nur nach unten gespiegelt
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white, Color(white: 0.78)],   // Weiß zu Hellgrau
                                    center: UnitPoint(x: 0.45, y: 0.3),
                                    startRadius: 0,
                                    endRadius: size * 0.5
                                )
                            )
                            .frame(width: size, height: size)
                            .offset(y: -half / 2)  // circle center at top of clip frame = equator
                    }
                    .frame(width: size, height: half)
                    .clipped()
                    .scaleEffect(x: 1, y: bottomYScale)
                    .offset(y: half / 2 + bottomOffset)

                    // ── Center band ───────────────────────────────────
                    // Schwarzes Band in der Mitte der Pokéball (das horizontale Trennband)
                    Rectangle()
                        .fill(Color(white: 0.08))
                        .frame(width: size, height: size * 0.08)
                        .opacity(detailsOpacity)

                    // ── Center button ─────────────────────────────────
                    // Der mittige weiße Knopf der Pokéball (kleiner Kreis in der Mitte)
                    Circle()
                        .fill(Color(white: 0.08))                        // Dunkler Außenring
                        .frame(width: size * 0.19, height: size * 0.19)
                        .overlay(
                            // Überlagerter weißer Innenknopf mit Glanzeffekt
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.white, Color(white: 0.82)],
                                        center: UnitPoint(x: 0.38, y: 0.32),
                                        startRadius: 0,
                                        endRadius: size * 0.08
                                    )
                                )
                                .frame(width: size * 0.12, height: size * 0.12)
                        )
                        .scaleEffect(buttonScale)    // Skaliert beim Bounce-Effekt
                        .opacity(detailsOpacity)
                }
                // scaleEffect auf den gesamten Ball: 0 → erscheint mit Sprung-Animation
                .scaleEffect(ballScale)
                // position platziert den Ball exakt in der Bildschirmmitte
                .position(x: cx, y: cy)

                // ── Flash ─────────────────────────────────────────────
                // Weißer Blitz der kurz aufleuchtet wenn der Ball sich öffnet
                Color.white
                    .ignoresSafeArea()
                    .opacity(flashOpacity)   // 0 = unsichtbar, 1 = voller weißer Bildschirm
            }
        }
        // .onAppear wird aufgerufen sobald die View auf dem Bildschirm erscheint
        .onAppear {
            guard !hasStarted else { return }  // Animation nur einmal starten
            hasStarted = true
            // Schätzung für die Ballgröße - wird durch tatsächliche Geometry überschrieben
            ballSize = 200
            animate()   // Animation starten
        }
        // .onGeometryChange reagiert auf Größenänderungen (z. B. Gerät drehen)
        // Aktualisiert ballSize damit die Offset-Berechnung in animate() korrekt bleibt
        .onGeometryChange(for: CGFloat.self) { proxy in
            min(proxy.size.width, proxy.size.height) * 0.55
        } action: { newSize in
            ballSize = newSize
        }
    }

    /// Führt die mehrstufige Pokéball-Animation aus.
    /// Alle Animationen werden mit Verzögerungen (delay) gestaffelt.
    private func animate() {
        // 1. Ball erscheint — springt aus dem Nichts (scale 0 → 1)
        // .spring = federnde Animation mit response (Geschwindigkeit) und dampingFraction (Dämpfung)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.58)) {
            ballScale = 1
        }

        // 2. Button bounce — der mittlere Knopf springt kurz auf (scale 1 → 1.5 → 1)
        // .delay(0.55) = startet 0,55 Sekunden nach dem Funktionsaufruf
        withAnimation(.spring(response: 0.22, dampingFraction: 0.38).delay(0.55)) {
            buttonScale = 1.5   // Vergrößern
        }
        withAnimation(.spring(response: 0.22, dampingFraction: 0.55).delay(0.76)) {
            buttonScale = 1.0   // Zurück auf normale Größe
        }

        // 3. Band und Ring ausblenden — verschwinden bevor sich der Ball öffnet
        withAnimation(.easeOut(duration: 0.14).delay(0.88)) {
            detailsOpacity = 0
        }

        // 4. Ball öffnet sich — die zwei Hälften quetschen sich flach und fliegen auseinander
        // topYScale/bottomYScale → 0: Hälften flachdrücken
        // topOffset/bottomOffset: Hälften nach oben/unten wegfliegen
        withAnimation(.easeInOut(duration: 0.38).delay(0.92)) {
            topYScale    = 0
            bottomYScale = 0
            topOffset    = -ballSize * 0.6    // Obere Hälfte fliegt nach oben
            bottomOffset =  ballSize * 0.6    // Untere Hälfte fliegt nach unten
        }

        // 5. White flash — starts exactly when ball is fully open (0.92 + 0.38 = 1.30)
        // Weißer Blitz: erscheint genau wenn der Ball vollständig offen ist
        withAnimation(.easeIn(duration: 0.10).delay(1.30)) {
            flashOpacity = 1   // Einblenden
        }
        withAnimation(.easeOut(duration: 0.35).delay(1.40)) {
            flashOpacity = 0   // Ausblenden
        }

        // 6. Done — Splash beendet, ContentView übernimmt
        // DispatchQueue.main.asyncAfter: führt Code nach einer Verzögerung auf dem Haupt-Thread aus
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
            isFinished = true   // Eltern-View (PokedexApp) wird benachrichtigt
        }
    }
}

// Xcode-Canvas-Vorschau für die SplashView
#Preview {
    SplashView(isFinished: .constant(false))   // .constant = unveränderlicher Binding-Wert für Preview
}
