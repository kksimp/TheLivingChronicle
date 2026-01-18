import SwiftUI

// MARK: - App Entry Point
@main
struct VillageGameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
    }
}

// MARK: - Content View
struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.village.isExtinct {
                    ExtinctionView(viewModel: viewModel)
                } else {
                    MainGameView(viewModel: viewModel, screenSize: geometry.size)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "hourglass")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(rotation))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: rotation)
                
                Text("Processing time away...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .onAppear { rotation = 360 }
    }
}

// MARK: - Main Game View (Clash of Clans / Plague Inc Style)
struct MainGameView: View {
    @ObservedObject var viewModel: GameViewModel
    let screenSize: CGSize
    
    var body: some View {
        ZStack {
            // Background Map (always visible)
            VillageMapView(viewModel: viewModel)
                .ignoresSafeArea()
            
            // HUD Overlay
            HUDOverlay(viewModel: viewModel, screenSize: screenSize)
            
            // Slide-in Panel
            if let panel = viewModel.selectedPanel {
                SlidePanelView(viewModel: viewModel, panel: panel, screenSize: screenSize)
                    .transition(.move(edge: .trailing))
            }
            
            // Build Menu (bottom sheet style)
            if viewModel.showingBuildMenu {
                BuildMenuOverlay(viewModel: viewModel, screenSize: screenSize)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.selectedPanel)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.showingBuildMenu)
        .sheet(item: $viewModel.showingEvent) { event in
            EventView(event: event, viewModel: viewModel)
                .presentationDetents([.medium])
        }
    }
}

// MARK: - HUD Overlay (Always Visible)
struct HUDOverlay: View {
    @ObservedObject var viewModel: GameViewModel
    let screenSize: CGSize
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            topBar
            
            HStack(spacing: 0) {
                // Left Side - Resource Panel
                leftResourcePanel
                
                Spacer()
                
                // Right Side - Menu Buttons
                rightMenuButtons
            }
            
            Spacer()
            
            // Bottom Bar
            bottomBar
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 12) {
            // Village Name & Era
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.village.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(viewModel.village.currentEra.name)")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.6))
                    .overlay(Capsule().stroke(Color.yellow.opacity(0.5), lineWidth: 1))
            )
            
            Spacer()
            
            // Season & Year
            HStack(spacing: 8) {
                seasonIcon
                    .font(.system(size: 18))
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.village.currentSeason.name)
                        .font(.system(size: 12, weight: .semibold))
                    Text("Year \(viewModel.village.gameYear)")
                        .font(.system(size: 10))
                        .opacity(0.8)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(seasonColor.opacity(0.8))
                    .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
            )
            
            // Weather
            weatherBadge
            
            // Guild Marks (Premium Currency)
            HStack(spacing: 4) {
                Image(systemName: "seal.fill")
                    .foregroundColor(.yellow)
                Text("\(viewModel.village.resources.guildMarks)")
                    .font(.system(size: 14, weight: .bold))
                
                Button(action: { viewModel.watchAdForGuildMarks() }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.6))
                    .overlay(Capsule().stroke(Color.yellow, lineWidth: 1))
            )
        }
        .padding(.top, 8)
    }
    
    private var seasonIcon: some View {
        let icon: String
        switch viewModel.village.currentSeason {
        case .spring: icon = "leaf.fill"
        case .summer: icon = "sun.max.fill"
        case .fall: icon = "wind"
        case .winter: icon = "snowflake"
        }
        return Image(systemName: icon)
    }
    
    private var seasonColor: Color {
        switch viewModel.village.currentSeason {
        case .spring: return .green
        case .summer: return .orange
        case .fall: return .brown
        case .winter: return .cyan
        }
    }
    
    private var weatherBadge: some View {
        let icon: String
        let color: Color
        
        switch viewModel.village.currentWeather {
        case .weak:
            icon = "sun.max.fill"
            color = .yellow
        case .mild:
            icon = "cloud.sun.fill"
            color = .gray
        case .heavy:
            icon = "cloud.rain.fill"
            color = .blue
        case .dangerous:
            icon = "cloud.bolt.fill"
            color = .red
        }
        
        return Image(systemName: icon)
            .font(.system(size: 18))
            .foregroundColor(color)
            .padding(8)
            .background(Circle().fill(Color.black.opacity(0.5)))
    }
    
    // MARK: - Left Resource Panel
    private var leftResourcePanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            ResourceBar(icon: "leaf.fill", color: .green,
                       value: viewModel.village.foodStorage.total,
                       label: "\(Int(viewModel.village.daysOfFoodRemaining))d")
            
            ResourceBar(icon: "drop.fill", color: .blue,
                       value: viewModel.village.resources.water, label: nil)
            
            ResourceBar(icon: "flame.fill", color: .orange,
                       value: viewModel.village.resources.firewood, label: nil)
            
            ResourceBar(icon: "cube.fill", color: .gray,
                       value: viewModel.village.resources.salt, label: nil)
            
            if viewModel.village.hasDiscovery(.stoneworking) {
                ResourceBar(icon: "mountain.2.fill", color: .brown,
                           value: viewModel.village.resources.stone, label: nil)
            }
            
            if viewModel.village.resources.metal > 0 {
                ResourceBar(icon: "gearshape.fill", color: .gray,
                           value: viewModel.village.resources.metal, label: nil)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
        )
        .padding(.top, 8)
    }
    
    // MARK: - Right Menu Buttons
    private var rightMenuButtons: some View {
        VStack(spacing: 8) {
            MenuButton(icon: "hammer.fill", color: .blue, badge: viewModel.village.availableBuilders > 0 ? "\(viewModel.village.availableBuilders)" : nil) {
                viewModel.showingBuildMenu = true
            }
            
            MenuButton(icon: "person.3.fill", color: .green, badge: nil) {
                viewModel.selectedPanel = .population
            }
            
            MenuButton(icon: "shield.fill", color: threatColor, badge: viewModel.village.currentThreatPhase != .none ? "!" : nil) {
                viewModel.selectedPanel = .threats
            }
            
            if viewModel.village.hasDiscovery(.scholars) {
                MenuButton(icon: "lightbulb.fill", color: .purple, badge: nil) {
                    viewModel.selectedPanel = .research
                }
            }
            
            MenuButton(icon: "book.fill", color: .brown, badge: nil) {
                viewModel.selectedPanel = .chronicle
            }
            
            MenuButton(icon: "gear", color: .gray, badge: nil) {
                viewModel.selectedPanel = .settings
            }
        }
        .padding(.top, 8)
    }
    
    private var threatColor: Color {
        switch viewModel.village.currentThreatPhase {
        case .none: return .gray
        case .rumors: return .yellow
        case .scouts: return .orange
        case .raidImminent: return .red
        }
    }
    
    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack(spacing: 16) {
            // Population
            StatPill(icon: "person.3.fill", value: "\(viewModel.village.population)/\(viewModel.village.housingCapacity)", color: .blue)
            
            // Health
            StatPill(icon: "heart.fill", value: "\(Int(viewModel.village.health))%", color: healthColor)
            
            // Morale
            StatPill(icon: "face.smiling.fill", value: "\(Int(viewModel.village.morale))%", color: moraleColor)
            
            // Panic
            if viewModel.village.panic > 10 {
                StatPill(icon: "exclamationmark.triangle.fill", value: "\(Int(viewModel.village.panic))%", color: panicColor)
            }
            
            Spacer()
            
            // Threat indicator
            if viewModel.village.currentThreatPhase != .none {
                ThreatPill(phase: viewModel.village.currentThreatPhase)
            }
        }
        .padding(.bottom, 8)
    }
    
    private var healthColor: Color {
        viewModel.village.health > 60 ? .green : (viewModel.village.health > 30 ? .yellow : .red)
    }
    
    private var moraleColor: Color {
        viewModel.village.morale > 60 ? .green : (viewModel.village.morale > 30 ? .yellow : .orange)
    }
    
    private var panicColor: Color {
        viewModel.village.panic < 30 ? .yellow : (viewModel.village.panic < 60 ? .orange : .red)
    }
}

// MARK: - Resource Bar
struct ResourceBar: View {
    let icon: String
    let color: Color
    let value: Double
    let label: String?
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
                .frame(width: 16)
            
            Text("\(Int(value))")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 40, alignment: .leading)
            
            if let label = label {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

// MARK: - Menu Button
struct MenuButton: View {
    let icon: String
    let color: Color
    let badge: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color.opacity(0.8))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.3), lineWidth: 1))
                            .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 2)
                    )
                
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Circle().fill(Color.red))
                        .offset(x: 4, y: -4)
                }
            }
        }
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
                .overlay(Capsule().stroke(color.opacity(0.5), lineWidth: 1))
        )
    }
}

// MARK: - Threat Pill
struct ThreatPill: View {
    let phase: ThreatPhase
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: phaseIcon)
                .font(.system(size: 14))
            
            Text(phase.name)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(phaseColor)
                .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
        )
    }
    
    private var phaseIcon: String {
        switch phase {
        case .none: return "checkmark.shield"
        case .rumors: return "eye"
        case .scouts: return "binoculars"
        case .raidImminent: return "flame.fill"
        }
    }
    
    private var phaseColor: Color {
        switch phase {
        case .none: return .green
        case .rumors: return .yellow
        case .scouts: return .orange
        case .raidImminent: return .red
        }
    }
}

// MARK: - Slide Panel View
struct SlidePanelView: View {
    @ObservedObject var viewModel: GameViewModel
    let panel: GamePanel
    let screenSize: CGSize
    
    var body: some View {
        HStack(spacing: 0) {
            // Dimmed background tap to close
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.selectedPanel = nil
                }
            
            // Panel content
            VStack(spacing: 0) {
                // Header
                panelHeader
                
                // Content
                ScrollView {
                    panelContent
                        .padding()
                }
            }
            .frame(width: min(400, screenSize.width * 0.45))
            .background(Color(red: 0.15, green: 0.15, blue: 0.2))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.5), radius: 20, x: -5, y: 0)
            .padding(.vertical, 20)
            .padding(.trailing, 10)
        }
    }
    
    private var panelHeader: some View {
        HStack {
            Image(systemName: panel.icon)
                .font(.title2)
            Text(panel.rawValue)
                .font(.title2.bold())
            Spacer()
            Button(action: { viewModel.selectedPanel = nil }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.black.opacity(0.3))
    }
    
    @ViewBuilder
    private var panelContent: some View {
        switch panel {
        case .buildings:
            BuildingsPanelContent(viewModel: viewModel)
        case .population:
            PopulationPanelContent(viewModel: viewModel)
        case .threats:
            ThreatsPanelContent(viewModel: viewModel)
        case .research:
            ResearchPanelContent(viewModel: viewModel)
        case .chronicle:
            ChroniclePanelContent(viewModel: viewModel)
        case .settings:
            SettingsPanelContent(viewModel: viewModel)
        }
    }
}

// MARK: - Panel Contents

struct BuildingsPanelContent: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Buildings")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(BuildingCategory.allCases, id: \.self) { category in
                let buildings = viewModel.village.buildings.filter { $0.category == category }
                if !buildings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category.rawValue)
                            .font(.subheadline.bold())
                            .foregroundColor(.gray)
                        
                        ForEach(buildings) { building in
                            CompactBuildingRow(building: building, viewModel: viewModel)
                        }
                    }
                }
            }
        }
    }
}

struct CompactBuildingRow: View {
    let building: Building
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(building.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text("Level \(building.level)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if building.isUnderConstruction {
                Image(systemName: "hammer.fill")
                    .foregroundColor(.orange)
            } else if building.isDamaged {
                Button("Repair") {
                    viewModel.repair(building)
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .tint(.orange)
            } else if viewModel.canUpgrade(building) {
                Button("Upgrade") {
                    viewModel.upgrade(building)
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .tint(.blue)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

struct PopulationPanelContent: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Overview
            VStack(alignment: .leading, spacing: 8) {
                Text("Population: \(viewModel.village.population) / \(viewModel.village.housingCapacity)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ProgressView(value: Double(viewModel.village.population), total: Double(max(1, viewModel.village.housingCapacity)))
                    .tint(.blue)
            }
            
            Divider().background(Color.gray)
            
            // Job Assignments
            Text("Job Assignments")
                .font(.headline)
                .foregroundColor(.white)
            
            let availableWorkers = viewModel.village.population - viewModel.village.guards - viewModel.village.scientists - viewModel.village.farmers
            
            Text("\(availableWorkers) idle workers")
                .font(.caption)
                .foregroundColor(.gray)
            
            JobAssignmentRow(
                title: "Guards",
                icon: "shield.fill",
                color: .purple,
                value: viewModel.village.guards,
                max: viewModel.village.population,
                description: "Protect against raids",
                warning: viewModel.village.isPoliceState ? "Police state!" : nil
            ) { newValue in
                viewModel.assignGuards(newValue)
            }
            
            if viewModel.village.hasDiscovery(.scholars) {
                JobAssignmentRow(
                    title: "Scientists",
                    icon: "brain.head.profile",
                    color: .blue,
                    value: viewModel.village.scientists,
                    max: viewModel.village.population,
                    description: "Research discoveries"
                ) { newValue in
                    viewModel.assignScientists(newValue)
                }
            }
            
            JobAssignmentRow(
                title: "Farmers",
                icon: "leaf.fill",
                color: .green,
                value: viewModel.village.farmers,
                max: viewModel.village.population,
                description: "Boost food production"
            ) { newValue in
                viewModel.assignFarmers(newValue)
            }
        }
    }
}

struct JobAssignmentRow: View {
    let title: String
    let icon: String
    let color: Color
    let value: Int
    let max: Int
    let description: String
    var warning: String? = nil
    let onChange: (Int) -> Void
    
    @State private var sliderValue: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Spacer()
                Text("\(value)")
                    .font(.headline)
                    .foregroundColor(color)
            }
            
            Slider(value: $sliderValue, in: 0...Double(max), step: 1) { editing in
                if !editing {
                    onChange(Int(sliderValue))
                }
            }
            .tint(color)
            .onAppear { sliderValue = Double(value) }
            .onChange(of: value) { _, newValue in
                sliderValue = Double(newValue)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.gray)
            
            if let warning = warning {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(warning)
                }
                .font(.caption)
                .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct ThreatsPanelContent: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Threat Status
            HStack {
                VStack(alignment: .leading) {
                    Text("Threat Level")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(viewModel.village.currentThreatPhase.name)
                        .font(.title2.bold())
                        .foregroundColor(threatColor)
                }
                Spacer()
                Image(systemName: threatIcon)
                    .font(.system(size: 40))
                    .foregroundColor(threatColor)
            }
            .padding()
            .background(threatColor.opacity(0.2))
            .cornerRadius(12)
            
            // Defense Rating
            VStack(alignment: .leading, spacing: 8) {
                Text("Defense Rating")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    Text("\(Int(viewModel.village.totalDefenseRating * 100))%")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.purple)
                    
                    Spacer()
                    
                    Text("Damage Reduction")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                ProgressView(value: viewModel.village.totalDefenseRating)
                    .tint(.purple)
            }
            
            Divider().background(Color.gray)
            
            // Stats
            HStack(spacing: 20) {
                VStack {
                    Text("\(viewModel.village.raidsRepelled)")
                        .font(.title2.bold())
                        .foregroundColor(.green)
                    Text("Repelled")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Text("\(viewModel.village.raidsSuffered)")
                        .font(.title2.bold())
                        .foregroundColor(.red)
                    Text("Suffered")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(viewModel.village.perceivedWealth))")
                        .font(.title2.bold())
                        .foregroundColor(.yellow)
                    Text("Wealth")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private var threatColor: Color {
        switch viewModel.village.currentThreatPhase {
        case .none: return .green
        case .rumors: return .yellow
        case .scouts: return .orange
        case .raidImminent: return .red
        }
    }
    
    private var threatIcon: String {
        switch viewModel.village.currentThreatPhase {
        case .none: return "checkmark.shield.fill"
        case .rumors: return "eye.fill"
        case .scouts: return "binoculars.fill"
        case .raidImminent: return "flame.fill"
        }
    }
}

struct ResearchPanelContent: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(.purple)
                Text("Knowledge: \(Int(viewModel.village.resources.knowledge))")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text("Available Discoveries")
                .font(.subheadline.bold())
                .foregroundColor(.gray)
            
            ForEach(availableDiscoveries, id: \.self) { discovery in
                DiscoveryRow(discovery: discovery, village: viewModel.village)
            }
            
            if availableDiscoveries.isEmpty {
                Text("Research more to unlock new discoveries!")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
    
    private var availableDiscoveries: [Discovery] {
        Discovery.allCases.filter { discovery in
            !viewModel.village.hasDiscovery(discovery) &&
            viewModel.village.discoveryState.canUnlock(discovery)
        }
    }
}

struct DiscoveryRow: View {
    let discovery: Discovery
    let village: Village
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(discovery.name)
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            Text(discovery.description)
                .font(.caption)
                .foregroundColor(.gray)
            
            if discovery.baseKnowledgeCost > 0 {
                HStack {
                    Image(systemName: "book.fill")
                        .font(.caption)
                    Text("\(Int(discovery.baseKnowledgeCost)) knowledge required")
                        .font(.caption)
                }
                .foregroundColor(village.resources.knowledge >= discovery.baseKnowledgeCost ? .green : .red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

struct ChroniclePanelContent: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Village History")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Survived \(viewModel.village.yearsSurvived) years")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ForEach(viewModel.village.chronicle.suffix(20).reversed()) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.title)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Spacer()
                        Text(entry.displayDate)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text(entry.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(10)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
}

struct SettingsPanelContent: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showingNewGameAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Game Settings")
                .font(.headline)
                .foregroundColor(.white)
            
            // Save info
            VStack(alignment: .leading, spacing: 4) {
                Text("Auto-save enabled")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("Game saves automatically every minute")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            
            // Manual save
            Button(action: { viewModel.forceSave() }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save Now")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            
            Divider().background(Color.gray)
            
            // New game
            Button(action: { showingNewGameAlert = true }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Start New Game")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .alert("Start New Game?", isPresented: $showingNewGameAlert) {
                Button("Cancel", role: .cancel) { }
                Button("New Game", role: .destructive) {
                    viewModel.startNewGame(name: "New Settlement")
                    viewModel.selectedPanel = nil
                }
            } message: {
                Text("This will erase your current village. Are you sure?")
            }
        }
    }
}

// MARK: - Build Menu Overlay
struct BuildMenuOverlay: View {
    @ObservedObject var viewModel: GameViewModel
    let screenSize: CGSize
    @State private var selectedCategory: BuildingCategory = .housing
    
    var body: some View {
        VStack(spacing: 0) {
            // Tap to close
            Color.black.opacity(0.3)
                .onTapGesture {
                    viewModel.showingBuildMenu = false
                }
            
            // Build menu
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Build")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "hammer.fill")
                        Text("\(viewModel.village.availableBuilders) builders")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    
                    Button(action: { viewModel.showingBuildMenu = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                
                // Category tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(BuildingCategory.allCases, id: \.self) { category in
                            CategoryTab(category: category, isSelected: selectedCategory == category) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Building options
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(availableBuildings, id: \.self) { type in
                            BuildOptionCard(type: type, viewModel: viewModel) {
                                viewModel.build(type)
                            }
                        }
                        
                        if availableBuildings.isEmpty {
                            Text("No buildings available.\nUnlock through discoveries!")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .frame(width: 150)
                        }
                    }
                    .padding()
                }
            }
            .frame(height: 280)
            .background(Color(red: 0.15, green: 0.15, blue: 0.2))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .ignoresSafeArea()
    }
    
    private var availableBuildings: [BuildingType] {
        BuildingType.allCases.filter { type in
            type.category == selectedCategory && viewModel.village.canBuild(type)
        }
    }
}

struct CategoryTab: View {
    let category: BuildingCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.subheadline.bold())
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.clear)
                )
        }
    }
}

struct BuildOptionCardView: View {
    let type: BuildingType
    @ObservedObject var viewModel: GameViewModel
    let onBuild: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Building icon
            Image(systemName: buildingIcon)
                .font(.system(size: 30))
                .foregroundColor(categoryColor)
                .frame(width: 60, height: 60)
                .background(categoryColor.opacity(0.2))
                .cornerRadius(12)
            
            Text(type.name)
                .font(.caption.bold())
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Cost
            HStack(spacing: 4) {
                if type.baseCost.food > 0 {
                    CostIcon(icon: "leaf.fill", value: Int(type.baseCost.food), canAfford: viewModel.village.foodStorage.total >= type.baseCost.food)
                }
                if type.baseCost.firewood > 0 {
                    CostIcon(icon: "flame.fill", value: Int(type.baseCost.firewood), canAfford: viewModel.village.resources.firewood >= type.baseCost.firewood)
                }
                if type.baseCost.stone > 0 {
                    CostIcon(icon: "cube.fill", value: Int(type.baseCost.stone), canAfford: viewModel.village.resources.stone >= type.baseCost.stone)
                }
            }
            
            Button(action: onBuild) {
                Text("Build")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(viewModel.canBuild(type) ? Color.green : Color.gray)
                    .cornerRadius(8)
            }
            .disabled(!viewModel.canBuild(type))
        }
        .frame(width: 120)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var buildingIcon: String {
        switch type.category {
        case .housing: return "house.fill"
        case .production: return "gearshape.2.fill"
        case .storage: return "archivebox.fill"
        case .defense: return "shield.fill"
        case .special: return "star.fill"
        }
    }
    
    private var categoryColor: Color {
        switch type.category {
        case .housing: return .blue
        case .production: return .green
        case .storage: return .orange
        case .defense: return .purple
        case .special: return .yellow
        }
    }
}

struct CostIcon: View {
    let icon: String
    let value: Int
    let canAfford: Bool
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text("\(value)")
                .font(.system(size: 10))
        }
        .foregroundColor(canAfford ? .white : .red)
    }
}

// MARK: - Extinction View
struct ExtinctionView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showingNewGame = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            HStack(spacing: 40) {
                // Left side - info
                VStack(spacing: 20) {
                    Image(systemName: "leaf.arrow.triangle.circlepath")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    Text(viewModel.village.name)
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    
                    Text("Year \(viewModel.village.gameYear)")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("Survived \(viewModel.village.yearsSurvived) years")
                        .foregroundColor(.gray)
                }
                
                // Right side - actions
                VStack(spacing: 16) {
                    Button(action: { viewModel.watchAdsForContinue() }) {
                        Label("Continue (3 Ads)", systemImage: "play.circle.fill")
                            .frame(width: 200)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    Button(action: { viewModel.startLegacyGame(from: viewModel.village) }) {
                        Label("Legacy Mode (1 Ad)", systemImage: "arrow.triangle.2.circlepath")
                            .frame(width: 200)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button(action: { showingNewGame = true }) {
                        Label("Start Fresh", systemImage: "plus.circle.fill")
                            .frame(width: 200)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(40)
        }
        .sheet(isPresented: $showingNewGame) {
            NewGameView(viewModel: viewModel)
        }
    }
}

// MARK: - New Game View
struct NewGameView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    @State private var villageName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Village Name") {
                    TextField("Enter name", text: $villageName)
                }
                
                Section {
                    Button("Create Village") {
                        let name = villageName.isEmpty ? "New Settlement" : villageName
                        viewModel.startNewGame(name: name)
                        dismiss()
                    }
                }
            }
            .navigationTitle("New Game")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Event View
struct EventView: View {
    let event: GameEvent
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: eventIcon)
                .font(.system(size: 50))
                .foregroundColor(severityColor)
            
            Text(event.title)
                .font(.title2.bold())
            
            Text("\(event.season.name), Year \(event.year)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(event.message)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            if let choices = event.choices, !choices.isEmpty {
                ForEach(choices) { choice in
                    Button(action: {
                        viewModel.selectChoice(choice)
                        dismiss()
                    }) {
                        VStack {
                            Text(choice.label).font(.headline)
                            Text(choice.description).font(.caption).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
            } else {
                Button("Continue") {
                    viewModel.acknowledgeEvent()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    private var eventIcon: String {
        switch event.type {
        case .raid, .threatRumor, .threatScout: return "flame.fill"
        case .raidRepelled: return "shield.fill"
        case .bountifulHarvest: return "leaf.fill"
        case .diseaseOutbreak: return "cross.fill"
        case .discoveryMade: return "lightbulb.fill"
        default: return "bell.fill"
        }
    }
    
    private var severityColor: Color {
        switch event.type.severity {
        case .critical: return .red
        case .warning: return .orange
        case .notice: return .yellow
        case .positive: return .green
        case .info: return .blue
        }
    }
}

#Preview {
    ContentView()
}
