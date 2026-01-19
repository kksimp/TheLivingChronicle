import Foundation

// MARK: - Resources
struct Resources: Codable, Equatable {
    var food: Double
    var water: Double
    var firewood: Double
    var salt: Double
    var stone: Double
    var metal: Double
    var knowledge: Double
    var guildMarks: Int
    
    init(
        food: Double = GameConstants.startingFood,
        water: Double = GameConstants.startingWater,
        firewood: Double = GameConstants.startingFirewood,
        salt: Double = GameConstants.startingSalt,
        stone: Double = GameConstants.startingStone,
        metal: Double = GameConstants.startingMetal,
        knowledge: Double = GameConstants.startingKnowledge,
        guildMarks: Int = GameConstants.startingGuildMarks
    ) {
        self.food = food
        self.water = water
        self.firewood = firewood
        self.salt = salt
        self.stone = stone
        self.metal = metal
        self.knowledge = knowledge
        self.guildMarks = guildMarks
    }
    
    mutating func clampNonNegative() {
        food = max(0, food)
        water = max(0, water)
        firewood = max(0, firewood)
        salt = max(0, salt)
        stone = max(0, stone)
        metal = max(0, metal)
        knowledge = max(0, knowledge)
        guildMarks = max(0, guildMarks)
    }
    
    static func + (lhs: Resources, rhs: Resources) -> Resources {
        Resources(
            food: lhs.food + rhs.food,
            water: lhs.water + rhs.water,
            firewood: lhs.firewood + rhs.firewood,
            salt: lhs.salt + rhs.salt,
            stone: lhs.stone + rhs.stone,
            metal: lhs.metal + rhs.metal,
            knowledge: lhs.knowledge + rhs.knowledge,
            guildMarks: lhs.guildMarks + rhs.guildMarks
        )
    }
    
    static func - (lhs: Resources, rhs: Resources) -> Resources {
        Resources(
            food: lhs.food - rhs.food,
            water: lhs.water - rhs.water,
            firewood: lhs.firewood - rhs.firewood,
            salt: lhs.salt - rhs.salt,
            stone: lhs.stone - rhs.stone,
            metal: lhs.metal - rhs.metal,
            knowledge: lhs.knowledge - rhs.knowledge,
            guildMarks: lhs.guildMarks - rhs.guildMarks
        )
    }
    
    static func * (lhs: Resources, rhs: Double) -> Resources {
        Resources(
            food: lhs.food * rhs,
            water: lhs.water * rhs,
            firewood: lhs.firewood * rhs,
            salt: lhs.salt * rhs,
            stone: lhs.stone * rhs,
            metal: lhs.metal * rhs,
            knowledge: lhs.knowledge * rhs,
            guildMarks: Int(Double(lhs.guildMarks) * rhs)
        )
    }
}

// MARK: - Food Storage
struct FoodStorage: Codable {
    var fresh: Double = 0
    var preserved: Double = 0
    var salted: Double = 0
    var smoked: Double = 0
    var refrigerated: Double = 0
    var industrial: Double = 0
    
    var total: Double {
        fresh + preserved + salted + smoked + refrigerated + industrial
    }
    
    mutating func add(_ amount: Double, type: FoodType) {
        switch type {
        case .fresh: fresh += amount
        case .preserved: preserved += amount
        case .salted: salted += amount
        case .smoked: smoked += amount
        case .refrigerated: refrigerated += amount
        case .industrial: industrial += amount
        }
    }
    
    mutating func consume(_ amount: Double) -> Double {
        var remaining = amount
        
        // Consume in order: fresh first (spoils fastest), then others
        let consumeOrder: [(keyPath: WritableKeyPath<FoodStorage, Double>, type: FoodType)] = [
            (\.fresh, .fresh),
            (\.preserved, .preserved),
            (\.salted, .salted),
            (\.smoked, .smoked),
            (\.refrigerated, .refrigerated),
            (\.industrial, .industrial)
        ]
        
        for (keyPath, _) in consumeOrder {
            if remaining <= 0 { break }
            let available = self[keyPath: keyPath]
            let consumed = min(available, remaining)
            self[keyPath: keyPath] -= consumed
            remaining -= consumed
        }
        
        return amount - remaining  // Return amount actually consumed
    }
    
    mutating func applySpoilage(hasRefrigeration: Bool, hasSaltStorage: Bool) -> Double {
        var totalSpoiled: Double = 0
        
        // Fresh food spoils
        let freshSpoilage = fresh * FoodType.fresh.spoilageRate
        fresh -= freshSpoilage
        totalSpoiled += freshSpoilage
        
        // Salted food spoilage (reduced if salt storage exists)
        let saltedRate = hasSaltStorage ? FoodType.salted.spoilageRate * 0.5 : FoodType.salted.spoilageRate
        let saltedSpoilage = salted * saltedRate
        salted -= saltedSpoilage
        totalSpoiled += saltedSpoilage
        
        // Smoked food
        let smokedSpoilage = smoked * FoodType.smoked.spoilageRate
        smoked -= smokedSpoilage
        totalSpoiled += smokedSpoilage
        
        // Refrigerated (only works if power exists)
        if hasRefrigeration {
            let refrigeratedSpoilage = refrigerated * FoodType.refrigerated.spoilageRate
            refrigerated -= refrigeratedSpoilage
            totalSpoiled += refrigeratedSpoilage
        } else {
            // Without power, refrigerated food spoils like fresh
            let refrigeratedSpoilage = refrigerated * FoodType.fresh.spoilageRate
            refrigerated -= refrigeratedSpoilage
            totalSpoiled += refrigeratedSpoilage
        }
        
        // Industrial food
        let industrialSpoilage = industrial * FoodType.industrial.spoilageRate
        industrial -= industrialSpoilage
        totalSpoiled += industrialSpoilage
        
        return totalSpoiled
    }
    
    func averageMoraleModifier() -> Double {
        let totalFood = total
        guard totalFood > 0 else { return 0 }
        
        let weightedSum = fresh * FoodType.fresh.moraleModifier +
                         preserved * FoodType.preserved.moraleModifier +
                         salted * FoodType.salted.moraleModifier +
                         smoked * FoodType.smoked.moraleModifier +
                         refrigerated * FoodType.refrigerated.moraleModifier +
                         industrial * FoodType.industrial.moraleModifier
        
        return weightedSum / totalFood
    }
}

// MARK: - Resource Production
struct ResourceProduction: Codable {
    var foodPerTick: Double = 0
    var waterPerTick: Double = 0
    var firewoodPerTick: Double = 0
    var saltPerTick: Double = 0
    var stonePerTick: Double = 0
    var metalPerTick: Double = 0
    var knowledgePerTick: Double = 0
}

// MARK: - Resource Consumption
struct ResourceConsumption: Codable {
    var foodPerTick: Double = 0
    var waterPerTick: Double = 0
    var firewoodPerTick: Double = 0
    
    func scaled(by population: Int) -> ResourceConsumption {
        let pop = Double(population)
        return ResourceConsumption(
            foodPerTick: foodPerTick * pop,
            waterPerTick: waterPerTick * pop,
            firewoodPerTick: firewoodPerTick * pop
        )
    }
}
