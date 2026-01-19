import SwiftUI

// MARK: - Population View
struct PopulationView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    populationOverview
                    jobAssignments
                    populationStats
                }
                .padding()
            }
            .navigationTitle("Population")
        }
    }
    
    private var populationOverview: some View {
        VStack(spacing: 16) {
            HStack {
                VStack {
                    Text("\(viewModel.village.population)")
                        .font(.system(size: 48, weight: .bold))
                    Text("Villagers")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    HStack {
                        Text("Housing:")
                        Text("\(viewModel.village.housingCapacity)")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    
                    if viewModel.village.population >= viewModel.village.housingCapacity {
                        Text("At Capacity")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Population bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                        .cornerRadius(10)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * min(1.0, Double(viewModel.village.population) / Double(max(1, viewModel.village.housingCapacity))), height: 20)
                        .cornerRadius(10)
                }
            }
            .frame(height: 20)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var jobAssignments: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Job Assignments")
                .font(.headline)
            
            let availableWorkers = viewModel.village.population - viewModel.village.guards - viewModel.village.scientists - viewModel.village.farmers
            
            Text("\(availableWorkers) workers available")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Guards
            JobSlider(
                title: "Guards",
                icon: "shield.fill",
                color: .purple,
                value: viewModel.village.guards,
                maxValue: viewModel.village.population,
                description: "Protect against raids",
                warning: viewModel.village.isPoliceState ? "High guard ratio affects morale" : nil
            ) { newValue in
                viewModel.assignGuards(newValue)
            }
            
            // Scientists (if unlocked)
            if viewModel.village.hasDiscovery(.scholars) {
                JobSlider(
                    title: "Scientists",
                    icon: "brain.head.profile",
                    color: .blue,
                    value: viewModel.village.scientists,
                    maxValue: viewModel.village.population,
                    description: "Research new discoveries"
                ) { newValue in
                    viewModel.assignScientists(newValue)
                }
            }
            
            // Farmers
            JobSlider(
                title: "Farmers",
                icon: "leaf.fill",
                color: .green,
                value: viewModel.village.farmers,
                maxValue: viewModel.village.population,
                description: "Boost food production"
            ) { newValue in
                viewModel.assignFarmers(newValue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var populationStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
            
            StatRow(label: "Birth Rate", value: birthRateDescription)
            StatRow(label: "Production Bonus", value: "\(Int(viewModel.village.populationProductionBonus * 100))%")
            StatRow(label: "Guard Protection", value: "\(Int(viewModel.village.guardProtection * 100))%")
            
            if viewModel.village.isPoliceState {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Police state: Morale affected")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var birthRateDescription: String {
        if viewModel.village.population >= viewModel.village.housingCapacity {
            return "At capacity"
        } else if viewModel.village.health < 50 {
            return "Low (poor health)"
        } else if !viewModel.village.hasFoodSurplus {
            return "Low (food shortage)"
        } else {
            return "Normal"
        }
    }
}

// MARK: - Job Slider
struct JobSlider: View {
    let title: String
    let icon: String
    let color: Color
    let value: Int
    let maxValue: Int
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
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(value)")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            Slider(value: $sliderValue, in: 0...Double(maxValue), step: 1) { editing in
                if !editing {
                    onChange(Int(sliderValue))
                }
            }
            .tint(color)
            .onAppear { sliderValue = Double(value) }
            .onChange(of: value) { oldValue, newValue in
                sliderValue = Double(newValue)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let warning = warning {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(warning)
                        .font(.caption)
                }
                .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - Threats View
struct ThreatsView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    threatStatus
                    defenseOverview
                    threatHistory
                }
                .padding()
            }
            .navigationTitle("Threats")
        }
    }
    
    private var threatStatus: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Threat Level")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(viewModel.village.currentThreatPhase.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(threatColor)
                }
                
                Spacer()
                
                threatIcon
                    .font(.system(size: 50))
                    .foregroundColor(threatColor)
            }
            
            if viewModel.village.currentThreatPhase != .none {
                VStack(alignment: .leading, spacing: 8) {
                    if let faction = viewModel.village.threatFaction {
                        HStack {
                            Text("Faction:")
                            Text(faction.rawValue)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        
                        Text(faction.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    threatPhaseDescription
                }
            } else {
                Text("No immediate threats detected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(threatColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var threatIcon: some View {
        switch viewModel.village.currentThreatPhase {
        case .none: return Image(systemName: "checkmark.shield.fill")
        case .rumors: return Image(systemName: "eye.fill")
        case .scouts: return Image(systemName: "binoculars.fill")
        case .raidImminent: return Image(systemName: "flame.fill")
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
    
    @ViewBuilder
    private var threatPhaseDescription: some View {
        switch viewModel.village.currentThreatPhase {
        case .none:
            EmptyView()
        case .rumors:
            Text("Rumors speak of hostile activity. Consider strengthening defenses.")
                .font(.caption)
                .foregroundColor(.secondary)
        case .scouts:
            Text("Enemy scouts have been spotted. A raid may be coming.")
                .font(.caption)
                .foregroundColor(.orange)
        case .raidImminent:
            Text("An attack is imminent! Prepare your defenses!")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.red)
        }
    }
    
    private var defenseOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Defense Rating")
                .font(.headline)
            
            HStack {
                Text("\(Int(viewModel.village.totalDefenseRating * 100))%")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.purple)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Damage Reduction")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Against raids")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Defense bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 16)
                        .cornerRadius(8)
                    
                    Rectangle()
                        .fill(Color.purple)
                        .frame(width: geometry.size.width * viewModel.village.totalDefenseRating, height: 16)
                        .cornerRadius(8)
                }
            }
            .frame(height: 16)
            
            Divider()
            
            // Breakdown
            VStack(alignment: .leading, spacing: 8) {
                DefenseBreakdownRow(
                    label: "Guards",
                    value: viewModel.village.guardProtection,
                    icon: "shield.fill"
                )
                
                let defenseBuildings = viewModel.village.buildings.filter {
                    [.watchtower, .palisade, .stoneWall].contains($0.type) && !$0.isUnderConstruction
                }
                
                ForEach(defenseBuildings) { building in
                    DefenseBreakdownRow(
                        label: building.name,
                        value: building.defenseBonus() * (building.type == .stoneWall ? 2.0 : (building.type == .palisade ? 1.5 : 1.0)),
                        icon: building.type == .watchtower ? "eye.fill" : "brick.fill"
                    )
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var threatHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(viewModel.village.raidsRepelled)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Repelled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(viewModel.village.raidsSuffered)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("Suffered")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Wealth Rating")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(viewModel.village.perceivedWealth))")
                        .font(.headline)
                }
            }
            
            Text("Higher wealth attracts more raiders")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Defense Breakdown Row
struct DefenseBreakdownRow: View {
    let label: String
    let value: Double
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text("+\(Int(value * 100))%")
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Chronicle View
struct ChronicleView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredEntries) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(entry.title)
                                .font(.headline)
                            Spacer()
                            Text(entry.displayDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(entry.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Chronicle")
            .searchable(text: $searchText, prompt: "Search history")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(viewModel.village.yearsSurvived) years")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var filteredEntries: [ChronicleEntry] {
        let entries = viewModel.village.chronicle.reversed()
        if searchText.isEmpty {
            return Array(entries)
        }
        return entries.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
}
