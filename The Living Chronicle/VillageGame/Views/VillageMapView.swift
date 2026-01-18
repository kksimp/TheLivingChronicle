import SwiftUI

// MARK: - Village Map View
struct VillageMapView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var selectedBuilding: Building?
    @State private var mapOffset: CGSize = .zero
    @State private var mapScale: CGFloat = 1.0
    
    private let gridSize: Int = 12
    private let tileSize: CGFloat = 60
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sky gradient based on time/season
                skyGradient
                    .ignoresSafeArea()
                
                // Main map content
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    ZStack {
                        // Ground layer
                        groundLayer
                        
                        // Buildings layer
                        buildingsLayer
                        
                        // Weather effects
                        weatherEffects
                        
                        // Villagers (animated dots)
                        villagersLayer
                    }
                    .frame(width: CGFloat(gridSize) * tileSize, height: CGFloat(gridSize) * tileSize)
                    .scaleEffect(mapScale)
                }
                
                // Overlay UI
                VStack {
                    // Top bar with time/weather
                    mapTopBar
                    
                    Spacer()
                    
                    // Bottom info panel
                    if let building = selectedBuilding {
                        buildingInfoPanel(building)
                    }
                }
            }
        }
        .onTapGesture {
            selectedBuilding = nil
        }
    }
    
    // MARK: - Sky Gradient
    private var skyGradient: some View {
        let colors: [Color]
        
        switch (viewModel.village.currentSeason, viewModel.village.currentWeather) {
        case (.winter, _):
            colors = [Color(red: 0.7, green: 0.8, blue: 0.9), Color(red: 0.9, green: 0.95, blue: 1.0)]
        case (_, .dangerous):
            colors = [Color(red: 0.3, green: 0.2, blue: 0.3), Color(red: 0.5, green: 0.3, blue: 0.2)]
        case (_, .heavy):
            colors = [Color(red: 0.4, green: 0.45, blue: 0.5), Color(red: 0.6, green: 0.65, blue: 0.7)]
        case (.summer, _):
            colors = [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.6, green: 0.85, blue: 1.0)]
        case (.fall, _):
            colors = [Color(red: 0.6, green: 0.5, blue: 0.4), Color(red: 0.9, green: 0.8, blue: 0.6)]
        default:
            colors = [Color(red: 0.5, green: 0.75, blue: 1.0), Color(red: 0.7, green: 0.9, blue: 0.7)]
        }
        
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }
    
    // MARK: - Ground Layer
    private var groundLayer: some View {
        Canvas { context, size in
            let seed = viewModel.village.seed
            
            for row in 0..<gridSize {
                for col in 0..<gridSize {
                    let rect = CGRect(
                        x: CGFloat(col) * tileSize,
                        y: CGFloat(row) * tileSize,
                        width: tileSize,
                        height: tileSize
                    )
                    
                    // Procedural ground color
                    let noise = seededNoise(x: col, y: row, seed: seed)
                    let groundColor = groundColorForSeason(noise: noise)
                    
                    context.fill(Path(rect), with: .color(groundColor))
                    
                    // Add grass tufts or snow patches
                    drawGroundDetails(context: context, rect: rect, noise: noise)
                }
            }
            
            // Draw paths between buildings
            drawPaths(context: context)
            
            // Draw river if present
            if viewModel.village.hasBuilding(.well) || viewModel.village.resources.water > 0 {
                drawRiver(context: context, size: size, seed: seed)
            }
        }
        .frame(width: CGFloat(gridSize) * tileSize, height: CGFloat(gridSize) * tileSize)
    }
    
    private func groundColorForSeason(noise: Double) -> Color {
        let baseVariation = 0.1 * noise
        
        switch viewModel.village.currentSeason {
        case .spring:
            return Color(red: 0.3 + baseVariation, green: 0.6 + baseVariation, blue: 0.3)
        case .summer:
            return Color(red: 0.35 + baseVariation, green: 0.55 + baseVariation, blue: 0.25)
        case .fall:
            return Color(red: 0.5 + baseVariation, green: 0.45 + baseVariation, blue: 0.25)
        case .winter:
            let snowAmount = 0.7 + baseVariation * 0.3
            return Color(red: snowAmount, green: snowAmount, blue: snowAmount + 0.05)
        }
    }
    
    private func drawGroundDetails(context: GraphicsContext, rect: CGRect, noise: Double) {
        if viewModel.village.currentSeason == .winter {
            // Snow sparkles
            if noise > 0.7 {
                let sparkle = Path(ellipseIn: CGRect(
                    x: rect.midX + noise * 10 - 5,
                    y: rect.midY + noise * 10 - 5,
                    width: 3,
                    height: 3
                ))
                context.fill(sparkle, with: .color(.white.opacity(0.8)))
            }
        } else {
            // Grass tufts
            if noise > 0.6 {
                for i in 0..<3 {
                    let x = rect.minX + CGFloat(i) * 15 + 10
                    let y = rect.maxY - 5
                    var grass = Path()
                    grass.move(to: CGPoint(x: x, y: y))
                    grass.addLine(to: CGPoint(x: x - 2, y: y - 8 - noise * 5))
                    grass.addLine(to: CGPoint(x: x + 2, y: y - 6 - noise * 5))
                    grass.closeSubpath()
                    
                    let grassColor = viewModel.village.currentSeason == .fall ?
                        Color(red: 0.6, green: 0.5, blue: 0.2) :
                        Color(red: 0.2, green: 0.5, blue: 0.2)
                    context.fill(grass, with: .color(grassColor))
                }
            }
        }
    }
    
    private func drawPaths(context: GraphicsContext) {
        let pathColor = Color(red: 0.6, green: 0.5, blue: 0.4)
        
        // Simple path from center outward
        let centerX = CGFloat(gridSize / 2) * tileSize
        let centerY = CGFloat(gridSize / 2) * tileSize
        
        var mainPath = Path()
        mainPath.move(to: CGPoint(x: centerX, y: 0))
        mainPath.addLine(to: CGPoint(x: centerX, y: CGFloat(gridSize) * tileSize))
        
        context.stroke(mainPath, with: .color(pathColor), lineWidth: 8)
        
        var crossPath = Path()
        crossPath.move(to: CGPoint(x: 0, y: centerY))
        crossPath.addLine(to: CGPoint(x: CGFloat(gridSize) * tileSize, y: centerY))
        
        context.stroke(crossPath, with: .color(pathColor), lineWidth: 8)
    }
    
    private func drawRiver(context: GraphicsContext, size: CGSize, seed: UInt64) {
        var river = Path()
        river.move(to: CGPoint(x: 0, y: size.height * 0.3))
        
        for x in stride(from: 0, to: size.width, by: 20) {
            let noise = seededNoise(x: Int(x), y: 0, seed: seed)
            let y = size.height * 0.3 + sin(x / 50) * 30 + noise * 20
            river.addLine(to: CGPoint(x: x, y: y))
        }
        
        river.addLine(to: CGPoint(x: size.width, y: size.height * 0.35))
        river.addLine(to: CGPoint(x: size.width, y: size.height * 0.4))
        
        for x in stride(from: size.width, through: 0, by: -20) {
            let noise = seededNoise(x: Int(x), y: 1, seed: seed)
            let y = size.height * 0.35 + sin(x / 50) * 30 + noise * 20
            river.addLine(to: CGPoint(x: x, y: y))
        }
        
        river.closeSubpath()
        
        let riverColor = Color(red: 0.3, green: 0.5, blue: 0.7)
        context.fill(river, with: .color(riverColor.opacity(0.7)))
    }
    
    // MARK: - Buildings Layer
    private var buildingsLayer: some View {
        let positions = calculateBuildingPositions()
        
        return ZStack {
            ForEach(Array(positions.enumerated()), id: \.element.0.id) { index, item in
                let (building, position) = item
                
                ProceduralBuildingView(
                    building: building,
                    season: viewModel.village.currentSeason,
                    isSelected: selectedBuilding?.id == building.id
                )
                .position(position)
                .onTapGesture {
                    selectedBuilding = building
                }
            }
        }
    }
    
    private func calculateBuildingPositions() -> [(Building, CGPoint)] {
        var positions: [(Building, CGPoint)] = []
        let center = CGPoint(x: CGFloat(gridSize) * tileSize / 2, y: CGFloat(gridSize) * tileSize / 2)
        
        // Sort buildings by category for placement
        let sortedBuildings = viewModel.village.buildings.sorted { b1, b2 in
            b1.category.rawValue < b2.category.rawValue
        }
        
        var angle: CGFloat = 0
        var radius: CGFloat = 80
        var buildingsInRing = 0
        let maxPerRing = 8
        
        for building in sortedBuildings {
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            
            positions.append((building, CGPoint(x: x, y: y)))
            
            angle += .pi * 2 / CGFloat(maxPerRing)
            buildingsInRing += 1
            
            if buildingsInRing >= maxPerRing {
                buildingsInRing = 0
                radius += 70
                angle = CGFloat.random(in: 0...0.5)  // Offset each ring
            }
        }
        
        return positions
    }
    
    // MARK: - Weather Effects
    private var weatherEffects: some View {
        ZStack {
            if viewModel.village.currentWeather == .heavy || viewModel.village.currentWeather == .dangerous {
                RainView(intensity: viewModel.village.currentWeather == .dangerous ? 1.0 : 0.5)
            }
            
            if viewModel.village.currentSeason == .winter && viewModel.village.currentWeather != .weak {
                SnowView(intensity: viewModel.village.currentWeather == .dangerous ? 1.0 : 0.3)
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Villagers Layer
    private var villagersLayer: some View {
        let villagerCount = min(viewModel.village.population, 30)  // Cap visual villagers
        
        return ForEach(0..<villagerCount, id: \.self) { index in
            AnimatedVillagerView(
                index: index,
                seed: viewModel.village.seed,
                gridSize: gridSize,
                tileSize: tileSize
            )
        }
    }
    
    // MARK: - Top Bar
    private var mapTopBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.village.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Text("\(viewModel.village.currentSeason.name), Year \(viewModel.village.gameYear)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Weather indicator
            WeatherIndicatorView(
                weather: viewModel.village.currentWeather,
                season: viewModel.village.currentSeason
            )
            
            // Population
            HStack(spacing: 4) {
                Image(systemName: "person.3.fill")
                Text("\(viewModel.village.population)")
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.5), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Building Info Panel
    private func buildingInfoPanel(_ building: Building) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(building.name)
                    .font(.headline)
                Spacer()
                Text("Level \(building.level)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if building.isUnderConstruction {
                if let endTime = building.constructionEndTime {
                    ProgressView(value: constructionProgress(building))
                        .tint(.orange)
                    Text("Building... \(timeRemaining(endTime))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            } else {
                HStack {
                    if viewModel.canUpgrade(building) {
                        Button("Upgrade") {
                            viewModel.upgrade(building)
                            selectedBuilding = nil
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Button("Demolish") {
                        viewModel.demolish(building)
                        selectedBuilding = nil
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding()
    }
    
    private func constructionProgress(_ building: Building) -> Double {
        guard let start = building.constructionStartTime,
              let end = building.constructionEndTime else { return 0 }
        let total = end.timeIntervalSince(start)
        let elapsed = Date().timeIntervalSince(start)
        return min(1.0, max(0, elapsed / total))
    }
    
    private func timeRemaining(_ endTime: Date) -> String {
        let remaining = endTime.timeIntervalSince(Date())
        if remaining <= 0 { return "Complete!" }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    // MARK: - Helpers
    private func seededNoise(x: Int, y: Int, seed: UInt64) -> Double {
        var hash = seed
        hash ^= UInt64(x) * 374761393
        hash ^= UInt64(y) * 668265263
        hash = (hash ^ (hash >> 13)) &* 1274126177
        return Double(hash % 1000) / 1000.0
    }
}

// MARK: - Procedural Building View
struct ProceduralBuildingView: View {
    let building: Building
    let season: Season
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(Color.black.opacity(0.2))
                .frame(width: buildingSize.width * 0.8, height: buildingSize.height * 0.3)
                .offset(y: buildingSize.height * 0.4)
            
            // Building shape
            Canvas { context, size in
                drawBuilding(context: context, size: size)
            }
            .frame(width: buildingSize.width, height: buildingSize.height)
            
            // Construction indicator
            if building.isUnderConstruction {
                Image(systemName: "hammer.fill")
                    .foregroundColor(.orange)
                    .offset(y: -buildingSize.height * 0.4)
            }
            
            // Damage indicator
            if building.isDamaged {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .offset(y: -buildingSize.height * 0.4)
            }
        }
        .opacity(building.isUnderConstruction ? 0.6 : 1.0)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
    
    private var buildingSize: CGSize {
        let baseSize: CGFloat = 50 + CGFloat(building.level) * 3
        
        switch building.type.category {
        case .housing:
            return CGSize(width: baseSize * 0.8, height: baseSize)
        case .production:
            return CGSize(width: baseSize * 1.2, height: baseSize * 0.8)
        case .storage:
            return CGSize(width: baseSize, height: baseSize * 0.7)
        case .defense:
            return CGSize(width: baseSize * 0.6, height: baseSize * 1.3)
        case .special:
            return CGSize(width: baseSize * 1.1, height: baseSize * 1.2)
        }
    }
    
    private func drawBuilding(context: GraphicsContext, size: CGSize) {
        switch building.type {
        case .groundShelter:
            drawShelter(context: context, size: size)
        case .tent:
            drawTent(context: context, size: size)
        case .hut:
            drawHut(context: context, size: size)
        case .stoneHome, .insulatedHouse, .houseWithAC:
            drawHouse(context: context, size: size)
        case .farm:
            drawFarm(context: context, size: size)
        case .orchard:
            drawOrchard(context: context, size: size)
        case .well:
            drawWell(context: context, size: size)
        case .woodpile:
            drawWoodpile(context: context, size: size)
        case .quarry, .mine:
            drawMine(context: context, size: size)
        case .granary, .saltStorehouse, .smokehouse, .refrigeratedStorage:
            drawStorage(context: context, size: size)
        case .watchtower:
            drawTower(context: context, size: size)
        case .palisade, .stoneWall:
            drawWall(context: context, size: size)
        case .shrine, .church:
            drawChurch(context: context, size: size)
        case .herbalist:
            drawHerbalist(context: context, size: size)
        case .scholarsHut:
            drawScholar(context: context, size: size)
        case .market:
            drawMarket(context: context, size: size)
        case .townHall:
            drawTownHall(context: context, size: size)
        case .medicalHall:
            drawMedical(context: context, size: size)
        }
    }
    
    // MARK: - Building Drawing Functions
    
    private func drawShelter(context: GraphicsContext, size: CGSize) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))
        path.addLine(to: CGPoint(x: size.width / 2, y: size.height * 0.3))
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()
        
        context.fill(path, with: .color(Color(red: 0.4, green: 0.3, blue: 0.2)))
        context.stroke(path, with: .color(Color(red: 0.3, green: 0.2, blue: 0.1)), lineWidth: 2)
    }
    
    private func drawTent(context: GraphicsContext, size: CGSize) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))
        path.addLine(to: CGPoint(x: size.width / 2, y: 0))
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()
        
        let tentColor = Color(red: 0.8, green: 0.7, blue: 0.5)
        context.fill(path, with: .color(tentColor))
        context.stroke(path, with: .color(Color(red: 0.5, green: 0.4, blue: 0.3)), lineWidth: 2)
        
        // Tent opening
        var opening = Path()
        opening.move(to: CGPoint(x: size.width * 0.4, y: size.height))
        opening.addLine(to: CGPoint(x: size.width / 2, y: size.height * 0.5))
        opening.addLine(to: CGPoint(x: size.width * 0.6, y: size.height))
        context.fill(opening, with: .color(Color(red: 0.2, green: 0.15, blue: 0.1)))
    }
    
    private func drawHut(context: GraphicsContext, size: CGSize) {
        // Walls
        let wallRect = CGRect(x: size.width * 0.1, y: size.height * 0.4, width: size.width * 0.8, height: size.height * 0.6)
        context.fill(Path(roundedRect: wallRect, cornerRadius: 3), with: .color(Color(red: 0.6, green: 0.45, blue: 0.3)))
        
        // Roof
        var roof = Path()
        roof.move(to: CGPoint(x: 0, y: size.height * 0.45))
        roof.addLine(to: CGPoint(x: size.width / 2, y: 0))
        roof.addLine(to: CGPoint(x: size.width, y: size.height * 0.45))
        roof.closeSubpath()
        
        context.fill(roof, with: .color(Color(red: 0.5, green: 0.35, blue: 0.2)))
        
        // Door
        let doorRect = CGRect(x: size.width * 0.4, y: size.height * 0.6, width: size.width * 0.2, height: size.height * 0.4)
        context.fill(Path(roundedRect: doorRect, cornerRadius: 2), with: .color(Color(red: 0.3, green: 0.2, blue: 0.1)))
    }
    
    private func drawHouse(context: GraphicsContext, size: CGSize) {
        let isStone = building.type == .stoneHome || building.type == .insulatedHouse || building.type == .houseWithAC
        let wallColor = isStone ? Color(red: 0.7, green: 0.7, blue: 0.7) : Color(red: 0.8, green: 0.75, blue: 0.65)
        
        // Walls
        let wallRect = CGRect(x: size.width * 0.1, y: size.height * 0.35, width: size.width * 0.8, height: size.height * 0.65)
        context.fill(Path(roundedRect: wallRect, cornerRadius: 2), with: .color(wallColor))
        
        // Roof
        var roof = Path()
        roof.move(to: CGPoint(x: 0, y: size.height * 0.4))
        roof.addLine(to: CGPoint(x: size.width / 2, y: 0))
        roof.addLine(to: CGPoint(x: size.width, y: size.height * 0.4))
        roof.closeSubpath()
        
        let roofColor = building.type == .houseWithAC ? Color(red: 0.3, green: 0.3, blue: 0.4) : Color(red: 0.6, green: 0.3, blue: 0.2)
        context.fill(roof, with: .color(roofColor))
        
        // Window
        let windowRect = CGRect(x: size.width * 0.6, y: size.height * 0.45, width: size.width * 0.2, height: size.height * 0.2)
        context.fill(Path(roundedRect: windowRect, cornerRadius: 1), with: .color(Color(red: 0.6, green: 0.8, blue: 1.0)))
        
        // Door
        let doorRect = CGRect(x: size.width * 0.25, y: size.height * 0.55, width: size.width * 0.2, height: size.height * 0.45)
        context.fill(Path(roundedRect: doorRect, cornerRadius: 2), with: .color(Color(red: 0.4, green: 0.25, blue: 0.15)))
        
        // AC unit for modern house
        if building.type == .houseWithAC {
            let acRect = CGRect(x: size.width * 0.7, y: size.height * 0.7, width: size.width * 0.2, height: size.height * 0.15)
            context.fill(Path(roundedRect: acRect, cornerRadius: 2), with: .color(Color.gray))
        }
    }
    
    private func drawFarm(context: GraphicsContext, size: CGSize) {
        // Field rows
        let fieldColor = season == .winter ? Color(red: 0.8, green: 0.8, blue: 0.8) :
                        (season == .fall ? Color(red: 0.7, green: 0.6, blue: 0.3) : Color(red: 0.4, green: 0.6, blue: 0.3))
        
        for i in 0..<4 {
            let y = size.height * 0.3 + CGFloat(i) * size.height * 0.18
            var row = Path()
            row.move(to: CGPoint(x: 0, y: y))
            row.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(row, with: .color(fieldColor), lineWidth: 8)
        }
        
        // Small barn
        let barnRect = CGRect(x: size.width * 0.7, y: 0, width: size.width * 0.3, height: size.height * 0.35)
        context.fill(Path(roundedRect: barnRect, cornerRadius: 2), with: .color(Color(red: 0.6, green: 0.3, blue: 0.2)))
    }
    
    private func drawOrchard(context: GraphicsContext, size: CGSize) {
        let treeColor = season == .fall ? Color(red: 0.8, green: 0.5, blue: 0.2) :
                       (season == .winter ? Color(red: 0.4, green: 0.3, blue: 0.3) : Color(red: 0.3, green: 0.6, blue: 0.3))
        
        // Draw trees in grid
        for row in 0..<2 {
            for col in 0..<3 {
                let x = size.width * 0.2 + CGFloat(col) * size.width * 0.3
                let y = size.height * 0.3 + CGFloat(row) * size.height * 0.4
                
                // Trunk
                let trunkRect = CGRect(x: x - 3, y: y, width: 6, height: 15)
                context.fill(Path(roundedRect: trunkRect, cornerRadius: 1), with: .color(Color(red: 0.4, green: 0.3, blue: 0.2)))
                
                // Foliage
                let foliage = Path(ellipseIn: CGRect(x: x - 12, y: y - 20, width: 24, height: 24))
                context.fill(foliage, with: .color(treeColor))
            }
        }
    }
    
    private func drawWell(context: GraphicsContext, size: CGSize) {
        // Well base (stone circle)
        let baseCircle = Path(ellipseIn: CGRect(x: size.width * 0.1, y: size.height * 0.5, width: size.width * 0.8, height: size.height * 0.4))
        context.fill(baseCircle, with: .color(Color(red: 0.5, green: 0.5, blue: 0.5)))
        
        // Water
        let waterCircle = Path(ellipseIn: CGRect(x: size.width * 0.2, y: size.height * 0.55, width: size.width * 0.6, height: size.height * 0.3))
        context.fill(waterCircle, with: .color(Color(red: 0.3, green: 0.5, blue: 0.7)))
        
        // Roof posts
        let postWidth: CGFloat = 4
        context.fill(Path(CGRect(x: size.width * 0.2, y: size.height * 0.2, width: postWidth, height: size.height * 0.4)), with: .color(Color(red: 0.4, green: 0.3, blue: 0.2)))
        context.fill(Path(CGRect(x: size.width * 0.8 - postWidth, y: size.height * 0.2, width: postWidth, height: size.height * 0.4)), with: .color(Color(red: 0.4, green: 0.3, blue: 0.2)))
        
        // Roof
        var roof = Path()
        roof.move(to: CGPoint(x: size.width * 0.1, y: size.height * 0.25))
        roof.addLine(to: CGPoint(x: size.width / 2, y: 0))
        roof.addLine(to: CGPoint(x: size.width * 0.9, y: size.height * 0.25))
        roof.closeSubpath()
        context.fill(roof, with: .color(Color(red: 0.5, green: 0.35, blue: 0.2)))
    }
    
    private func drawWoodpile(context: GraphicsContext, size: CGSize) {
        // Stacked logs
        for row in 0..<3 {
            for col in 0..<(4 - row) {
                let x = size.width * 0.1 + CGFloat(col) * size.width * 0.25 + CGFloat(row) * size.width * 0.125
                let y = size.height - CGFloat(row + 1) * size.height * 0.25
                
                let logRect = CGRect(x: x, y: y, width: size.width * 0.2, height: size.height * 0.2)
                context.fill(Path(roundedRect: logRect, cornerRadius: 4), with: .color(Color(red: 0.5, green: 0.35, blue: 0.2)))
                
                // Log end
                let endCircle = Path(ellipseIn: CGRect(x: x + size.width * 0.15, y: y + 2, width: size.width * 0.08, height: size.height * 0.16))
                context.fill(endCircle, with: .color(Color(red: 0.6, green: 0.45, blue: 0.3)))
            }
        }
    }
    
    private func drawMine(context: GraphicsContext, size: CGSize) {
        // Cave entrance
        var entrance = Path()
        entrance.move(to: CGPoint(x: size.width * 0.1, y: size.height))
        entrance.addQuadCurve(to: CGPoint(x: size.width * 0.9, y: size.height),
                              control: CGPoint(x: size.width / 2, y: size.height * 0.3))
        entrance.addLine(to: CGPoint(x: size.width * 0.9, y: size.height))
        entrance.closeSubpath()
        
        context.fill(entrance, with: .color(Color(red: 0.5, green: 0.5, blue: 0.5)))
        
        // Dark interior
        var interior = Path()
        interior.move(to: CGPoint(x: size.width * 0.2, y: size.height))
        interior.addQuadCurve(to: CGPoint(x: size.width * 0.8, y: size.height),
                              control: CGPoint(x: size.width / 2, y: size.height * 0.5))
        interior.closeSubpath()
        
        context.fill(interior, with: .color(Color(red: 0.15, green: 0.1, blue: 0.1)))
        
        // Support beams
        context.fill(Path(CGRect(x: size.width * 0.25, y: size.height * 0.5, width: 4, height: size.height * 0.5)),
                    with: .color(Color(red: 0.4, green: 0.3, blue: 0.2)))
        context.fill(Path(CGRect(x: size.width * 0.75 - 4, y: size.height * 0.5, width: 4, height: size.height * 0.5)),
                    with: .color(Color(red: 0.4, green: 0.3, blue: 0.2)))
    }
    
    private func drawStorage(context: GraphicsContext, size: CGSize) {
        // Main building
        let wallRect = CGRect(x: size.width * 0.05, y: size.height * 0.3, width: size.width * 0.9, height: size.height * 0.7)
        context.fill(Path(roundedRect: wallRect, cornerRadius: 3), with: .color(Color(red: 0.6, green: 0.5, blue: 0.4)))
        
        // Roof
        var roof = Path()
        roof.move(to: CGPoint(x: 0, y: size.height * 0.35))
        roof.addLine(to: CGPoint(x: size.width / 2, y: 0))
        roof.addLine(to: CGPoint(x: size.width, y: size.height * 0.35))
        roof.closeSubpath()
        context.fill(roof, with: .color(Color(red: 0.5, green: 0.4, blue: 0.3)))
        
        // Door
        let doorRect = CGRect(x: size.width * 0.35, y: size.height * 0.5, width: size.width * 0.3, height: size.height * 0.5)
        context.fill(Path(roundedRect: doorRect, cornerRadius: 2), with: .color(Color(red: 0.35, green: 0.25, blue: 0.15)))
    }
    
    private func drawTower(context: GraphicsContext, size: CGSize) {
        // Tower body
        let towerRect = CGRect(x: size.width * 0.2, y: size.height * 0.2, width: size.width * 0.6, height: size.height * 0.8)
        context.fill(Path(roundedRect: towerRect, cornerRadius: 2), with: .color(Color(red: 0.5, green: 0.4, blue: 0.3)))
        
        // Platform
        let platformRect = CGRect(x: size.width * 0.1, y: size.height * 0.15, width: size.width * 0.8, height: size.height * 0.1)
        context.fill(Path(roundedRect: platformRect, cornerRadius: 2), with: .color(Color(red: 0.45, green: 0.35, blue: 0.25)))
        
        // Roof
        var roof = Path()
        roof.move(to: CGPoint(x: size.width * 0.1, y: size.height * 0.15))
        roof.addLine(to: CGPoint(x: size.width / 2, y: 0))
        roof.addLine(to: CGPoint(x: size.width * 0.9, y: size.height * 0.15))
        roof.closeSubpath()
        context.fill(roof, with: .color(Color(red: 0.4, green: 0.25, blue: 0.15)))
    }
    
    private func drawWall(context: GraphicsContext, size: CGSize) {
        let isStone = building.type == .stoneWall
        let wallColor = isStone ? Color(red: 0.6, green: 0.6, blue: 0.6) : Color(red: 0.5, green: 0.4, blue: 0.3)
        
        // Wall segments
        let wallRect = CGRect(x: 0, y: size.height * 0.3, width: size.width, height: size.height * 0.7)
        context.fill(Path(roundedRect: wallRect, cornerRadius: isStone ? 2 : 0), with: .color(wallColor))
        
        // Crenellations
        for i in 0..<4 {
            let x = CGFloat(i) * size.width * 0.25 + size.width * 0.05
            let crenRect = CGRect(x: x, y: size.height * 0.15, width: size.width * 0.15, height: size.height * 0.2)
            context.fill(Path(roundedRect: crenRect, cornerRadius: isStone ? 1 : 0), with: .color(wallColor))
        }
    }
    
    private func drawChurch(context: GraphicsContext, size: CGSize) {
        // Main building
        let wallRect = CGRect(x: size.width * 0.15, y: size.height * 0.35, width: size.width * 0.7, height: size.height * 0.65)
        context.fill(Path(roundedRect: wallRect, cornerRadius: 2), with: .color(Color(red: 0.85, green: 0.8, blue: 0.75)))
        
        // Roof
        var roof = Path()
        roof.move(to: CGPoint(x: size.width * 0.1, y: size.height * 0.4))
        roof.addLine(to: CGPoint(x: size.width / 2, y: size.height * 0.15))
        roof.addLine(to: CGPoint(x: size.width * 0.9, y: size.height * 0.4))
        roof.closeSubpath()
        context.fill(roof, with: .color(Color(red: 0.4, green: 0.25, blue: 0.2)))
        
        // Steeple
        var steeple = Path()
        steeple.move(to: CGPoint(x: size.width * 0.4, y: size.height * 0.15))
        steeple.addLine(to: CGPoint(x: size.width / 2, y: 0))
        steeple.addLine(to: CGPoint(x: size.width * 0.6, y: size.height * 0.15))
        steeple.closeSubpath()
        context.fill(steeple, with: .color(Color(red: 0.4, green: 0.25, blue: 0.2)))
        
        // Cross
        context.fill(Path(CGRect(x: size.width / 2 - 2, y: size.height * 0.02, width: 4, height: 12)),
                    with: .color(Color(red: 0.8, green: 0.7, blue: 0.3)))
        context.fill(Path(CGRect(x: size.width / 2 - 6, y: size.height * 0.05, width: 12, height: 4)),
                    with: .color(Color(red: 0.8, green: 0.7, blue: 0.3)))
        
        // Door
        var door = Path()
        door.move(to: CGPoint(x: size.width * 0.4, y: size.height))
        door.addLine(to: CGPoint(x: size.width * 0.4, y: size.height * 0.6))
        door.addQuadCurve(to: CGPoint(x: size.width * 0.6, y: size.height * 0.6),
                         control: CGPoint(x: size.width / 2, y: size.height * 0.5))
        door.addLine(to: CGPoint(x: size.width * 0.6, y: size.height))
        door.closeSubpath()
        context.fill(door, with: .color(Color(red: 0.4, green: 0.25, blue: 0.15)))
    }
    
    private func drawHerbalist(context: GraphicsContext, size: CGSize) {
        // Hut
        drawHut(context: context, size: size)
        
        // Herbs/plants around
        let herbColor = season == .winter ? Color.white : Color(red: 0.3, green: 0.7, blue: 0.4)
        for i in 0..<5 {
            let x = CGFloat(i) * size.width * 0.2 + 5
            let herb = Path(ellipseIn: CGRect(x: x, y: size.height * 0.85, width: 8, height: 10))
            context.fill(herb, with: .color(herbColor))
        }
    }
    
    private func drawScholar(context: GraphicsContext, size: CGSize) {
        // Building similar to hut but with books
        drawHut(context: context, size: size)
        
        // Book stack
        for i in 0..<3 {
            let bookRect = CGRect(x: size.width * 0.7, y: size.height * 0.7 - CGFloat(i) * 5, width: 15, height: 4)
            let colors: [Color] = [.red, .blue, .green]
            context.fill(Path(roundedRect: bookRect, cornerRadius: 1), with: .color(colors[i].opacity(0.7)))
        }
    }
    
    private func drawMarket(context: GraphicsContext, size: CGSize) {
        // Stall with canopy
        let stallRect = CGRect(x: size.width * 0.1, y: size.height * 0.5, width: size.width * 0.8, height: size.height * 0.5)
        context.fill(Path(roundedRect: stallRect, cornerRadius: 2), with: .color(Color(red: 0.6, green: 0.5, blue: 0.4)))
        
        // Canopy
        var canopy = Path()
        canopy.move(to: CGPoint(x: 0, y: size.height * 0.5))
        canopy.addLine(to: CGPoint(x: size.width / 2, y: size.height * 0.2))
        canopy.addLine(to: CGPoint(x: size.width, y: size.height * 0.5))
        canopy.closeSubpath()
        context.fill(canopy, with: .color(Color(red: 0.8, green: 0.3, blue: 0.2)))
        
        // Stripes on canopy
        for i in 0..<4 {
            let x1 = CGFloat(i) * size.width * 0.25 + size.width * 0.1
            var stripe = Path()
            stripe.move(to: CGPoint(x: x1, y: size.height * 0.5))
            stripe.addLine(to: CGPoint(x: x1 + size.width * 0.05, y: size.height * 0.35))
            context.stroke(stripe, with: .color(Color.white), lineWidth: 3)
        }
    }
    
    private func drawTownHall(context: GraphicsContext, size: CGSize) {
        // Grand building
        let wallRect = CGRect(x: size.width * 0.1, y: size.height * 0.3, width: size.width * 0.8, height: size.height * 0.7)
        context.fill(Path(roundedRect: wallRect, cornerRadius: 3), with: .color(Color(red: 0.8, green: 0.75, blue: 0.7)))
        
        // Columns
        for i in 0..<3 {
            let x = size.width * 0.2 + CGFloat(i) * size.width * 0.25
            let colRect = CGRect(x: x, y: size.height * 0.35, width: size.width * 0.08, height: size.height * 0.6)
            context.fill(Path(roundedRect: colRect, cornerRadius: 2), with: .color(Color(red: 0.9, green: 0.85, blue: 0.8)))
        }
        
        // Pediment
        var pediment = Path()
        pediment.move(to: CGPoint(x: size.width * 0.05, y: size.height * 0.35))
        pediment.addLine(to: CGPoint(x: size.width / 2, y: 0))
        pediment.addLine(to: CGPoint(x: size.width * 0.95, y: size.height * 0.35))
        pediment.closeSubpath()
        context.fill(pediment, with: .color(Color(red: 0.85, green: 0.8, blue: 0.75)))
    }
    
    private func drawMedical(context: GraphicsContext, size: CGSize) {
        // White building
        let wallRect = CGRect(x: size.width * 0.1, y: size.height * 0.3, width: size.width * 0.8, height: size.height * 0.7)
        context.fill(Path(roundedRect: wallRect, cornerRadius: 3), with: .color(Color.white))
        
        // Flat roof
        let roofRect = CGRect(x: size.width * 0.05, y: size.height * 0.25, width: size.width * 0.9, height: size.height * 0.1)
        context.fill(Path(roundedRect: roofRect, cornerRadius: 2), with: .color(Color(red: 0.9, green: 0.9, blue: 0.9)))
        
        // Red cross
        context.fill(Path(CGRect(x: size.width / 2 - 3, y: size.height * 0.4, width: 6, height: 20)),
                    with: .color(Color.red))
        context.fill(Path(CGRect(x: size.width / 2 - 10, y: size.height * 0.47, width: 20, height: 6)),
                    with: .color(Color.red))
    }
}

// MARK: - Weather Indicator View
struct WeatherIndicatorView: View {
    let weather: Weather
    let season: Season
    
    var body: some View {
        HStack(spacing: 4) {
            weatherIcon
                .font(.title3)
            Text(weather.name)
                .font(.caption)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
    
    private var weatherIcon: some View {
        let iconName: String
        
        switch (season, weather) {
        case (.winter, .dangerous): iconName = "cloud.snow.fill"
        case (.winter, _): iconName = "snowflake"
        case (_, .dangerous): iconName = "sun.max.fill"
        case (_, .heavy): iconName = "cloud.bolt.rain.fill"
        case (_, .mild): iconName = "cloud.sun.fill"
        case (_, .weak): iconName = "sun.max.fill"
        }
        
        return Image(systemName: iconName)
    }
}

// MARK: - Rain View
struct RainView: View {
    let intensity: Double
    @State private var drops: [RainDrop] = []
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                for drop in drops {
                    let y = ((time * drop.speed + drop.offset).truncatingRemainder(dividingBy: 1.0)) * size.height
                    
                    var path = Path()
                    path.move(to: CGPoint(x: drop.x * size.width, y: y))
                    path.addLine(to: CGPoint(x: drop.x * size.width, y: y + 10))
                    
                    context.stroke(path, with: .color(.white.opacity(0.3)), lineWidth: 1)
                }
            }
        }
        .onAppear {
            drops = (0..<Int(100 * intensity)).map { _ in
                RainDrop(
                    x: Double.random(in: 0...1),
                    speed: Double.random(in: 0.5...1.0),
                    offset: Double.random(in: 0...1)
                )
            }
        }
    }
}

struct RainDrop {
    let x: Double
    let speed: Double
    let offset: Double
}

// MARK: - Snow View
struct SnowView: View {
    let intensity: Double
    @State private var flakes: [SnowFlake] = []
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                for flake in flakes {
                    let y = ((time * flake.speed * 0.3 + flake.offset).truncatingRemainder(dividingBy: 1.0)) * size.height
                    let x = flake.x * size.width + sin(time * flake.wobble + flake.offset * 10) * 20
                    
                    let snowFlake = Path(ellipseIn: CGRect(x: x, y: y, width: flake.size, height: flake.size))
                    context.fill(snowFlake, with: .color(.white.opacity(0.8)))
                }
            }
        }
        .onAppear {
            flakes = (0..<Int(80 * intensity)).map { _ in
                SnowFlake(
                    x: Double.random(in: 0...1),
                    speed: Double.random(in: 0.3...0.7),
                    offset: Double.random(in: 0...1),
                    size: Double.random(in: 3...6),
                    wobble: Double.random(in: 1...3)
                )
            }
        }
    }
}

struct SnowFlake {
    let x: Double
    let speed: Double
    let offset: Double
    let size: Double
    let wobble: Double
}

// MARK: - Animated Villager View
struct AnimatedVillagerView: View {
    let index: Int
    let seed: UInt64
    let gridSize: Int
    let tileSize: CGFloat
    
    @State private var position: CGPoint = .zero
    @State private var targetPosition: CGPoint = .zero
    
    var body: some View {
        ZStack {
            // Body
            Circle()
                .fill(villagerColor)
                .frame(width: 8, height: 8)
            
            // Head
            Circle()
                .fill(Color(red: 0.9, green: 0.8, blue: 0.7))
                .frame(width: 5, height: 5)
                .offset(y: -5)
        }
        .position(position)
        .onAppear {
            let hash = seededRandom(seed: seed, index: index)
            position = CGPoint(
                x: CGFloat(hash % UInt64(gridSize)) * tileSize + tileSize / 2,
                y: CGFloat((hash >> 16) % UInt64(gridSize)) * tileSize + tileSize / 2
            )
            startWalking()
        }
    }
    
    private var villagerColor: Color {
        let colors: [Color] = [
            Color(red: 0.6, green: 0.4, blue: 0.3),
            Color(red: 0.3, green: 0.4, blue: 0.6),
            Color(red: 0.5, green: 0.5, blue: 0.3),
            Color(red: 0.4, green: 0.3, blue: 0.4)
        ]
        return colors[index % colors.count]
    }
    
    private func startWalking() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 2...5), repeats: true) { _ in
            let newX = position.x + CGFloat.random(in: -30...30)
            let newY = position.y + CGFloat.random(in: -30...30)
            
            let maxCoord = CGFloat(gridSize) * tileSize
            targetPosition = CGPoint(
                x: max(20, min(maxCoord - 20, newX)),
                y: max(20, min(maxCoord - 20, newY))
            )
            
            withAnimation(.easeInOut(duration: 1.5)) {
                position = targetPosition
            }
        }
    }
    
    private func seededRandom(seed: UInt64, index: Int) -> UInt64 {
        var hash = seed
        hash ^= UInt64(index) * 374761393
        hash = (hash ^ (hash >> 13)) &* 1274126177
        return hash
    }
}
