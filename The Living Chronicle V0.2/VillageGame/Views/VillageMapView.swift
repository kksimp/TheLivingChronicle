import SwiftUI
import SceneKit


// MARK: - Village Map View (2.5D Isometric)
struct VillageMapView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var selectedBuilding: Building?
    @State private var mapScale: CGFloat = 1.0
    @State private var mapOffset: CGSize = .zero
    @GestureState private var magnificationState: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Sky gradient background
            skyGradient
                .ignoresSafeArea()
            
            // Main isometric scene
            VillageIsometricSceneView(
                viewModel: viewModel,
                selectedBuilding: $selectedBuilding
            )
            .scaleEffect(mapScale * magnificationState)
            .offset(mapOffset)
            .gesture(
                MagnificationGesture()
                    .updating($magnificationState) { value, state, _ in
                        state = value
                    }
                    .onEnded { value in
                        mapScale *= value
                        mapScale = min(max(mapScale, 0.5), 3.0) // Clamp zoom
                    }
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        mapOffset = CGSize(
                            width: mapOffset.width + value.translation.width,
                            height: mapOffset.height + value.translation.height
                        )
                    }
            )
            .ignoresSafeArea()
            
            // UI Overlay (reuse existing HUD)
            VStack {
                if let building = selectedBuilding {
                    buildingInfoPanel(building)
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
}

// MARK: - Village Isometric Scene View
struct VillageIsometricSceneView: UIViewRepresentable {
    @ObservedObject var viewModel: GameViewModel
    @Binding var selectedBuilding: Building?
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = SCNScene()
        sceneView.allowsCameraControl = false  // We control zoom manually
        sceneView.autoenablesDefaultLighting = false
        sceneView.backgroundColor = .clear
        
        // Setup isometric camera
        setupIsometricCamera(in: sceneView.scene!)
        
        // Setup ground plane
        setupGroundPlane(in: sceneView.scene!)
        
        // Setup lighting (from above-right for isometric look)
        setupIsometricLighting(in: sceneView.scene!)
        
        // Add environment
        setupEnvironment(in: sceneView.scene!)
        
        // Add buildings
        updateBuildings(in: sceneView.scene!)
        
        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        return sceneView
    }
    
    func updateUIView(_ sceneView: SCNView, context: Context) {
        updateBuildings(in: sceneView.scene!)
        setupGroundPlane(in: sceneView.scene!)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Isometric Camera Setup
    
    private func setupIsometricCamera(in scene: SCNScene) {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true  // KEY: Orthographic for 2.5D
        cameraNode.camera?.orthographicScale = 15
        
        // Isometric angle: 45° from top, looking down-right
        cameraNode.position = SCNVector3(x: 0, y: 30, z: 30)
        cameraNode.eulerAngles = SCNVector3(x: -.pi / 4, y: 0, z: 0)
        
        scene.rootNode.addChildNode(cameraNode)
    }
    
    // MARK: - Ground Plane
    
    private func setupGroundPlane(in scene: SCNScene) {
        scene.rootNode.childNodes.filter { $0.name == "ground" }.forEach { $0.removeFromParentNode() }
        
        // Large flat plane for the ground
        let groundPlane = SCNPlane(width: 100, height: 100)
        
        let groundMaterial = SCNMaterial()
        groundMaterial.diffuse.contents = groundColorForSeason(viewModel.village.currentSeason)
        groundMaterial.lightingModel = .lambert
        groundPlane.materials = [groundMaterial]
        
        let groundNode = SCNNode(geometry: groundPlane)
        groundNode.name = "ground"
        groundNode.eulerAngles.x = -.pi / 2  // Rotate to be horizontal
        groundNode.position = SCNVector3(0, -0.1, 0)
        
        scene.rootNode.addChildNode(groundNode)
        
        // Add grid pattern (optional - looks nice)
        addGridPattern(to: scene)
    }
    
    private func addGridPattern(to scene: SCNScene) {
        scene.rootNode.childNodes.filter { $0.name == "grid" }.forEach { $0.removeFromParentNode() }
        
        let gridSize = 50
        let spacing: Float = 2.0
        
        for i in -gridSize...gridSize {
            // Horizontal lines
            let hLine = SCNBox(width: CGFloat(gridSize * 2) * CGFloat(spacing), height: 0.01, length: 0.05, chamferRadius: 0)
            let hMaterial = SCNMaterial()
            hMaterial.diffuse.contents = UIColor.white.withAlphaComponent(0.1)
            hLine.materials = [hMaterial]
            
            let hNode = SCNNode(geometry: hLine)
            hNode.name = "grid"
            hNode.position = SCNVector3(0, 0, Float(i) * spacing)
            scene.rootNode.addChildNode(hNode)
            
            // Vertical lines
            let vLine = SCNBox(width: 0.05, height: 0.01, length: CGFloat(gridSize * 2) * CGFloat(spacing), chamferRadius: 0)
            let vMaterial = SCNMaterial()
            vMaterial.diffuse.contents = UIColor.white.withAlphaComponent(0.1)
            vLine.materials = [vMaterial]
            
            let vNode = SCNNode(geometry: vLine)
            vNode.name = "grid"
            vNode.position = SCNVector3(Float(i) * spacing, 0, 0)
            scene.rootNode.addChildNode(vNode)
        }
    }
    
    // MARK: - Isometric Lighting
    
    private func setupIsometricLighting(in scene: SCNScene) {
        scene.rootNode.childNodes.filter { $0.name == "light" }.forEach { $0.removeFromParentNode() }
        
        // Ambient light
        let ambientLight = SCNNode()
        ambientLight.name = "light"
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.5, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
        
        // Main directional light (from top-right for isometric look)
        let mainLight = SCNNode()
        mainLight.name = "light"
        mainLight.light = SCNLight()
        mainLight.light?.type = .directional
        mainLight.light?.color = UIColor(white: 0.8, alpha: 1.0)
        mainLight.light?.castsShadow = true
        mainLight.light?.shadowMode = .deferred
        mainLight.light?.shadowRadius = 3
        mainLight.eulerAngles = SCNVector3(x: -.pi / 3, y: .pi / 4, z: 0)
        scene.rootNode.addChildNode(mainLight)
    }
    
    // MARK: - Environment
    
    private func setupEnvironment(in scene: SCNScene) {
        scene.rootNode.childNodes.filter { $0.name == "env" }.forEach { $0.removeFromParentNode() }
        
        let envAssets = KenneyAssetLoader.shared.getEnvironmentAssets()
        let isModern = viewModel.village.currentEra.rawValue >= Era.structuredSociety.rawValue
        let isSuperModern = viewModel.village.currentEra.rawValue >= Era.industrialTransition.rawValue
        
        let assets = isSuperModern ? envAssets.filter { $0.category == .suburban } :
                     (isModern ? envAssets.filter { $0.category == .urban } :
                      envAssets.filter { $0.category == .medieval })
        
        // Add trees in a grid pattern around the edges
        let treePositions = [
            (-15.0, -15.0), (-15.0, 0.0), (-15.0, 15.0),
            (15.0, -15.0), (15.0, 0.0), (15.0, 15.0),
            (0.0, -15.0), (0.0, 15.0),
            (-10.0, -10.0), (10.0, -10.0), (-10.0, 10.0), (10.0, 10.0)
        ]
        
        for (i, (x, z)) in treePositions.enumerated() {
            if let treeAsset = assets.filter({ $0.type == .tree }).randomElement(),
               let treeNode = KenneyAssetLoader.shared.loadAsset(category: treeAsset.category, filename: treeAsset.filename) {
                
                treeNode.name = "env"
                treeNode.position = SCNVector3(x, 0, z)
                treeNode.scale = SCNVector3(0.8, 0.8, 0.8)
                treeNode.eulerAngles.y = Float.random(in: 0...(.pi * 2))
                
                scene.rootNode.addChildNode(treeNode)
            }
        }
    }
    
    // MARK: - Buildings
    
    private func updateBuildings(in scene: SCNScene) {
        scene.rootNode.childNodes.filter { $0.name?.hasPrefix("building_") ?? false }.forEach { $0.removeFromParentNode() }
        
        let positions = calculateBuildingGrid()
        
        for (building, gridPos) in positions {
            guard let (category, filename) = KenneyAssetLoader.shared.assetForBuilding(building.type),
                  let buildingNode = KenneyAssetLoader.shared.loadAsset(category: category, filename: filename) else {
                let fallback = createFallbackBuilding(for: building)
                fallback.position = SCNVector3(gridPos.x, 0, gridPos.y)
                fallback.name = "building_\(building.id.uuidString)"
                scene.rootNode.addChildNode(fallback)
                continue
            }
            
            buildingNode.name = "building_\(building.id.uuidString)"
            buildingNode.position = SCNVector3(gridPos.x, 0, gridPos.y)
            
            // Scale based on level
            let scale = 0.8 + Double(building.level) * 0.1
            buildingNode.scale = SCNVector3(scale, scale, scale)
            
            // Effects
            if building.isUnderConstruction {
                buildingNode.opacity = 0.6
                addConstructionEffect(to: buildingNode)
            } else if building.isDamaged {
                addDamageSmoke(to: buildingNode)
            }
            
            // Selection highlight
            if selectedBuilding?.id == building.id {
                addSelectionRing(to: buildingNode)
            }
            
            scene.rootNode.addChildNode(buildingNode)
        }
    }
    
    // MARK: - Building Grid Layout (Like Clash of Clans)
    
    private func calculateBuildingGrid() -> [(Building, CGPoint)] {
        var positions: [(Building, CGPoint)] = []
        
        // Sort by category for organized placement
        let sorted = viewModel.village.buildings.sorted { b1, b2 in
            if b1.category == b2.category {
                return b1.id.uuidString < b2.id.uuidString
            }
            return b1.category.rawValue < b2.category.rawValue
        }
        
        // Grid layout
        let gridSpacing: CGFloat = 3.0
        var currentX: CGFloat = -12
        var currentZ: CGFloat = -12
        var inRow = 0
        let maxPerRow = 6
        
        for building in sorted {
            positions.append((building, CGPoint(x: currentX, y: currentZ)))
            
            currentX += gridSpacing
            inRow += 1
            
            if inRow >= maxPerRow {
                inRow = 0
                currentX = -12
                currentZ += gridSpacing
            }
        }
        
        return positions
    }
    
    // MARK: - Visual Effects
    
    private func createFallbackBuilding(for building: Building) -> SCNNode {
        let box = SCNBox(width: 1.5, height: 2, length: 1.5, chamferRadius: 0.1)
        let material = SCNMaterial()
        material.diffuse.contents = categoryColor(for: building.category)
        box.materials = [material]
        return SCNNode(geometry: box)
    }
    
    private func addConstructionEffect(to node: SCNNode) {
        // Rotating crane/hammer indicator
        let cone = SCNCone(topRadius: 0.1, bottomRadius: 0.2, height: 0.4)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.orange
        cone.materials = [material]
        
        let indicator = SCNNode(geometry: cone)
        indicator.position = SCNVector3(0, 2.5, 0)
        
        let rotate = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 2)
        indicator.runAction(SCNAction.repeatForever(rotate))
        
        node.addChildNode(indicator)
    }
    
    private func addDamageSmoke(to node: SCNNode) {
        let particle = SCNParticleSystem()
        particle.birthRate = 5
        particle.particleLifeSpan = 1.5
        particle.particleSize = 0.2
        particle.particleColor = UIColor.darkGray
        particle.emitterShape = SCNBox(width: 0.5, height: 0.1, length: 0.5, chamferRadius: 0)
        
        let smokeNode = SCNNode()
        smokeNode.addParticleSystem(particle)
        smokeNode.position = SCNVector3(0, 1.5, 0)
        node.addChildNode(smokeNode)
    }
    
    private func addSelectionRing(to node: SCNNode) {
        let ring = SCNTorus(ringRadius: 1.2, pipeRadius: 0.05)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.yellow
        material.emission.contents = UIColor.yellow
        ring.materials = [material]
        
        let ringNode = SCNNode(geometry: ring)
        ringNode.eulerAngles.x = .pi / 2
        ringNode.position = SCNVector3(0, 0.1, 0)
        
        // Pulse animation
        let scaleUp = SCNAction.scale(to: 1.1, duration: 0.5)
        let scaleDown = SCNAction.scale(to: 1.0, duration: 0.5)
        let pulse = SCNAction.sequence([scaleUp, scaleDown])
        ringNode.runAction(SCNAction.repeatForever(pulse))
        
        node.addChildNode(ringNode)
    }
    
    private func categoryColor(for category: BuildingCategory) -> UIColor {
        switch category {
        case .housing: return UIColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 1.0)
        case .production: return UIColor(red: 0.6, green: 0.8, blue: 0.4, alpha: 1.0)
        case .storage: return UIColor(red: 0.9, green: 0.7, blue: 0.3, alpha: 1.0)
        case .defense: return UIColor(red: 0.5, green: 0.5, blue: 0.7, alpha: 1.0)
        case .special: return UIColor(red: 0.9, green: 0.6, blue: 0.8, alpha: 1.0)
        }
    }
    
    private func groundColorForSeason(_ season: Season) -> UIColor {
        switch season {
        case .spring: return UIColor(red: 0.35, green: 0.65, blue: 0.35, alpha: 1.0)
        case .summer: return UIColor(red: 0.4, green: 0.6, blue: 0.3, alpha: 1.0)
        case .fall: return UIColor(red: 0.55, green: 0.5, blue: 0.3, alpha: 1.0)
        case .winter: return UIColor(red: 0.92, green: 0.92, blue: 0.95, alpha: 1.0)
        }
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject {
        var parent: VillageIsometricSceneView
        
        init(_ parent: VillageIsometricSceneView) {
            self.parent = parent
        }
        
        @MainActor @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let sceneView = gesture.view as! SCNView
            let location = gesture.location(in: sceneView)
            
            let hitResults = sceneView.hitTest(location, options: [:])
            
            if let hit = hitResults.first,
               let nodeName = hit.node.name,
               nodeName.hasPrefix("building_") {
                let uuidString = String(nodeName.dropFirst("building_".count))
                if let uuid = UUID(uuidString: uuidString),
                   let building = parent.viewModel.village.buildings.first(where: { $0.id == uuid }) {
                    parent.selectedBuilding = building
                }
            } else {
                parent.selectedBuilding = nil
            }
        }
    }
}
