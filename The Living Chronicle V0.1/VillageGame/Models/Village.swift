import Foundation

// MARK: - Village
struct Village: Codable, Identifiable {
    let id: UUID
    var name: String
    var seed: UInt64
    
    // Time
    var gameYear: Int
    var currentSeason: Season
    var dayInSeason: Int  // 0-based, maps to ~1.75 real days per season
    var lastUpdateTime: Date
    var lastVerifiedTime: Date?
    var isTimeVerified: Bool
    
    // Population
    var population: Int
    var maxPopulation: Int
    var health: Double  // 0-100
    var morale: Double  // 0-100
    var panic: Double   // 0-100
    
    // Jobs
        var guards: Int
        var scientists: Int
        var farmers: Int
        var builders: Int
    
    
    // Resources
    var resources: Resources
    var foodStorage: FoodStorage
    
    // Buildings
    var buildings: [Building]
    
    // Discoveries
    var discoveryState: DiscoveryState
    
    // Threats
    var currentThreatPhase: ThreatPhase
    var threatFaction: FactionType?
    var perceivedWealth: Double
    
    // Weather
    var currentWeather: Weather
    
    // Stats tracking
    var yearsSurvived: Int
    var wintersSurvived: Int
    var hasExperiencedFoodSpoilage: Bool
    var hasExperiencedDisease: Bool
    var totalDeaths: Int
    var raidsRepelled: Int
    var raidsSuffered: Int
    
    // Chronicle
    var chronicle: [ChronicleEntry]
    
    // Legacy
    var isLegacyMode: Bool
    var legacyBonuses: LegacyBonuses?
    
    // Flags
    var isExtinct: Bool
    var gracePeriodsRemaining: Int  // Year 1 protection
    
    init(name: String, seed: UInt64? = nil) {
        self.id = UUID()
        self.name = name
        self.seed = seed ?? UInt64.random(in: 0...UInt64.max)
        
        // Time
        self.gameYear = GameConstants.startingYear
        self.currentSeason = .spring
        self.dayInSeason = 0
        self.lastUpdateTime = Date()
        self.lastVerifiedTime = nil
        self.isTimeVerified = false
        
        // Population
        self.population = GameConstants.startingPopulation
        self.maxPopulation = GameConstants.startingPopulation * 2
        self.health = 80.0
        self.morale = 60.0
        self.panic = 10.0
        
        // Jobs (everyone starts as general workers)
        self.guards = 0
        self.scientists = 0
        self.farmers = 0
        self.builders = GameConstants.startingBuilders
        
        // Resources
        self.resources = Resources()
        self.foodStorage = FoodStorage(fresh: GameConstants.startingFood)
        
        // Buildings - start with ground shelters
        self.buildings = [
            Building(type: .groundShelter, level: 1),
            Building(type: .groundShelter, level: 1),
            Building(type: .groundShelter, level: 1),
            Building(type: .groundShelter, level: 1),
            Building(type: .groundShelter, level: 1)
        ]
        
        // Discoveries
        self.discoveryState = DiscoveryState()
        
        // Threats
        self.currentThreatPhase = .none
        self.threatFaction = nil
        self.perceivedWealth = 0
        
        // Weather
        self.currentWeather = .mild
        
        // Stats
        self.yearsSurvived = 0
        self.wintersSurvived = 0
        self.hasExperiencedFoodSpoilage = false
        self.hasExperiencedDisease = false
        self.totalDeaths = 0
        self.raidsRepelled = 0
        self.raidsSuffered = 0
        
        // Chronicle
        self.chronicle = [
            ChronicleEntry(
                year: GameConstants.startingYear,
                season: .spring,
                title: "A New Beginning",
                description: "A small group of settlers have founded \(name). The future is uncertain, but hope remains."
            )
        ]
        
        // Legacy
        self.isLegacyMode = false
        self.legacyBonuses = nil
        
        // Flags
        self.isExtinct = false
        self.gracePeriodsRemaining = 4  // First year (4 seasons) of protection
    }
    
    // MARK: - Computed Properties
    
    var currentEra: Era {
        // Determine era based on discoveries
        if discoveryState.hasDiscovery(.secularGovernance) || discoveryState.hasDiscovery(.advancedPreservation) {
            return .enlightenment
        } else if discoveryState.hasDiscovery(.insulation) || discoveryState.hasDiscovery(.airConditioning) {
            return .modernization
        } else if discoveryState.hasDiscovery(.electricity) || discoveryState.hasDiscovery(.refrigeration) {
            return .industrialTransition
        } else if discoveryState.hasDiscovery(.germTheory) || discoveryState.hasDiscovery(.vaccination) {
            return .medicalRevolution
        } else if discoveryState.hasDiscovery(.scholars) {
            return .earlyScience
        } else if discoveryState.hasDiscovery(.stoneworking) || discoveryState.hasDiscovery(.marketEconomy) {
            return .structuredSociety
        } else if discoveryState.hasDiscovery(.permanentHousing) || discoveryState.hasDiscovery(.wells) {
            return .organizedVillage
        } else if discoveryState.hasDiscovery(.temporaryShelter) || discoveryState.hasDiscovery(.agriculture) {
            return .earlySettlement
        }
        return .founding
    }
    
    var populationProductionBonus: Double {
        let bonus = Double(population) * GameConstants.productionBonusPerVillager
        return min(bonus, GameConstants.maxProductionBonus)
    }
    
    var guardRatio: Double {
        guard population > 0 else { return 0 }
        return Double(guards) / Double(population)
    }
    
    var isPoliceState: Bool {
        guardRatio > GameConstants.policeStateThreshold
    }
    
    var isSeverePoliceState: Bool {
        guardRatio > GameConstants.severePoliceStateThreshold
    }
    
    var guardProtection: Double {
        let rawProtection = Double(guards) * GameConstants.guardProtectionPerGuard
        return min(rawProtection, GameConstants.maxGuardProtection)
    }
    
    var hasFoodSurplus: Bool {
        let consumption = baseConsumption.foodPerTick * Double(population)
        return foodStorage.total > consumption * 24  // More than a day's worth
    }
    
    var winterFoodPressure: Bool {
        currentSeason == .winter && foodStorage.total < Double(population) * 10
    }
    
    var daysOfFoodRemaining: Double {
        let dailyConsumption = baseConsumption.foodPerTick * Double(population) * 4  // 4 ticks per day roughly
        guard dailyConsumption > 0 else { return Double.infinity }
        return foodStorage.total / dailyConsumption
    }
    
    var housingCapacity: Int {
        buildings
            .filter { $0.category == .housing && !$0.isUnderConstruction }
            .reduce(0) { $0 + $1.housingCapacity }
    }
    
    var availableBuilders: Int {
        let inUse = buildings.filter { $0.isUnderConstruction }.count
        return max(0, builders - inUse)
    }
    
    var baseConsumption: ResourceConsumption {
        var consumption = ResourceConsumption()
        consumption.foodPerTick = 0.5 * currentSeason.waterConsumptionModifier
        consumption.waterPerTick = 0.3 * currentSeason.waterConsumptionModifier
        consumption.firewoodPerTick = 0.2 * currentSeason.firewoodConsumptionModifier
        return consumption
    }
    
    var totalDefenseRating: Double {
        var defense = 0.0
        
        // Guard protection
        defense += guardProtection
        
        // Building defenses
        for building in buildings where !building.isUnderConstruction {
            switch building.type {
            case .watchtower:
                defense += building.defenseBonus()
            case .palisade:
                defense += building.defenseBonus() * 1.5
            case .stoneWall:
                defense += building.defenseBonus() * 2.0
            default:
                break
            }
        }
        
        return min(defense, 0.80)  // Cap at 80% reduction
    }
    
    // MARK: - Helper Methods
    
    func hasDiscovery(_ discovery: Discovery) -> Bool {
        discoveryState.hasDiscovery(discovery)
    }
    
    func hasBuilding(_ type: BuildingType) -> Bool {
        buildings.contains { $0.type == type && !$0.isUnderConstruction }
    }
    
    func buildingCount(_ type: BuildingType) -> Int {
        buildings.filter { $0.type == type && !$0.isUnderConstruction }.count
    }
    
    func canBuild(_ type: BuildingType) -> Bool {
        discoveryState.availableBuildings().contains(type)
    }
    
    func canAfford(_ cost: Resources) -> Bool {
        resources.food >= cost.food &&
        resources.water >= cost.water &&
        resources.firewood >= cost.firewood &&
        resources.salt >= cost.salt &&
        resources.stone >= cost.stone &&
        resources.metal >= cost.metal &&
        resources.knowledge >= cost.knowledge &&
        resources.guildMarks >= cost.guildMarks
    }
    
    mutating func spendResources(_ cost: Resources) {
        resources = resources - cost
        resources.clampNonNegative()
    }
    
    mutating func addChronicleEntry(title: String, description: String) {
        let entry = ChronicleEntry(
            year: gameYear,
            season: currentSeason,
            title: title,
            description: description
        )
        chronicle.append(entry)
        
        // Keep chronicle manageable
        if chronicle.count > 500 {
            chronicle.removeFirst(100)
        }
    }
}

// MARK: - Chronicle Entry
struct ChronicleEntry: Codable, Identifiable {
    let id: UUID
    let year: Int
    let season: Season
    let title: String
    let description: String
    let timestamp: Date
    
    init(year: Int, season: Season, title: String, description: String) {
        self.id = UUID()
        self.year = year
        self.season = season
        self.title = title
        self.description = description
        self.timestamp = Date()
    }
    
    var displayDate: String {
        "\(season.name) \(year)"
    }
}

// MARK: - Legacy Bonuses
struct LegacyBonuses: Codable {
    var productionBonus: Double  // 5-10%
    var startingResources: Resources
    var startingDiscoveries: Set<Discovery>
    var chronicleSummary: String
    
    static func from(previousVillage: Village) -> LegacyBonuses {
        // Calculate bonus based on how well the village did
        let yearsSurvived = previousVillage.yearsSurvived
        let productionBonus = min(0.10, 0.05 + Double(yearsSurvived) * 0.001)
        
        // Carry forward some resources
        let resourceBonus = previousVillage.resources * 0.1
        
        // Carry forward early discoveries
        let inheritedDiscoveries = previousVillage.discoveryState.completed.filter { 
            $0.era <= .organizedVillage 
        }
        
        return LegacyBonuses(
            productionBonus: productionBonus,
            startingResources: resourceBonus,
            startingDiscoveries: inheritedDiscoveries,
            chronicleSummary: "Descendants of \(previousVillage.name), which survived \(yearsSurvived) years."
        )
    }
}
