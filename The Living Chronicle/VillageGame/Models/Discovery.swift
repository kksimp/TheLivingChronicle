import Foundation

// MARK: - Discovery
enum Discovery: String, Codable, CaseIterable, Identifiable {
    // Era 0 - Founding (defaults)
    case basicSurvival = "basic_survival"
    
    // Era 1 - Early Settlement
    case temporaryShelter = "temporary_shelter"
    case agriculture = "agriculture"
    case saltPreservation = "salt_preservation"
    case fireManagement = "fire_management"
    
    // Era 2 - Organized Village
    case permanentHousing = "permanent_housing"
    case wells = "wells"
    case rudimentaryDefense = "rudimentary_defense"
    case smokePreservation = "smoke_preservation"
    case organizedFaith = "organized_faith"
    
    // Era 3 - Structured Society
    case stoneworking = "stoneworking"
    case marketEconomy = "market_economy"
    case herbalMedicine = "herbal_medicine"
    
    // Era 4 - Early Science
    case scholars = "scholars"
    case sanitation = "sanitation"
    case organizedGovernance = "organized_governance"
    
    // Era 5 - Medical Revolution
    case germTheory = "germ_theory"
    case vaccination = "vaccination"
    
    // Era 6 - Industrial Transition
    case electricity = "electricity"
    case refrigeration = "refrigeration"
    case industrialAgriculture = "industrial_agriculture"
    
    // Era 7 - Modernization
    case insulation = "insulation"
    case airConditioning = "air_conditioning"
    case treatedWater = "treated_water"
    
    // Era 8 - Enlightenment
    case secularGovernance = "secular_governance"
    case advancedPreservation = "advanced_preservation"
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .basicSurvival: return "Basic Survival"
        case .temporaryShelter: return "Temporary Shelter"
        case .agriculture: return "Agriculture"
        case .saltPreservation: return "Salt Preservation"
        case .fireManagement: return "Fire Management"
        case .permanentHousing: return "Permanent Housing"
        case .wells: return "Wells"
        case .rudimentaryDefense: return "Rudimentary Defense"
        case .smokePreservation: return "Smoke Preservation"
        case .organizedFaith: return "Organized Faith"
        case .stoneworking: return "Stoneworking"
        case .marketEconomy: return "Market Economy"
        case .herbalMedicine: return "Herbal Medicine"
        case .scholars: return "Scholars"
        case .sanitation: return "Sanitation"
        case .organizedGovernance: return "Organized Governance"
        case .germTheory: return "Germ Theory"
        case .vaccination: return "Vaccination"
        case .electricity: return "Electricity"
        case .refrigeration: return "Refrigeration"
        case .industrialAgriculture: return "Industrial Agriculture"
        case .insulation: return "Insulation"
        case .airConditioning: return "Air Conditioning"
        case .treatedWater: return "Treated Water"
        case .secularGovernance: return "Secular Governance"
        case .advancedPreservation: return "Advanced Preservation"
        }
    }
    
    var description: String {
        switch self {
        case .basicSurvival: return "The fundamental skills needed to survive in the wild."
        case .temporaryShelter: return "Basic tents provide protection from the elements."
        case .agriculture: return "Farming allows sustainable food production."
        case .saltPreservation: return "Salt can preserve food for longer periods."
        case .fireManagement: return "Controlled fire provides warmth and safety."
        case .permanentHousing: return "Sturdy huts offer better protection."
        case .wells: return "Wells provide cleaner, more reliable water."
        case .rudimentaryDefense: return "Watchtowers and guards protect against threats."
        case .smokePreservation: return "Smoking food extends its lifespan."
        case .organizedFaith: return "Religion brings the community together."
        case .stoneworking: return "Stone construction enables stronger buildings."
        case .marketEconomy: return "Trade brings prosperity and resources."
        case .herbalMedicine: return "Natural remedies help treat illness."
        case .scholars: return "Dedicated thinkers accelerate progress."
        case .sanitation: return "Clean practices reduce disease spread."
        case .organizedGovernance: return "Formal leadership improves efficiency."
        case .germTheory: return "Understanding disease enables prevention."
        case .vaccination: return "Immunity protects the population."
        case .electricity: return "Power transforms civilization."
        case .refrigeration: return "Cold storage revolutionizes food preservation."
        case .industrialAgriculture: return "Mechanized farming increases yields."
        case .insulation: return "Better insulation reduces heating needs."
        case .airConditioning: return "Climate control improves comfort."
        case .treatedWater: return "Purified water eliminates waterborne illness."
        case .secularGovernance: return "Rational governance modernizes society."
        case .advancedPreservation: return "Freeze drying and canning perfect preservation."
        }
    }
    
    var era: Era {
        switch self {
        case .basicSurvival:
            return .founding
        case .temporaryShelter, .agriculture, .saltPreservation, .fireManagement:
            return .earlySettlement
        case .permanentHousing, .wells, .rudimentaryDefense, .smokePreservation, .organizedFaith:
            return .organizedVillage
        case .stoneworking, .marketEconomy, .herbalMedicine:
            return .structuredSociety
        case .scholars, .sanitation, .organizedGovernance:
            return .earlyScience
        case .germTheory, .vaccination:
            return .medicalRevolution
        case .electricity, .refrigeration, .industrialAgriculture:
            return .industrialTransition
        case .insulation, .airConditioning, .treatedWater:
            return .modernization
        case .secularGovernance, .advancedPreservation:
            return .enlightenment
        }
    }
    
    var prerequisites: [Discovery] {
        switch self {
        case .basicSurvival: return []
        case .temporaryShelter: return []  // Population >= 10
        case .agriculture: return []  // Survive 1 year, Population >= 10
        case .saltPreservation: return []  // Food spoilage event + salt available
        case .fireManagement: return []  // First winter survived
        case .permanentHousing: return [.fireManagement]  // + stable food
        case .wells: return [.permanentHousing]
        case .rudimentaryDefense: return []  // Population >= 20
        case .smokePreservation: return [.saltPreservation]  // + winter food pressure
        case .organizedFaith: return []  // Population >= 30
        case .stoneworking: return [.permanentHousing]  // + quarry access
        case .marketEconomy: return []  // Population >= 50
        case .herbalMedicine: return [.smokePreservation]  // + disease survived
        case .scholars: return [.marketEconomy]  // + pop >= 75, low panic
        case .sanitation: return [.wells, .herbalMedicine]  // + knowledge
        case .organizedGovernance: return [.marketEconomy, .scholars]
        case .germTheory: return [.sanitation, .scholars]
        case .vaccination: return [.germTheory]
        case .electricity: return [.scholars]  // + metalworking implied
        case .refrigeration: return [.electricity, .germTheory]
        case .industrialAgriculture: return [.refrigeration]
        case .insulation: return [.electricity]
        case .airConditioning: return [.insulation]
        case .treatedWater: return [.sanitation, .electricity]
        case .secularGovernance: return [.vaccination]  // + high education
        case .advancedPreservation: return [.refrigeration]
        }
    }
    
    var unlocksBuildings: [BuildingType] {
        switch self {
        case .basicSurvival: return [.groundShelter]
        case .temporaryShelter: return [.tent]
        case .agriculture: return [.farm, .orchard]
        case .saltPreservation: return [.saltStorehouse]
        case .fireManagement: return [.woodpile]
        case .permanentHousing: return [.hut]
        case .wells: return [.well]
        case .rudimentaryDefense: return [.watchtower]
        case .smokePreservation: return [.smokehouse]
        case .organizedFaith: return [.shrine, .church]
        case .stoneworking: return [.stoneHome, .quarry, .stoneWall]
        case .marketEconomy: return [.market]
        case .herbalMedicine: return [.herbalist]
        case .scholars: return [.scholarsHut]
        case .sanitation: return []
        case .organizedGovernance: return [.townHall]
        case .germTheory: return []
        case .vaccination: return [.medicalHall]
        case .electricity: return []
        case .refrigeration: return [.refrigeratedStorage]
        case .industrialAgriculture: return []
        case .insulation: return [.insulatedHouse]
        case .airConditioning: return [.houseWithAC]
        case .treatedWater: return []
        case .secularGovernance: return []
        case .advancedPreservation: return []
        }
    }
    
    var baseKnowledgeCost: Double {
        switch era {
        case .founding: return 0
        case .earlySettlement: return 0  // Emergent discoveries
        case .organizedVillage: return 0  // Guided discoveries
        case .structuredSociety: return 0  // Guided discoveries
        case .earlyScience: return 50
        case .medicalRevolution: return 100
        case .industrialTransition: return 150
        case .modernization: return 200
        case .enlightenment: return 300
        }
    }
}

// MARK: - Discovery Progress
struct DiscoveryProgress: Codable {
    var discovery: Discovery
    var progress: Double  // 0.0 to 1.0
    var isCompleted: Bool
    var completedDate: Date?
    
    init(discovery: Discovery) {
        self.discovery = discovery
        self.progress = 0.0
        self.isCompleted = false
        self.completedDate = nil
    }
    
    mutating func addProgress(_ amount: Double) {
        guard !isCompleted else { return }
        progress = min(1.0, progress + amount)
        if progress >= 1.0 {
            isCompleted = true
            completedDate = Date()
        }
    }
}

// MARK: - Discovery Trigger Conditions
struct DiscoveryTrigger {
    let discovery: Discovery
    let condition: (Village) -> Bool
    
    static let allTriggers: [DiscoveryTrigger] = [
        // Era 1
        DiscoveryTrigger(discovery: .temporaryShelter) { village in
            village.population >= 10
        },
        DiscoveryTrigger(discovery: .agriculture) { village in
            village.yearsSurvived >= 1 && village.population >= 10
        },
        DiscoveryTrigger(discovery: .saltPreservation) { village in
            village.hasExperiencedFoodSpoilage && village.resources.salt > 5
        },
        DiscoveryTrigger(discovery: .fireManagement) { village in
            village.wintersSurvived >= 1
        },
        
        // Era 2
        DiscoveryTrigger(discovery: .permanentHousing) { village in
            village.hasDiscovery(.fireManagement) && village.hasFoodSurplus
        },
        DiscoveryTrigger(discovery: .wells) { village in
            village.hasDiscovery(.permanentHousing)
        },
        DiscoveryTrigger(discovery: .rudimentaryDefense) { village in
            village.population >= 20
        },
        DiscoveryTrigger(discovery: .smokePreservation) { village in
            village.hasDiscovery(.saltPreservation) && village.winterFoodPressure
        },
        DiscoveryTrigger(discovery: .organizedFaith) { village in
            village.population >= 30
        },
        
        // Era 3
        DiscoveryTrigger(discovery: .stoneworking) { village in
            village.hasDiscovery(.permanentHousing) && village.hasBuilding(.quarry)
        },
        DiscoveryTrigger(discovery: .marketEconomy) { village in
            village.population >= 50
        },
        DiscoveryTrigger(discovery: .herbalMedicine) { village in
            village.hasDiscovery(.smokePreservation) && village.hasExperiencedDisease
        },
        
        // Era 4+ require scientists and knowledge
        DiscoveryTrigger(discovery: .scholars) { village in
            village.population >= 75 && 
            village.panic < 30 && 
            village.hasDiscovery(.marketEconomy)
        },
        DiscoveryTrigger(discovery: .sanitation) { village in
            village.hasDiscovery(.wells) && 
            village.hasDiscovery(.herbalMedicine) &&
            village.resources.knowledge >= Discovery.sanitation.baseKnowledgeCost
        },
        DiscoveryTrigger(discovery: .organizedGovernance) { village in
            village.hasDiscovery(.marketEconomy) && 
            village.hasDiscovery(.scholars)
        }
    ]
}

// MARK: - Discovery State
struct DiscoveryState: Codable {
    var completed: Set<Discovery>
    var inProgress: [Discovery: Double]  // Discovery -> progress (0-1)
    var rumorProgress: [Discovery: Double]  // Pre-science "rumor" progress
    
    init() {
        self.completed = [.basicSurvival]
        self.inProgress = [:]
        self.rumorProgress = [:]
    }
    
    func hasDiscovery(_ discovery: Discovery) -> Bool {
        completed.contains(discovery)
    }
    
    func canUnlock(_ discovery: Discovery) -> Bool {
        guard !hasDiscovery(discovery) else { return false }
        return discovery.prerequisites.allSatisfy { hasDiscovery($0) }
    }
    
    func availableBuildings() -> Set<BuildingType> {
        var buildings = Set<BuildingType>()
        for discovery in completed {
            buildings.formUnion(discovery.unlocksBuildings)
        }
        return buildings
    }
    
    mutating func completeDiscovery(_ discovery: Discovery) {
        completed.insert(discovery)
        inProgress.removeValue(forKey: discovery)
        rumorProgress.removeValue(forKey: discovery)
    }
    
    mutating func addProgress(to discovery: Discovery, amount: Double) {
        guard !hasDiscovery(discovery) else { return }
        
        if discovery.era < .earlyScience {
            // Pre-science: use rumor progress
            let current = rumorProgress[discovery] ?? 0
            rumorProgress[discovery] = min(1.0, current + amount)
            if rumorProgress[discovery]! >= 1.0 {
                completeDiscovery(discovery)
            }
        } else {
            // Post-science: use knowledge-based progress
            let current = inProgress[discovery] ?? 0
            inProgress[discovery] = min(1.0, current + amount)
            if inProgress[discovery]! >= 1.0 {
                completeDiscovery(discovery)
            }
        }
    }
}
