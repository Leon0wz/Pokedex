//
//  SplashView.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import SwiftUI

// MARK: - SplashView

struct SplashView: View {
    @Binding var isFinished: Bool

    @State private var ballScale: CGFloat = 0
    @State private var buttonScale: CGFloat = 1
    @State private var topYScale: CGFloat = 1
    @State private var bottomYScale: CGFloat = 1
    @State private var topOffset: CGFloat = 0
    @State private var bottomOffset: CGFloat = 0
    @State private var detailsOpacity: Double = 1
    @State private var flashOpacity: Double = 0
    @State private var hasStarted = false
    @State private var ballSize: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let size     = min(geo.size.width, geo.size.height) * 0.55
            let half     = size / 2
            let cx       = geo.size.width  / 2
            let cy       = geo.size.height / 2

            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()

                // ── Pokéball ──────────────────────────────────────────
                ZStack {

                    // Drop shadow
                    Ellipse()
                        .fill(Color.black.opacity(0.18))
                        .frame(width: size * 0.75, height: size * 0.1)
                        .blur(radius: 14)
                        .offset(y: half + 18)
                        .opacity(detailsOpacity)

                    // Outer ring (gives shape to bottom half in light mode)
                    Circle()
                        .strokeBorder(Color(white: 0.08), lineWidth: size * 0.018)
                        .frame(width: size, height: size)
                        .opacity(detailsOpacity)

                    // ── Top half (red) — circle clipped to upper half ─
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.44, blue: 0.44),
                                        Color(red: 0.84, green: 0.07, blue: 0.07),
                                        Color(red: 0.50, green: 0.00, blue: 0.00)
                                    ],
                                    center: UnitPoint(x: 0.38, y: 0.7),
                                    startRadius: 0,
                                    endRadius: size * 0.58
                                )
                            )
                            .frame(width: size, height: size)
                            .offset(y: half / 2)   // circle center at bottom of clip frame = equator

                        // Specular shine
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
                    .clipped()
                    .scaleEffect(x: 1, y: topYScale)
                    .offset(y: -half / 2 + topOffset)

                    // ── Bottom half (white) — circle clipped to lower half
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white, Color(white: 0.78)],
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
                    Rectangle()
                        .fill(Color(white: 0.08))
                        .frame(width: size, height: size * 0.08)
                        .opacity(detailsOpacity)

                    // ── Center button ─────────────────────────────────
                    Circle()
                        .fill(Color(white: 0.08))
                        .frame(width: size * 0.19, height: size * 0.19)
                        .overlay(
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
                        .scaleEffect(buttonScale)
                        .opacity(detailsOpacity)
                }
                .scaleEffect(ballScale)
                .position(x: cx, y: cy)

                // ── Flash ─────────────────────────────────────────────
                Color.white
                    .ignoresSafeArea()
                    .opacity(flashOpacity)
            }
        }
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            // Schätzung für die Ballgröße - wird durch tatsächliche Geometry überschrieben
            ballSize = 200
            animate()
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            min(proxy.size.width, proxy.size.height) * 0.55
        } action: { newSize in
            ballSize = newSize
        }
    }

    private func animate() {
        // 1. Ball appears
        withAnimation(.spring(response: 0.35, dampingFraction: 0.58)) {
            ballScale = 1
        }

        // 2. Button bounce
        withAnimation(.spring(response: 0.22, dampingFraction: 0.38).delay(0.55)) {
            buttonScale = 1.5
        }
        withAnimation(.spring(response: 0.22, dampingFraction: 0.55).delay(0.76)) {
            buttonScale = 1.0
        }

        // 3. Fade band/ring before opening
        withAnimation(.easeOut(duration: 0.14).delay(0.88)) {
            detailsOpacity = 0
        }

        // 4. Ball opens: halves fold flat and fly apart
        withAnimation(.easeInOut(duration: 0.38).delay(0.92)) {
            topYScale    = 0
            bottomYScale = 0
            topOffset    = -ballSize * 0.6
            bottomOffset =  ballSize * 0.6
        }

        // 5. White flash — starts exactly when ball is fully open (0.92 + 0.38 = 1.30)
        withAnimation(.easeIn(duration: 0.10).delay(1.30)) {
            flashOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.35).delay(1.40)) {
            flashOpacity = 0
        }

        // 6. Done
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
            isFinished = true
        }
    }
}

#Preview {
    SplashView(isFinished: .constant(false))
}
