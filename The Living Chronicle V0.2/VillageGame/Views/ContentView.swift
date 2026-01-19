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
    @State private var needsSetup = false
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if needsSetup {
                    VillageSetupView(viewModel: viewModel)
                        .onReceive(viewModel.$village) { village in
                            if village.yearsSurvived > 0 || village.chronicle.count > 1 {
                                needsSetup = false
                            }
                        }
                } else if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.village.isExtinct {
                    ExtinctionView(viewModel: viewModel)
                } else {
                    MainGameView(viewModel: viewModel, screenSize: geometry.size)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if SaveManager.shared.loadAllSaves().isEmpty {
                needsSetup = true
            } else {
                viewModel.onAppear()
            }
        }
        .onDisappear { viewModel.onDisappear() }
    }
}

// MARK: - Village Setup View
struct VillageSetupView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var villageName = ""
    @State private var isAnimating = false
    
    private let randomNames = [
        "Willowbrook", "Stonehaven", "Riverdale", "Oakridge", "Pinecrest",
        "Meadowvale", "Thornfield", "Ashford", "Birchwood", "Cedarholm",
        "Dustmoor", "Eldergrove", "Frostpeak", "Goldvale", "Hazelwick",
        "Ironforge", "Juniper Falls", "Kingsreach", "Lakeshire", "Millbrook",
        "Northwatch", "Oldtown", "Pebblebrook", "Quarryhill", "Redcliff",
        "Silverstream", "Thistledown", "Umberton", "Vineheart", "Winterhollow"
    ]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.2, blue: 0.1), Color(red: 0.1, green: 0.15, blue: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Title
                VStack(spacing: 8) {
                    Text("The Living Chronicle")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    Text("A Village Survival Story")
                        .font(.system(size: 16, design: .serif))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Village naming section
                VStack(spacing: 20) {
                    Text("Name Your Village")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        TextField("Enter village name", text: $villageName)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                        
                        Button(action: randomizeName) {
                            Image(systemName: "dice.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.orange.opacity(0.8))
                                .cornerRadius(10)
                                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Start button
                Button(action: startGame) {
                    HStack {
                        Image(systemName: "flag.fill")
                        Text("Found Village")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(12)
                    .shadow(color: .green.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .disabled(villageName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(villageName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                
                Spacer()
            }
        }
        .onAppear {
            // Auto-generate a random name on appear
            villageName = randomNames.randomElement() ?? "New Settlement"
        }
    }
    
    private func randomizeName() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isAnimating = true
        }
        villageName = randomNames.randomElement() ?? "New Settlement"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimating = false
        }
    }
    
    private func startGame() {
        let name = villageName.trimmingCharacters(in: .whitespaces)
        viewModel.startNewGame(name: name.isEmpty ? "New Settlement" : name)
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

// MARK: - Main Game View
struct MainGameView: View {
    @ObservedObject var viewModel: GameViewModel
    let screenSize: CGSize
    
    var body: some View {
        ZStack {
            // Background Map
            VillageMapView(viewModel: viewModel)
                    .ignoresSafeArea()
            
            // Clash-Style HUD
            ClashStyleHUD(viewModel: viewModel, screenSize: screenSize)
            
            // Slide-in Panel
            if let panel = viewModel.selectedPanel {
                SlidePanelView(viewModel: viewModel, panel: panel, screenSize: screenSize)
                    .transition(.move(edge: .trailing))
            }
            
            // Build Menu
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
        .sheet(isPresented: $viewModel.showingGuildShop) {
            GuildMarksShopView(viewModel: viewModel)
        }
    }
}

// MARK: - Clash-Style HUD
struct ClashStyleHUD: View {
    @ObservedObject var viewModel: GameViewModel
    let screenSize: CGSize
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    var body: some View {
        ZStack {
            // Top Section
            VStack {
                HStack(alignment: .top, spacing: 12) {
                    playerInfoBadge
                    Spacer()
                    topRightResources
                }
                .padding(.top, max(safeAreaInsets.top, 8))
                .padding(.horizontal, 12)
                
                Spacer()
            }
        
    
            
            // Left Side Buttons
            HStack {
                VStack(spacing: 10) {
                    Spacer().frame(height: 90)
                    
                    leftSideButton(icon: "hammer.fill", label: "Build", color: .blue, badge: viewModel.village.availableBuilders > 0 ? "\(viewModel.village.availableBuilders)" : nil) {
                        viewModel.showingBuildMenu = true
                    }
                    
                    leftSideButton(icon: "person.3.fill", label: "Jobs", color: .green, badge: nil) {
                        viewModel.selectedPanel = .population
                    }
                    
                    if viewModel.village.hasDiscovery(.scholars) {
                        leftSideButton(icon: "lightbulb.fill", label: "Research", color: .purple, badge: nil) {
                            viewModel.selectedPanel = .research
                        }
                    }
                    
                    leftSideButton(icon: "book.fill", label: "Chronicle", color: .brown, badge: nil) {
                        viewModel.selectedPanel = .chronicle
                    }
                    
                    Spacer()
                }
                .padding(.leading, max(safeAreaInsets.leading, 8))
                
                Spacer()
            }
            
            // Right Side Buttons
            HStack {
                Spacer()
                
                VStack(spacing: 10) {
                    Spacer().frame(height: 140)
                    
                    rightSideButton(icon: "gear") {
                        viewModel.selectedPanel = .settings
                    }
                    
                    Spacer()
                }
                .padding(.trailing, max(safeAreaInsets.trailing, 8))
            }
            
            // Bottom Section
            VStack {
                Spacer()
                
                HStack(alignment: .bottom, spacing: 16) {
                    threatAttackButton
                    
                    Spacer()
                    
                    bottomStatBar
                    
                    Spacer()
                    
                    shopButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, max(safeAreaInsets.bottom, 12))
            }
        }
    }
    
    // MARK: - Player Info Badge
    private var playerInfoBadge: some View {
        HStack(spacing: 0) {
            ZStack {
            
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.5, blue: 0.8), Color(red: 0.1, green: 0.3, blue: 0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.cyan.opacity(0.8), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                
                VStack(spacing: 0) {
                    Text("\(viewModel.village.yearsSurvived)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("YRS")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }.padding(.trailing, 5)
            
            VStack(alignment: .center, spacing: 4) {
                Text(viewModel.village.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.black.opacity(0.4))
                        Capsule()
                            .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * eraProgress)
                    }
                }
                .frame(width: 100, height: 10)
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                
                Text(viewModel.village.currentEra.name)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.leading, 8)
            .padding(.trailing, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.5))
                
            )
        }.padding(.leading, 10)
    }
    
    private var eraProgress: Double {
        Double(viewModel.village.currentEra.rawValue + 1) / Double(Era.allCases.count)
    }

    // MARK: - Top Right Resources
    private var topRightResources: some View {
        VStack(alignment: .trailing, spacing: 6) {
            resourceBar(
                icon: "seal.fill",
                iconColor: .yellow,
                value: viewModel.village.resources.guildMarks,
                maxValue: nil,
                barColor: .green,
                showPlus: true
            ) {
                viewModel.showingGuildShop = true
            }
            
            resourceBar(
                icon: "leaf.fill",
                iconColor: .green,
                value: Int(viewModel.village.foodStorage.total),
                maxValue: 9999,
                barColor: .yellow,
                showPlus: false,
                action: nil
            )
            
            resourceBar(
                icon: "drop.fill",
                iconColor: .cyan,
                value: Int(viewModel.village.resources.water),
                maxValue: 9999,
                barColor: .purple,
                showPlus: false,
                action: nil
            )
            
            resourceBar(
                icon: "flame.fill",
                iconColor: .orange,
                value: Int(viewModel.village.resources.firewood),
                maxValue: 9999,
                barColor: .orange,
                showPlus: false,
                action: nil
            )
        }
        .fixedSize(horizontal: true, vertical: false) // KEY FIX: Constrain the entire VStack
    }

    private func resourceBar(
        icon: String,
        iconColor: Color,
        value: Int,
        maxValue: Int?,
        barColor: Color,
        showPlus: Bool,
        action: (() -> Void)?
    ) -> some View {
        Group {
            if let action {
                Button(action: action) {
                    resourceBarContent(
                        icon: icon,
                        iconColor: iconColor,
                        value: value,
                        showPlus: showPlus
                    )
                }
                .buttonStyle(.plain)
            } else {
                resourceBarContent(
                    icon: icon,
                    iconColor: iconColor,
                    value: value,
                    showPlus: showPlus
                )
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private func resourceBarContent(
        icon: String,
        iconColor: Color,
        value: Int,
        showPlus: Bool
    ) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [iconColor, iconColor.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.15, green: 0.15, blue: 0.2),
                                Color(red: 0.1, green: 0.1, blue: 0.15)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 95, height: 24)

                HStack(spacing: 4) {
                    Text(formatNumber(value))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 1, y: 1)

                    if showPlus {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 16, height: 16)
                            Image(systemName: "plus")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .frame(width: 95, height: 24)
            }
            .overlay(Capsule().stroke(Color.black.opacity(0.5), lineWidth: 1))
            .offset(x: -5)
        }
    }


    // MARK: - Number Formatter
    private func formatNumber(_ value: Int) -> String {
        if value >= 10000 {
            return String(format: "%.1fK", Double(value) / 1000.0)
        } else if value >= 1000 {
            return String(format: "%.1fK", Double(value) / 1000.0)
        }
        return "\(value)"
    }
    
    
    // MARK: - Left Side Buttons
    private func leftSideButton(icon: String, label: String, color: Color, badge: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.5)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 54, height: 54)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 2
                                    )
                            )
                            .shadow(color: color.opacity(0.5), radius: 4, y: 3)
                        
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                    }
                    
                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(
                                Circle()
                                    .fill(Color.red)
                                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                            )
                            .offset(x: 6, y: -6)
                    }
                }
                
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            }
        }
    }
    
    // MARK: - Right Side Buttons
    private func rightSideButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.3, green: 0.3, blue: 0.35), Color(red: 0.2, green: 0.2, blue: 0.25)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 46, height: 46)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Threat/Attack Button
    private var threatAttackButton: some View {
        Button(action: { viewModel.selectedPanel = .threats }) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: threatGradientColors,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 72, height: 72)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.6), Color.white.opacity(0.1)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: threatColor.opacity(0.6), radius: 6, y: 3)
                    
                    VStack(spacing: 2) {
                        Image(systemName: threatIcon)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                        
                        Text("\(Int(viewModel.village.totalDefenseRating * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                    }
                    
                    // Pulse animation for imminent threat
                    if viewModel.village.currentThreatPhase == .raidImminent {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red, lineWidth: 3)
                            .frame(width: 72, height: 72)
                            .scaleEffect(1.1)
                            .opacity(0.5)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.village.currentThreatPhase)
                    }
                }
                
                Text(viewModel.village.currentThreatPhase == .none ? "Defense" : viewModel.village.currentThreatPhase.name)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            }
        }
    }
    
    private var threatGradientColors: [Color] {
        switch viewModel.village.currentThreatPhase {
        case .none: return [Color(red: 0.2, green: 0.7, blue: 0.3), Color(red: 0.1, green: 0.5, blue: 0.2)]
        case .rumors: return [Color(red: 0.9, green: 0.8, blue: 0.2), Color(red: 0.8, green: 0.6, blue: 0.1)]
        case .scouts: return [Color(red: 0.9, green: 0.5, blue: 0.1), Color(red: 0.8, green: 0.3, blue: 0.1)]
        case .raidImminent: return [Color(red: 0.9, green: 0.2, blue: 0.2), Color(red: 0.7, green: 0.1, blue: 0.1)]
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
        case .none: return "shield.fill"
        case .rumors: return "eye.fill"
        case .scouts: return "binoculars.fill"
        case .raidImminent: return "flame.fill"
        }
    }
    
    // MARK: - Bottom Stat Bar
    private var bottomStatBar: some View {
        HStack(spacing: 10) {
            statPill(icon: "person.3.fill", value: "\(viewModel.village.population)", subValue: "/\(viewModel.village.housingCapacity)", color: .blue)
            statPill(icon: "heart.fill", value: "\(Int(viewModel.village.health))%", subValue: nil, color: healthColor)
            statPill(icon: "face.smiling.fill", value: "\(Int(viewModel.village.morale))%", subValue: nil, color: moraleColor)
            
            // Season indicator
            HStack(spacing: 4) {
                seasonIcon
                    .font(.system(size: 16))
                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.village.currentSeason.name)
                        .font(.system(size: 11, weight: .bold))
                    Text("Year \(viewModel.village.gameYear)")
                        .font(.system(size: 9))
                    .opacity(0.8)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [seasonColor, seasonColor.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
            )
        }
    }
    
    private func statPill(icon: String, value: String, subValue: String?, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            if let sub = subValue {
                Text(sub)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
                .overlay(
                    Capsule().stroke(color.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        )
    }
    
    private var healthColor: Color {
        viewModel.village.health > 60 ? .green : (viewModel.village.health > 30 ? .yellow : .red)
    }
    
    private var moraleColor: Color {
        viewModel.village.morale > 60 ? .green : (viewModel.village.morale > 30 ? .yellow : .orange)
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
        case .spring: return Color(red: 0.3, green: 0.7, blue: 0.4)
        case .summer: return Color(red: 0.9, green: 0.6, blue: 0.2)
        case .fall: return Color(red: 0.6, green: 0.4, blue: 0.2)
        case .winter: return Color(red: 0.4, green: 0.7, blue: 0.9)
        }
    }
    
    // MARK: - Shop Button
    private var shopButton: some View {
        Button(action: { viewModel.showingGuildShop = true }) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.75, blue: 0.2), Color(red: 0.85, green: 0.55, blue: 0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 72, height: 72)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.6), Color.white.opacity(0.1)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color.orange.opacity(0.5), radius: 6, y: 3)
                    
                    Image(systemName: "cart.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                }
                
                Text("Shop")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            }
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
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.selectedPanel = nil
                }
            
            VStack(spacing: 0) {
                panelHeader
                
                ScrollView {
                    panelContent
                        .padding()
                }
            }
            .frame(width: min(420, screenSize.width * 0.5))
            .background(
                LinearGradient(
                    colors: [Color(red: 0.12, green: 0.12, blue: 0.18), Color(red: 0.08, green: 0.08, blue: 0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.5), radius: 20, x: -5, y: 0)
            .padding(.vertical, 16)
            .padding(.trailing, 8)
        }
    }
    
    private var panelHeader: some View {
        HStack {
            Image(systemName: panel.icon)
                .font(.title2)
                .foregroundColor(panelColor)
            Text(panel.rawValue)
                .font(.title2.bold())
                .foregroundColor(.white)
            Spacer()
            Button(action: { viewModel.selectedPanel = nil }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
    
    private var panelColor: Color {
        switch panel {
        case .buildings: return .blue
        case .population: return .green
        case .threats: return .red
        case .research: return .purple
        case .chronicle: return .brown
        case .settings: return .gray
        }
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
                HStack(spacing: 4) {
                    Image(systemName: "hammer.fill")
                        .foregroundColor(.orange)
                    if let endTime = building.constructionEndTime {
                        Text(timeRemaining(endTime))
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
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
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
    
    private func timeRemaining(_ endTime: Date) -> String {
        let remaining = endTime.timeIntervalSince(Date())
        if remaining <= 0 { return "Done!" }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

struct PopulationPanelContent: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Population: \(viewModel.village.population) / \(viewModel.village.housingCapacity)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ProgressView(value: Double(viewModel.village.population), total: Double(max(1, viewModel.village.housingCapacity)))
                    .tint(.blue)
            }
            
            Divider().background(Color.gray)
            
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
        .cornerRadius(12)
    }
}

struct ThreatsPanelContent: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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
        .cornerRadius(10)
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
            .cornerRadius(10)
            
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
            Color.black.opacity(0.4)
                .onTapGesture {
                    viewModel.showingBuildMenu = false
                }
            
            VStack(spacing: 0) {
                // Handle bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                
                HStack {
                    Text("Build")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "hammer.fill")
                            .foregroundColor(.orange)
                        Text("\(viewModel.village.availableBuilders) builders")
                            .foregroundColor(.white)
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    
                    Button(action: { viewModel.showingBuildMenu = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                // Category tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
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
                            VStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                    .font(.title)
                                    .foregroundColor(.gray)
                                Text("No buildings available")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("Unlock through discoveries")
                                    .font(.caption2)
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                            .frame(width: 150)
                            .padding()
                        }
                    }
                    .padding()
                }
            }
            .frame(height: 300)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.15, green: 0.15, blue: 0.2), Color(red: 0.1, green: 0.1, blue: 0.15)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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
            HStack(spacing: 6) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 12))
                Text(category.rawValue)
                    .font(.subheadline.bold())
            }
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? categoryColor : Color.white.opacity(0.1))
            )
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
    
    private var categoryColor: Color {
        switch category {
        case .housing: return .blue
        case .production: return .green
        case .storage: return .orange
        case .defense: return .purple
        case .special: return .yellow
        }
    }
}

struct BuildOptionCardview: View {
    let type: BuildingType
    @ObservedObject var viewModel: GameViewModel
    let onBuild: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Building icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(categoryColor.opacity(0.5), lineWidth: 1)
                    )
                
                Image(systemName: buildingIcon)
                    .font(.system(size: 28))
                    .foregroundColor(categoryColor)
            }
            
            Text(type.name)
                .font(.caption.bold())
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 80)
            
            // Cost
            HStack(spacing: 4) {
                if type.baseCost.firewood > 0 {
                    costIcon(icon: "flame.fill", value: Int(type.baseCost.firewood), canAfford: viewModel.village.resources.firewood >= type.baseCost.firewood, color: .orange)
                }
                if type.baseCost.stone > 0 {
                    costIcon(icon: "cube.fill", value: Int(type.baseCost.stone), canAfford: viewModel.village.resources.stone >= type.baseCost.stone, color: .gray)
                }
            }
            
            // Time
            Text(formatTime(type.baseConstructionTime))
                .font(.caption2)
                .foregroundColor(.gray)
            
            Button(action: onBuild) {
                Text("Build")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(viewModel.canBuild(type) ? Color.green : Color.gray)
                    )
            }
            .disabled(!viewModel.canBuild(type))
        }
        .frame(width: 100)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private func costIcon(icon: String, value: Int, canAfford: Bool, color: Color) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(color)
            Text("\(value)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(canAfford ? .white : .red)
        }
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
    
    private func formatTime(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60))m"
        }
        return "\(Int(hours))h"
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
            NewGameSheet(viewModel: viewModel)
        }
    }
}

struct NewGameSheet: View {
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
        VStack(spacing: 20) {
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
                        VStack(spacing: 4) {
                            Text(choice.label)
                                .font(.headline)
                            Text(choice.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
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
