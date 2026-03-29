//
//  PokemonDetailView.swift
//  Pokedex
//

import SwiftUI
import SwiftData

// MARK: - ViewModel

@Observable
@MainActor
final class PokemonDetailViewModel {
    var isLoadingSpecies = false
    var speciesError: Error?

    private let client = PokeAPIClient()

    func loadSpeciesIfNeeded(for pokemon: Pokemon, context: ModelContext) async {
        guard !pokemon.isSpeciesFetched, !isLoadingSpecies else { return }
        isLoadingSpecies = true
        defer { isLoadingSpecies = false }

        do {
            let species = try await client.fetchPokemonSpecies(id: pokemon.id)

            if let entry = species.flavorTextEntries.first(where: { $0.language.name == "en" }) {
                pokemon.flavorText = entry.flavorText
                    .replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "\u{0C}", with: " ")
                    .replacingOccurrences(of: "  ", with: " ")
            }

            if let genusEntry = species.genera.first(where: { $0.language.name == "en" }) {
                pokemon.genus = genusEntry.genus
            }

            pokemon.isSpeciesFetched = true
            try context.save()
        } catch {
            speciesError = error
        }
    }
}

// MARK: - Detail View

struct PokemonDetailView: View {
    let pokemon: Pokemon

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PokemonDetailViewModel()
    @State private var statsAnimated = false

    private var primaryTypeColor: Color {
        guard let first = pokemon.types.first else { return .gray }
        return Color.pokemonType(first)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                contentSections
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSpeciesIfNeeded(for: pokemon, context: modelContext)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                statsAnimated = true
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // Gradient background
            LinearGradient(
                colors: [
                    primaryTypeColor.opacity(0.5),
                    primaryTypeColor.opacity(0.2),
                    Color(uiColor: .systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 360)

            VStack(spacing: 8) {
                // Pokedex number
                Text(String(format: "#%03d", pokemon.id))
                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                    .foregroundStyle(primaryTypeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(primaryTypeColor.opacity(0.12))
                    .clipShape(Capsule())

                // Artwork
                AsyncImage(url: URL(string: pokemon.officialArtURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 80))
                            .foregroundStyle(.tertiary)
                    default:
                        ProgressView()
                            .scaleEffect(1.5)
                    }
                }
                .frame(width: 240, height: 240)
                .shadow(color: primaryTypeColor.opacity(0.4), radius: 30, y: 10)

                // Name
                Text(pokemon.name.capitalized)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                // Genus
                if !pokemon.genus.isEmpty {
                    Text(pokemon.genus)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if viewModel.isLoadingSpecies {
                    Text(" ")
                        .font(.subheadline)
                        .redacted(reason: .placeholder)
                }
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Content

    private var contentSections: some View {
        VStack(spacing: 24) {
            typeBadgesRow
            physicalInfoCard
            aboutSection
            baseStatsSection
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 40)
    }

    // MARK: - Type Badges

    private var typeBadgesRow: some View {
        HStack(spacing: 8) {
            ForEach(pokemon.types, id: \.self) { typeName in
                Text(typeName.capitalized)
                    .font(.system(.callout, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.pokemonType(typeName))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Physical Info

    private var physicalInfoCard: some View {
        HStack(spacing: 0) {
            // Height
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "ruler.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(pokemon.formattedHeight)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
                Text("Height")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // Weight
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "scalemass.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(pokemon.formattedWeight)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
                Text("Weight")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // Abilities
            VStack(spacing: 4) {
                if pokemon.abilities.isEmpty {
                    Text("--")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                } else {
                    ForEach(pokemon.abilities, id: \.self) { ability in
                        Text(ability)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .lineLimit(1)
                    }
                }
                Text("Abilities")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About")
                .font(.system(.title3, design: .rounded, weight: .bold))

            if viewModel.isLoadingSpecies && pokemon.flavorText.isEmpty {
                VStack(spacing: 8) {
                    Text("Loading description text from the PokeAPI database for display here.")
                        .redacted(reason: .placeholder)
                }
            } else if !pokemon.flavorText.isEmpty {
                Text(pokemon.flavorText)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            } else if viewModel.speciesError != nil {
                Label("Could not load description.", systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Base Stats

    private var baseStatsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Base Stats")
                .font(.system(.title3, design: .rounded, weight: .bold))

            VStack(spacing: 10) {
                ForEach(pokemon.stats, id: \.name) { stat in
                    StatBarView(
                        statName: stat.name,
                        value: stat.baseStat,
                        animated: statsAnimated
                    )
                }

                Divider()
                    .padding(.vertical, 2)

                HStack {
                    Text("Total")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .frame(width: 52, alignment: .trailing)

                    Text("\(pokemon.stats.reduce(0) { $0 + $1.baseStat })")
                        .font(.system(.callout, design: .monospaced, weight: .bold))
                        .frame(width: 40, alignment: .trailing)

                    Spacer()
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Stat Bar

struct StatBarView: View {
    let statName: String
    let value: Int
    var maxValue: Int = 255
    var animated: Bool = false

    private var abbreviation: String {
        switch statName.lowercased() {
        case "hp":              return "HP"
        case "attack":          return "Atk"
        case "defense":         return "Def"
        case "special-attack":  return "Sp.Atk"
        case "special-defense": return "Sp.Def"
        case "speed":           return "Spd"
        default:                return statName.prefix(3).capitalized
        }
    }

    private var barColor: Color {
        switch value {
        case ..<50:  return Color(red: 0.90, green: 0.30, blue: 0.25)
        case 50..<80:  return Color(red: 0.95, green: 0.60, blue: 0.20)
        case 80..<100: return Color(red: 0.92, green: 0.82, blue: 0.20)
        default:       return Color(red: 0.30, green: 0.78, blue: 0.40)
        }
    }

    private var fraction: CGFloat {
        guard maxValue > 0 else { return 0 }
        return min(CGFloat(value) / CGFloat(maxValue), 1.0)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(abbreviation)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .trailing)

            Text("\(value)")
                .font(.system(.callout, design: .monospaced, weight: .medium))
                .frame(width: 40, alignment: .trailing)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(barColor.opacity(0.15))
                        .frame(height: 8)

                    Capsule()
                        .fill(barColor)
                        .frame(
                            width: animated ? geo.size.width * fraction : 0,
                            height: 8
                        )
                }
            }
            .frame(height: 8)
        }
    }
}
