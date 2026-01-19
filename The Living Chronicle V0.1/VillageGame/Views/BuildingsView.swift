import SwiftUI

// MARK: - Buildings View
struct BuildingsView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var selectedCategory: BuildingCategory = .housing
    @State private var showingBuildSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category picker
                categoryPicker
                
                // Buildings list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Under construction
                        let constructing = viewModel.village.buildings.filter { $0.isUnderConstruction && $0.category == selectedCategory }
                        if !constructing.isEmpty {
                            Section {
                                ForEach(constructing) { building in
                                    ConstructionCard(building: building, viewModel: viewModel)
                                }
                            } header: {
                                SectionHeader(title: "Under Construction")
                            }
                        }
                        
                        // Completed buildings
                        let completed = viewModel.village.buildings.filter { !$0.isUnderConstruction && $0.category == selectedCategory }
                        if !completed.isEmpty {
                            Section {
                                ForEach(completed) { building in
                                    BuildingCard(building: building, viewModel: viewModel)
                                }
                            } header: {
                                SectionHeader(title: "Completed")
                            }
                        }
                        
                        if constructing.isEmpty && completed.isEmpty {
                            emptyState
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Buildings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingBuildSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(viewModel.village.availableBuilders == 0)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Image(systemName: "hammer.fill")
                        Text("\(viewModel.village.availableBuilders)/\(viewModel.village.builders)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $showingBuildSheet) {
                BuildMenuView(viewModel: viewModel, category: selectedCategory)
            }
        }
    }
    
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BuildingCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        count: viewModel.village.buildings.filter { $0.category == category }.count
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding()
        }
        .background(Color.gray.opacity(0.05))
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No \(selectedCategory.rawValue) Buildings")
                .font(.headline)
            
            Text("Tap + to build new structures")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if viewModel.village.availableBuilders == 0 {
                Text("All builders are busy")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let category: BuildingCategory
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: categoryIcon)
                    .font(.title3)
                
                Text(category.rawValue)
                    .font(.caption)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(10)
        }
    }
    
    private var categoryIcon: String {
        switch category {
        case .housing: return "house.fill"
        case .production: return "gearshape.2.fill"
        case .storage: return "archivebox.fill"
        case .defense: return "shield.fill"
        case .special: return "star.fill"
        }
    }
}

// MARK: - Building Card
struct BuildingCard: View {
    let building: Building
    @ObservedObject var viewModel: GameViewModel
    @State private var showingActions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(building.name)
                            .font(.headline)
                        
                        if building.isDamaged {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                    
                    Text("Level \(building.level)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingActions = true }) {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            
            // Stats
            buildingStats
            
            // Damage indicator
            if building.isDamaged {
                HStack {
                    Image(systemName: "wrench.fill")
                        .foregroundColor(.orange)
                    Text("Damaged (\(Int(building.damageAmount * 100))%)")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                    Button("Repair") {
                        viewModel.repair(building)
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .confirmationDialog("Building Actions", isPresented: $showingActions) {
            if viewModel.canUpgrade(building) {
                Button("Upgrade to Level \(building.level + 1)") {
                    viewModel.upgrade(building)
                }
            }
            
            Button("Demolish", role: .destructive) {
                viewModel.demolish(building)
            }
            
            Button("Cancel", role: .cancel) { }
        }
    }
    
    @ViewBuilder
    private var buildingStats: some View {
        let production = building.type.baseProduction(level: building.level)
        
        HStack(spacing: 16) {
            if building.type.housingCapacity > 0 {
                StatBadge(icon: "person.fill", value: "\(building.housingCapacity)", color: .blue)
            }
            
            if production.foodPerTick > 0 {
                StatBadge(icon: "leaf.fill", value: "+\(String(format: "%.1f", production.foodPerTick))", color: .green)
            }
            
            if production.waterPerTick > 0 {
                StatBadge(icon: "drop.fill", value: "+\(String(format: "%.1f", production.waterPerTick))", color: .blue)
            }
            
            if production.firewoodPerTick > 0 {
                StatBadge(icon: "flame.fill", value: "+\(String(format: "%.1f", production.firewoodPerTick))", color: .orange)
            }
            
            if building.type == .watchtower || building.type == .palisade || building.type == .stoneWall {
                StatBadge(icon: "shield.fill", value: "+\(Int(building.defenseBonus() * 100))%", color: .purple)
            }
        }
    }
}

// MARK: - Construction Card
struct ConstructionCard: View {
    let building: Building
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.headline)
                    
                    Text(building.level == 0 ? "Building..." : "Upgrading to Level \(building.level + 1)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "hammer.fill")
                    .foregroundColor(.orange)
            }
            
            // Progress bar
            if let endTime = building.constructionEndTime {
                ProgressBar(progress: constructionProgress(endTime: endTime))
                
                HStack {
                    Text(timeRemaining(endTime: endTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.watchAdForBuildTimeReduction(building: building)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.rectangle.fill")
                            Text("-1h")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func constructionProgress(endTime: Date) -> Double {
        guard let startTime = building.constructionStartTime else { return 0 }
        let totalDuration = endTime.timeIntervalSince(startTime)
        let elapsed = Date().timeIntervalSince(startTime)
        return min(1.0, max(0, elapsed / totalDuration))
    }
    
    private func timeRemaining(endTime: Date) -> String {
        let remaining = endTime.timeIntervalSince(Date())
        if remaining <= 0 { return "Complete!" }
        
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }
}

// MARK: - Build Menu View
struct BuildMenuView: View {
    @ObservedObject var viewModel: GameViewModel
    let category: BuildingCategory
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(availableBuildings, id: \.self) { type in
                        BuildOptionCard(type: type, viewModel: viewModel) {
                            viewModel.build(type)
                            dismiss()
                        }
                    }
                    
                    if availableBuildings.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("No buildings available")
                                .font(.headline)
                            
                            Text("Unlock more through discoveries")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 50)
                    }
                }
                .padding()
            }
            .navigationTitle("Build \(category.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private var availableBuildings: [BuildingType] {
        BuildingType.allCases.filter { type in
            type.category == category && viewModel.village.canBuild(type)
        }
    }
}

// MARK: - Build Option Card
struct BuildOptionCard: View {
    let type: BuildingType
    @ObservedObject var viewModel: GameViewModel
    let onBuild: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.name)
                        .font(.headline)
                    
                    Text("Build time: \(formatTime(type.baseConstructionTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onBuild) {
                    Text("Build")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canBuild(type))
            }
            
            // Cost breakdown
            CostView(cost: type.baseCost, village: viewModel.village)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func formatTime(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60))m"
        }
        return "\(Int(hours))h"
    }
}

// MARK: - Cost View
struct CostView: View {
    let cost: Resources
    let village: Village
    
    var body: some View {
        HStack(spacing: 12) {
            if cost.food > 0 {
                CostBadge(icon: "leaf.fill", value: Int(cost.food),
                         canAfford: village.foodStorage.total >= cost.food, color: .green)
            }
            if cost.firewood > 0 {
                CostBadge(icon: "flame.fill", value: Int(cost.firewood),
                         canAfford: village.resources.firewood >= cost.firewood, color: .orange)
            }
            if cost.stone > 0 {
                CostBadge(icon: "mountain.2.fill", value: Int(cost.stone),
                         canAfford: village.resources.stone >= cost.stone, color: .brown)
            }
            if cost.metal > 0 {
                CostBadge(icon: "gearshape.fill", value: Int(cost.metal),
                         canAfford: village.resources.metal >= cost.metal, color: .gray)
            }
        }
    }
}

// MARK: - Supporting Views
struct StatBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct CostBadge: View {
    let icon: String
    let value: Int
    let canAfford: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text("\(value)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(canAfford ? .primary : .red)
        }
    }
}

struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: geometry.size.width * progress, height: 8)
                    .cornerRadius(4)
            }
        }
        .frame(height: 8)
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
