import Foundation
import Combine
import SwiftUI

// MARK: - Game View Model
@MainActor
class GameViewModel: ObservableObject {
    // Core state
    @Published var village: Village {
        didSet {
            // Auto-save when village changes
            saveDebouncer?.invalidate()
            saveDebouncer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.forceSave()
                }
            }
        }
    }
    @Published var isLoading: Bool = false
    @Published var showingEvent: GameEvent?
    @Published var pendingEvents: [GameEvent] = []
    @Published var errorMessage: String?
    @Published var showingGuildShop: Bool = false
    
    // Sheets / overlays
    @Published var showingSettings: Bool = false
    @Published var showingDiscoveries: Bool = false
    
    // Navigation/selection (used by your Overview quick actions)
    @Published var selectedTab: GameTab = .buildings
    
    enum GameTab: Hashable {
        case buildings
        case population
        case threats
    }
    
    // UI State
    @Published var selectedPanel: GamePanel? = nil
    @Published var showingBuildMenu: Bool = false
    
    // Managers
    private var engine: GameEngine!
    private let timeManager: TimeManager
    private let autoSaveManager: AutoSaveManager
    private var saveDebouncer: Timer?
    
    // Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    init(village: Village) {
        self.village = village
        self.timeManager = TimeManager()
        self.autoSaveManager = AutoSaveManager()
        
        // Create engine after self is initialized
        self.engine = GameEngine(village: village, timeManager: timeManager)
        
        setupBindings()
        autoSaveManager.startAutoSave(for: engine)
    }
    
    convenience init() {
        if let savedVillage = try? SaveManager.shared.loadCurrentSave() {
            self.init(village: savedVillage)
        } else {
            self.init(village: Village(name: "New Settlement"))
        }
    }
    
    private func setupBindings() {
        engine.$village
            .receive(on: DispatchQueue.main)
            .sink { [weak self] village in
                self?.village = village
            }
            .store(in: &cancellables)
        
        engine.$pendingEvents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] events in
                self?.handleNewEvents(events)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Game Flow
    
    func onAppear() {
        Task {
            await processCatchUp()
            await verifyTimeIfNeeded()
        }
    }
    
    func onDisappear() {
        forceSave()
        autoSaveManager.stopAutoSave()
    }
    
    private func processCatchUp() async {
        isLoading = true
        defer { isLoading = false }
        
        await Task.detached { [engine] in
            engine?.processCatchUp()
        }.value
    }
    
    private func verifyTimeIfNeeded() async {
        guard timeManager.shouldVerifyTime() else { return }
        
        let result = await timeManager.verifyTime()
        if !result.success {
            if let drift = result.drift, abs(drift) > 300 {
                errorMessage = "Time verification warning: Device time may be incorrect."
            }
        }
    }
    
    // MARK: - Events
    
    private func handleNewEvents(_ events: [GameEvent]) {
        for event in events {
            if event.requiresChoice {
                pendingEvents.append(event)
            } else {
                if event.type.severity == .critical || event.type.severity == .warning {
                    pendingEvents.append(event)
                }
            }
        }
        
        showNextEvent()
        engine.pendingEvents.removeAll()
    }
    
    func showNextEvent() {
        guard showingEvent == nil, !pendingEvents.isEmpty else { return }
        showingEvent = pendingEvents.removeFirst()
    }
    
    func acknowledgeEvent() {
        showingEvent = nil
        showNextEvent()
    }
    
    func selectChoice(_ choice: EventChoice) {
        guard let event = showingEvent, event.requiresChoice else { return }
        
        for effect in choice.effects {
            engine.applyEffect(effect)
        }
        
        acknowledgeEvent()
    }
    
    // MARK: - Building
    
    func canBuild(_ type: BuildingType) -> Bool {
        guard village.canBuild(type) else { return false }
        guard village.availableBuilders > 0 else { return false }
        return village.canAfford(type.baseCost)
    }
    
    func build(_ type: BuildingType) {
        guard canBuild(type) else { return }
        
        var newBuilding = Building(type: type, level: 0)
        let constructionTime = type.baseConstructionTime * 3600
        newBuilding.startConstruction(currentTime: Date(), duration: constructionTime)
        
        village.spendResources(type.baseCost)
        village.buildings.append(newBuilding)
        
        engine.village = village
        showingBuildMenu = false
    }
    
    func canUpgrade(_ building: Building) -> Bool {
        guard !building.isUnderConstruction else { return false }
        guard building.level < building.type.maxLevel else { return false }
        guard village.availableBuilders > 0 else { return false }
        return village.canAfford(building.upgradeCost())
    }
    
    func upgrade(_ building: Building) {
        guard canUpgrade(building) else { return }
        guard let index = village.buildings.firstIndex(where: { $0.id == building.id }) else { return }
        
        let upgradeCost = building.upgradeCost()
        let upgradeTime = building.upgradeTime(currentYear: village.gameYear)
        
        village.spendResources(upgradeCost)
        village.buildings[index].startConstruction(currentTime: Date(), duration: upgradeTime)
        
        engine.village = village
    }
    
    func demolish(_ building: Building) {
        guard let index = village.buildings.firstIndex(where: { $0.id == building.id }) else { return }
        
        let returnedResources = building.type.baseCost * 0.5
        village.resources = village.resources + returnedResources
        
        if building.category == .housing {
            let capacityLoss = building.housingCapacity
            if village.population > village.housingCapacity - capacityLoss {
                village.panic += 5
            }
        }
        
        village.buildings.remove(at: index)
        engine.village = village
    }
    
    func repair(_ building: Building) {
        guard building.isDamaged else { return }
        guard let index = village.buildings.firstIndex(where: { $0.id == building.id }) else { return }
        
        let repairCost = building.type.baseCost * building.damageAmount * 0.3
        guard village.canAfford(repairCost) else { return }
        
        village.spendResources(repairCost)
        village.buildings[index].repair()
        
        engine.village = village
    }
    
    // MARK: - Jobs (NOW SAVES PROPERLY)
    
    func assignGuards(_ count: Int) {
        let maxAssignable = village.population - village.scientists - village.farmers
        let newGuards = max(0, min(count, maxAssignable))
        village.guards = newGuards
        engine.village = village
        forceSave() // Immediate save for job changes
    }
    
    func assignScientists(_ count: Int) {
        guard village.hasDiscovery(.scholars) else { return }
        let maxAssignable = village.population - village.guards - village.farmers
        let newScientists = max(0, min(count, maxAssignable))
        village.scientists = newScientists
        engine.village = village
        forceSave()
    }
    
    func assignFarmers(_ count: Int) {
        let maxAssignable = village.population - village.guards - village.scientists
        let newFarmers = max(0, min(count, maxAssignable))
        village.farmers = newFarmers
        engine.village = village
        forceSave()
    }
    
    // MARK: - Saving
    
    func forceSave() {
        do {
            try SaveManager.shared.save(village)
        } catch {
            print("Save failed: \(error)")
        }
    }
    
    // MARK: - New Game / Continue
    
    func startNewGame(name: String, seed: UInt64? = nil) {
        let newVillage = Village(name: name, seed: seed)
        self.village = newVillage
        self.engine = GameEngine(village: newVillage, timeManager: timeManager)
        setupBindings()
        forceSave()
    }
    
    func startLegacyGame(from extinctVillage: Village) {
        let legacyBonuses = LegacyBonuses.from(previousVillage: extinctVillage)
        var newVillage = Village(name: "\(extinctVillage.name) II")
        newVillage.isLegacyMode = true
        newVillage.legacyBonuses = legacyBonuses
        newVillage.resources = newVillage.resources + legacyBonuses.startingResources
        
        for discovery in legacyBonuses.startingDiscoveries {
            newVillage.discoveryState.completeDiscovery(discovery)
        }
        
        newVillage.addChronicleEntry(
            title: "Legacy Begins",
            description: legacyBonuses.chronicleSummary
        )
        
        self.village = newVillage
        self.engine = GameEngine(village: newVillage, timeManager: timeManager)
        setupBindings()
        forceSave()
    }
    
    // MARK: - Ad Stubs
    
    func watchAdForBuildTimeReduction(building: Building) {
        guard let index = village.buildings.firstIndex(where: { $0.id == building.id }) else { return }
        guard village.buildings[index].isUnderConstruction,
              let endTime = village.buildings[index].constructionEndTime else { return }
        
        let reduction = GameConstants.adBuildTimeReductionHours * 3600
        village.buildings[index].constructionEndTime = endTime.addingTimeInterval(-reduction)
        
        if village.buildings[index].constructionEndTime! <= Date() {
            village.buildings[index].completeConstruction()
        }
        
        engine.village = village
    }
    
    func watchAdForGuildMarks() {
        village.resources.guildMarks += 5
        engine.village = village
    }
    
    func watchAdsForContinue() {
        guard village.isExtinct else { return }
        
        village.isExtinct = false
        village.population = 5
        village.health = 50
        village.panic = 30
        village.morale = 40
        
        village.addChronicleEntry(
            title: "Second Chance",
            description: "Against all odds, survivors returned to rebuild."
        )
        
        engine.village = village
        forceSave()
    }
    
    
    func convertGuildMarks(to resource: ConvertibleResource, amount: Int) {
        guard village.resources.guildMarks >= amount else { return }
        
        let resourceAmount = Double(amount) * 100.0
        
        village.resources.guildMarks -= amount
        
        switch resource {
        case .food:
            village.foodStorage.add(resourceAmount, type: .fresh)
        case .water:
            village.resources.water += resourceAmount
        case .firewood:
            village.resources.firewood += resourceAmount
        case .salt:
            village.resources.salt += resourceAmount
        case .stone:
            village.resources.stone += resourceAmount
        case .metal:
            village.resources.metal += resourceAmount
        }
        
        engine.village = village
        forceSave()
    }
    
}

