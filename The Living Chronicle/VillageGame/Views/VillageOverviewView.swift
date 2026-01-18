import SwiftUI

// MARK: - Village Overview View
struct VillageOverviewView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    statsGrid
                    resourcesSection

                    if !viewModel.pendingEvents.isEmpty {
                        alertsSection
                    }

                    quickActionsSection
                }
                .padding()
            }
            .navigationTitle(viewModel.village.name)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(viewModel.village.currentSeason.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Year \(viewModel.village.gameYear)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    weatherIcon.font(.title)
                    Text(viewModel.village.currentWeather.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Text("Era: \(viewModel.village.currentEra.name)")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(eraColor.opacity(0.2))
                    .foregroundColor(eraColor)
                    .cornerRadius(8)

                Spacer()

                if viewModel.village.isLegacyMode {
                    Text("Legacy")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var weatherIcon: some View {
        let iconName: String
        let color: Color

        switch (viewModel.village.currentSeason, viewModel.village.currentWeather) {
        case (_, .dangerous):
            iconName = viewModel.village.currentSeason == .winter ? "cloud.snow.fill" : "sun.max.fill"
            color = .red
        case (_, .heavy):
            iconName = "cloud.bolt.rain.fill"
            color = .blue
        case (.winter, _):
            iconName = "snowflake"
            color = .cyan
        case (.summer, .weak):
            iconName = "sun.max.fill"
            color = .orange
        default:
            iconName = "cloud.sun.fill"
            color = .yellow
        }

        return Image(systemName: iconName).foregroundColor(color)
    }

    private var eraColor: Color {
        switch viewModel.village.currentEra {
        case .founding: return .brown
        case .earlySettlement: return .green
        case .organizedVillage: return .blue
        case .structuredSociety: return .purple
        case .earlyScience: return .orange
        case .medicalRevolution: return .red
        case .industrialTransition: return .gray
        case .modernization: return .cyan
        case .enlightenment: return .yellow
        @unknown default: return .gray
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Population",
                value: "\(viewModel.village.population)",
                subtitle: "Max: \(viewModel.village.housingCapacity)",
                icon: "person.3.fill",
                color: .blue
            )

            StatCard(
                title: "Health",
                value: "\(Int(viewModel.village.health))%",
                subtitle: healthStatus,
                icon: "heart.fill",
                color: healthColor
            )

            StatCard(
                title: "Morale",
                value: "\(Int(viewModel.village.morale))%",
                subtitle: moraleStatus,
                icon: "face.smiling.fill",
                color: moraleColor
            )

            StatCard(
                title: "Panic",
                value: "\(Int(viewModel.village.panic))%",
                subtitle: panicStatus,
                icon: "exclamationmark.triangle.fill",
                color: panicColor
            )
        }
    }

    private var healthStatus: String {
        let h = viewModel.village.health
        switch h {
        case 80.0...100.0: return "Excellent"
        case 60.0..<80.0:  return "Good"
        case 40.0..<60.0:  return "Fair"
        case 20.0..<40.0:  return "Poor"
        default:           return "Critical"
        }
    }

    private var healthColor: Color {
        viewModel.village.health >= 60 ? .green : (viewModel.village.health >= 40 ? .yellow : .red)
    }

    private var moraleStatus: String {
        let m = viewModel.village.morale
        return m >= 70 ? "Happy" : (m >= 50 ? "Content" : "Unhappy")
    }

    private var moraleColor: Color {
        viewModel.village.morale >= 60 ? .green : (viewModel.village.morale >= 40 ? .yellow : .orange)
    }

    private var panicStatus: String {
        let p = viewModel.village.panic
        return p < 20 ? "Calm" : (p < 50 ? "Uneasy" : "Fearful")
    }

    private var panicColor: Color {
        viewModel.village.panic < 30 ? .green : (viewModel.village.panic < 60 ? .orange : .red)
    }

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resources").font(.headline)

            ResourceRow(
                name: "Food",
                value: Int(viewModel.village.foodStorage.total),
                icon: "leaf.fill",
                color: .green,
                subtitle: "\(Int(viewModel.village.daysOfFoodRemaining)) days"
            )

            ResourceRow(name: "Water",    value: Int(viewModel.village.resources.water),    icon: "drop.fill",       color: .blue)
            ResourceRow(name: "Firewood", value: Int(viewModel.village.resources.firewood), icon: "flame.fill",      color: .orange)
            ResourceRow(name: "Salt",     value: Int(viewModel.village.resources.salt),     icon: "cube.fill",       color: .gray)
            ResourceRow(name: "Stone",    value: Int(viewModel.village.resources.stone),    icon: "mountain.2.fill", color: .brown)
            ResourceRow(name: "Metal",    value: Int(viewModel.village.resources.metal),    icon: "gearshape.fill",  color: .gray)

            if viewModel.village.hasDiscovery(.scholars) {
                ResourceRow(
                    name: "Knowledge",
                    value: Int(viewModel.village.resources.knowledge),
                    icon: "book.fill",
                    color: .purple
                )
            }

            Divider()

            HStack {
                Image(systemName: "seal.fill").foregroundColor(.yellow)
                Text("Guild Marks")
                Spacer()
                Text("\(viewModel.village.resources.guildMarks)")
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Alerts").font(.headline)

            ForEach(Array(viewModel.pendingEvents.prefix(3))) { event in
                HStack {
                    Circle()
                        .fill(event.type.severity == .critical ? Color.red : .orange)
                        .frame(width: 8, height: 8)

                    Text(event.title).font(.subheadline)

                    Spacer()

                    if event.requiresChoice {
                        Text("Action needed").font(.caption).foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .onTapGesture { viewModel.showNextEvent() }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions").font(.headline)

            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Build",
                    icon: "hammer.fill",
                    color: .blue,
                    badge: viewModel.village.availableBuilders > 0 ? "\(viewModel.village.availableBuilders)" : nil
                ) {
                    viewModel.selectedTab = .buildings
                }

                QuickActionButton(title: "Jobs", icon: "person.badge.plus", color: .green) {
                    viewModel.selectedTab = .population
                }

                QuickActionButton(
                    title: "Threats",
                    icon: "shield.fill",
                    color: viewModel.village.currentThreatPhase == .none ? .gray : .orange,
                    badge: viewModel.village.currentThreatPhase != .none ? "!" : nil
                ) {
                    viewModel.selectedTab = .threats
                }

                QuickActionButton(
                    title: "Research",
                    icon: "lightbulb.fill",
                    color: .purple,
                    disabled: !viewModel.village.hasDiscovery(.scholars)
                ) {
                    viewModel.showingDiscoveries = true
                }
            }
        }
    }
}

// MARK: - Components

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Text(title).font(.caption).foregroundColor(.secondary)
            }
            Text(value).font(.title2).fontWeight(.bold)
            Text(subtitle).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ResourceRow: View {
    let name: String
    let value: Int
    let icon: String
    let color: Color
    var subtitle: String? = nil

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color).frame(width: 24)
            Text(name)
            Spacer()
            if let subtitle = subtitle {
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            Text("\(value)")
                .fontWeight(.semibold)
                .frame(width: 60, alignment: .trailing)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var badge: String? = nil
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(disabled ? .gray : color)

                    if let badge = badge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 8, y: -4)
                    }
                }

                Text(title)
                    .font(.caption)
                    .foregroundColor(disabled ? .gray : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .disabled(disabled)
    }
}
