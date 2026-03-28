//
//  PokedexApp.swift
//  Pokedex
//
//  Created by Leon Zimny on 28.03.26.
//

import SwiftUI

@main
struct PokedexApp: App {
    @State private var splashFinished = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .opacity(splashFinished ? 1 : 0)

                if !splashFinished {
                    SplashView(isFinished: $splashFinished)
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.4), value: splashFinished)
        }
    }
}
