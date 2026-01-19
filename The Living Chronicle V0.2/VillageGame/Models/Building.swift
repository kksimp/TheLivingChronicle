import Foundation

// MARK: - Building Type
enum BuildingType: String, Codable, CaseIterable, Identifiable {
    // Housing
    case groundShelter = "ground_shelter"
    case tent = "tent"
    case hut = "hut"
    case stoneHome = "stone_home"
    case insulatedHouse = "insulated_house"
    case houseWithAC = "house_with_ac"
    
    // Production - Early Game
    case campfire = "campfire"
    case gatheringPost = "gathering_post"
    case fishingSpot = "fishing_spot"
    
    // Production - Standard
    case farm = "farm"
    case orchard = "orchard"
    case well = "well"
    case woodpile = "woodpile"
    case quarry = "quarry"
    case mine = "mine"
    
    // Storage
    case granary = "granary"
    case saltStorehouse = "salt_storehouse"
    case smokehouse = "smokehouse"
    case refrigeratedStorage = "refrigerated_storage"
    
    // Defense
    case watchtower = "watchtower"
    case palisade = "palisade"
    case stoneWall = "stone_wall"
    
    // Special
    case shrine = "shrine"
    case church = "church"
    case herbalist = "herbalist"
    case scholarsHut = "scholars_hut"
    case market = "market"
    case townHall = "town_hall"
    case medicalHall = "medical_hall"
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .groundShelter: return "Ground Shelter"
        case .tent: return "Tent"
        case .hut: return "Hut"
        case .stoneHome: return "Stone Home"
        case .insulatedHouse: return "Insulated House"
        case .houseWithAC: return "House with AC"
        case .campfire: return "Campfire"
        case .gatheringPost: return "Gathering Post"
        case .fishingSpot: return "Fishing Spot"
        case .farm: return "Farm"
        case .orchard: return "Orchard"
        case .well: return "Well"
        case .woodpile: return "Woodpile"
        case .quarry: return "Quarry"
        case .mine: return "Mine"
        case .granary: return "Granary"
        case .saltStorehouse: return "Salt Storehouse"
        case .smokehouse: return "Smokehouse"
        case .refrigeratedStorage: return "Refrigerated Storage"
        case .watchtower: return "Watchtower"
        case .palisade: return "Palisade"
        case .stoneWall: return "Stone Wall"
        case .shrine: return "Shrine"
        case .church: return "Church"
        case .herbalist: return "Herbalist"
        case .scholarsHut: return "Scholar's Hut"
        case .market: return "Market"
        case .townHall: return "Town Hall"
        case .medicalHall: return "Medical Hall"
        }
    }
    
    var description: String {
        switch self {
        case .groundShelter: return "Basic bedroll for sleeping outdoors"
        case .tent: return "Simple shelter from the elements"
        case .hut: return "Permanent wooden dwelling"
        case .stoneHome: return "Sturdy stone construction"
        case .insulatedHouse: return "Well-insulated for harsh weather"
        case .houseWithAC: return "Modern climate-controlled home"
        case .campfire: return "Provides warmth and allows cooking"
        case .gatheringPost: return "Collect berries, nuts, and firewood"
        case .fishingSpot: return "Catch fish from nearby waters"
        case .farm: return "Grow crops for food"
        case .orchard: return "Fruit trees for steady food"
        case .well: return "Clean water source"
        case .woodpile: return "Organized firewood storage and collection"
        case .quarry: return "Extract stone for building"
        case .mine: return "Extract metal ore"
        case .granary: return "Store grain and food"
        case .saltStorehouse: return "Preserve food with salt"
        case .smokehouse: return "Smoke meat for preservation"
        case .refrigeratedStorage: return "Modern cold storage"
        case .watchtower: return "Early warning against threats"
        case .palisade: return "Wooden defensive wall"
        case .stoneWall: return "Strong stone fortification"
        case .shrine: return "Small place of worship"
        case .church: return "Center of faith and community"
        case .herbalist: return "Natural medicine and remedies"
        case .scholarsHut: return "Research and learning"
        case .market: return "Trade goods and resources"
        case .townHall: return "Center of governance"
        case .medicalHall: return "Advanced medical care"
        }
    }
    
    var category: BuildingCategory {
        switch self {
        case .groundShelter, .tent, .hut, .stoneHome, .insulatedHouse, .houseWithAC:
            return .housing
        case .campfire, .gatheringPost, .fishingSpot, .farm, .orchard, .well, .woodpile, .quarry, .mine:
            return .production
        case .granary, .saltStorehouse, .smokehouse, .refrigeratedStorage:
            return .storage
        case .watchtower, .palisade, .stoneWall:
            return .defense
        case .shrine, .church, .herbalist, .scholarsHut, .market, .townHall, .medicalHall:
            return .special
        }
    }
    
    var baseConstructionTime: Double {  // In hours
        switch self {
        case .groundShelter: return 0.5
        case .tent: return 1.0
        case .hut: return 2.0
        case .stoneHome: return 4.0
        case .insulatedHouse: return 6.0
        case .houseWithAC: return 8.0
        case .campfire: return 0.25
        case .gatheringPost: return 0.5
        case .fishingSpot: return 0.5
        case .farm: return 2.0
        case .orchard: return 3.0
        case .well: return 2.0
        case .woodpile: return 1.0
        case .quarry: return 4.0
        case .mine: return 5.0
        case .granary: return 2.0
        case .saltStorehouse: return 2.0
        case .smokehouse: return 2.5
        case .refrigeratedStorage: return 6.0
        case .watchtower: return 3.0
        case .palisade: return 4.0
        case .stoneWall: return 8.0
        case .shrine: return 2.0
        case .church: return 5.0
        case .herbalist: return 3.0
        case .scholarsHut: return 4.0
        case .market: return 4.0
        case .townHall: return 6.0
        case .medicalHall: return 8.0
        }
    }
    
    var baseCost: Resources {
        switch self {
        case .groundShelter:
            return Resources(food: 5, water: 0, firewood: 5, salt: 0, stone: 0, metal: 0, knowledge: 0, guildMarks: 0)
        case .tent:
            return Resources(food: 10, water: 0, firewood: 15, salt: 0, stone: 0, metal: 0, knowledge: 0, guildMarks: 0)
        case .hut:
            return Resources(food: 20, water: 0, firewood: 40, salt: 0, stone: 10, metal: 0, knowledge: 0, guildMarks: 0)
        case .stoneHome:
            return Resources(food: 30, water: 0, firewood: 30, salt: 0, stone: 60, metal: 5, knowledge: 0, guildMarks: 0)
        case .insulatedHouse:
            return Resources(food: 40, water: 0, firewood: 20, salt: 0, stone: 80, metal: 20, knowledge: 10, guildMarks: 0)
        case .houseWithAC:
            return Resources(food: 50, water: 0, firewood: 10, salt: 0, stone: 100, metal: 40, knowledge: 20, guildMarks: 0)
        case .campfire:
            return Resources(food: 0, water: 0, firewood: 10, salt: 0, stone: 5, metal: 0, knowledge: 0, guildMarks: 0)
        case .gatheringPost:
            return Resources(food: 5, water: 0, firewood: 15, salt: 0, stone: 0, metal: 0, knowledge: 0, guildMarks: 0)
        case .fishingSpot:
            return Resources(food: 5, water: 0, firewood: 10, salt: 0, stone: 0, metal: 0, knowledge: 0, guildMarks: 0)
        case .farm:
            return Resources(food: 15, water: 10, firewood: 20, salt: 0, stone: 0, metal: 5, knowledge: 0, guildMarks: 0)
        case .orchard:
            return Resources(food: 20, water: 15, firewood: 30, salt: 0, stone: 0, metal: 0, knowledge: 0, guildMarks: 0)
        case .well:
            return Resources(food: 10, water: 0, firewood: 15, salt: 0, stone: 30, metal: 5, knowledge: 0, guildMarks: 0)
        case .woodpile:
            return Resources(food: 5, water: 0, firewood: 10, salt: 0, stone: 5, metal: 0, knowledge: 0, guildMarks: 0)
        case .quarry:
            return Resources(food: 30, water: 10, firewood: 40, salt: 0, stone: 0, metal: 15, knowledge: 0, guildMarks: 0)
        case .mine:
            return Resources(food: 40, water: 15, firewood: 50, salt: 0, stone: 50, metal: 10, knowledge: 0, guildMarks: 0)
        case .granary:
            return Resources(food: 20, water: 0, firewood: 40, salt: 0, stone: 20, metal: 5, knowledge: 0, guildMarks: 0)
        case .saltStorehouse:
            return Resources(food: 15, water: 0, firewood: 30, salt: 10, stone: 15, metal: 0, knowledge: 0, guildMarks: 0)
        case .smokehouse:
            return Resources(food: 20, water: 0, firewood: 50, salt: 5, stone: 20, metal: 5, knowledge: 0, guildMarks: 0)
        case .refrigeratedStorage:
            return Resources(food: 50, water: 20, firewood: 20, salt: 0, stone: 80, metal: 60, knowledge: 30, guildMarks: 0)
        case .watchtower:
            return Resources(food: 20, water: 0, firewood: 40, salt: 0, stone: 30, metal: 10, knowledge: 0, guildMarks: 0)
        case .palisade:
            return Resources(food: 30, water: 0, firewood: 80, salt: 0, stone: 10, metal: 5, knowledge: 0, guildMarks: 0)
        case .stoneWall:
            return Resources(food: 50, water: 10, firewood: 30, salt: 0, stone: 150, metal: 20, knowledge: 5, guildMarks: 0)
        case .shrine:
            return Resources(food: 15, water: 5, firewood: 25, salt: 0, stone: 15, metal: 0, knowledge: 0, guildMarks: 0)
        case .church:
            return Resources(food: 40, water: 10, firewood: 60, salt: 0, stone: 80, metal: 10, knowledge: 0, guildMarks: 0)
        case .herbalist:
            return Resources(food: 25, water: 15, firewood: 30, salt: 5, stone: 20, metal: 5, knowledge: 5, guildMarks: 0)
        case .scholarsHut:
            return Resources(food: 35, water: 10, firewood: 40, salt: 0, stone: 30, metal: 10, knowledge: 0, guildMarks: 0)
        case .market:
            return Resources(food: 40, water: 10, firewood: 50, salt: 0, stone: 40, metal: 15, knowledge: 0, guildMarks: 0)
        case .townHall:
            return Resources(food: 60, water: 20, firewood: 60, salt: 0, stone: 100, metal: 30, knowledge: 10, guildMarks: 0)
        case .medicalHall:
            return Resources(food: 70, water: 30, firewood: 50, salt: 10, stone: 80, metal: 40, knowledge: 40, guildMarks: 0)
        }
    }
    
    var housingCapacity: Int {
        switch self {
        case .groundShelter: return 2
        case .tent: return 3
        case .hut: return 5
        case .stoneHome: return 8
        case .insulatedHouse: return 10
        case .houseWithAC: return 12
        default: return 0
        }
    }
    
    var maxLevel: Int { 10 }
}

// MARK: - Building Category
enum BuildingCategory: String, Codable, CaseIterable {
    case housing = "Housing"
    case production = "Production"
    case storage = "Storage"
    case defense = "Defense"
    case special = "Special"
}

// MARK: - Building
struct Building: Codable, Identifiable {
    let id: UUID
    let type: BuildingType
    var level: Int
    var isUnderConstruction: Bool
    var constructionStartTime: Date?
    var constructionEndTime: Date?
    var isDamaged: Bool
    var damageAmount: Double  // 0.0 to 1.0, where 1.0 is fully damaged
    
    init(type: BuildingType, level: Int = 1) {
        self.id = UUID()
        self.type = type
        self.level = level
        self.isUnderConstruction = false
        self.constructionStartTime = nil
        self.constructionEndTime = nil
        self.isDamaged = false
        self.damageAmount = 0.0
    }
    
    var name: String { type.name }
    var category: BuildingCategory { type.category }
    
    var effectiveLevel: Double {
        let baseLevel = Double(level)
        let damageReduction = isDamaged ? (1.0 - damageAmount * 0.5) : 1.0
        return baseLevel * damageReduction
    }
    
    var housingCapacity: Int {
        let baseCapacity = type.housingCapacity
        return baseCapacity + (level - 1) * (baseCapacity / 2)
    }
    
    func productionBonus() -> Double {
        if level <= 10 {
            return Double(level) * 0.10
        } else {
            return 1.0 + Double(level - 10) * 0.02
        }
    }
    
    func storageCapacityMultiplier() -> Double {
        return 1.0 + Double(level - 1) * 0.25
    }
    
    func defenseBonus() -> Double {
        return Double(level) * 0.05
    }
    
    func maintenanceCost() -> Resources {
        let baseMaintenance = type.baseCost * 0.01
        let levelMultiplier = 1.0 + Double(level - 1) * 0.1
        return baseMaintenance * levelMultiplier
    }
    
    func upgradeCost() -> Resources {
        let levelMultiplier = 1.0 + Double(level) * 0.5
        return type.baseCost * levelMultiplier
    }
    
    func upgradeTime(currentYear: Int) -> TimeInterval {
        let baseTime = type.baseConstructionTime
        let yearFactor = 1.0 + Double(currentYear) / GameConstants.yearDivisor
        let levelFactor = 1.0 + Double(level) * GameConstants.levelMultiplier
        
        let calculatedHours = baseTime * yearFactor * levelFactor
        let clampedHours = min(max(calculatedHours, GameConstants.minUpgradeHours), GameConstants.maxUpgradeHours)
        
        return clampedHours * 3600
    }
    
    mutating func startConstruction(currentTime: Date, duration: TimeInterval) {
        isUnderConstruction = true
        constructionStartTime = currentTime
        constructionEndTime = currentTime.addingTimeInterval(duration)
    }
    
    mutating func completeConstruction() {
        isUnderConstruction = false
        constructionStartTime = nil
        constructionEndTime = nil
        level += 1
    }
    
    mutating func repair() {
        isDamaged = false
        damageAmount = 0.0
    }
    
    mutating func damage(amount: Double) {
        isDamaged = true
        damageAmount = min(1.0, damageAmount + amount)
    }
}

// MARK: - Building Production Stats
extension BuildingType {
    func baseProduction(level: Int) -> ResourceProduction {
        let levelBonus = 1.0 + Double(level - 1) * 0.10
        
        switch self {
        case .campfire:
            return ResourceProduction(
                foodPerTick: 0.3 * levelBonus,
                waterPerTick: 0,
                firewoodPerTick: 0,
                saltPerTick: 0,
                stonePerTick: 0,
                metalPerTick: 0,
                knowledgePerTick: 0
            )
        case .gatheringPost:
            return ResourceProduction(
                foodPerTick: 1.0 * levelBonus,
                waterPerTick: 0,
                firewoodPerTick: 0.5 * levelBonus,
                saltPerTick: 0,
                stonePerTick: 0,
                metalPerTick: 0,
                knowledgePerTick: 0
            )
        case .fishingSpot:
            return ResourceProduction(
                foodPerTick: 1.2 * levelBonus,
                waterPerTick: 0.2 * levelBonus,
                firewoodPerTick: 0,
                saltPerTick: 0,
                stonePerTick: 0,
                metalPerTick: 0,
                knowledgePerTick: 0
            )
        case .farm:
            return ResourceProduction(foodPerTick: 2.0 * levelBonus)
        case .orchard:
            return ResourceProduction(foodPerTick: 1.5 * levelBonus)
        case .well:
            return ResourceProduction(waterPerTick: 3.0 * levelBonus)
        case .woodpile:
            return ResourceProduction(firewoodPerTick: 2.0 * levelBonus)
        case .quarry:
            return ResourceProduction(stonePerTick: 1.0 * levelBonus)
        case .mine:
            return ResourceProduction(metalPerTick: 0.5 * levelBonus)
        case .scholarsHut:
            return ResourceProduction(knowledgePerTick: 0.2 * levelBonus)
        default:
            return ResourceProduction()
        }
    }
    
    func baseStorageCapacity(level: Int) -> Double {
        let levelBonus = 1.0 + Double(level - 1) * 0.25
        
        switch self {
        case .granary: return 200.0 * levelBonus
        case .saltStorehouse: return 100.0 * levelBonus
        case .smokehouse: return 150.0 * levelBonus
        case .refrigeratedStorage: return 300.0 * levelBonus
        default: return 0
        }
    }
}
