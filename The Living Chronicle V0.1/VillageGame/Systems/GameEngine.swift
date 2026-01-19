import Foundation
import Combine

// MARK: - Game Engine
class GameEngine: ObservableObject {
    @Published var village: Village
    @Published var pendingEvents: [GameEvent] = []
    @Published var activeEffects: [ActiveEffect] = []
    @Published var isProcessing: Bool = false
    
    private let timeManager: TimeManager
    private let eventSystem: EventSystem
    private let randomGenerator: SeededRandomGenerator
    
    init(village: Village, timeManager: TimeManager) {
        self.village = village
        self.timeManager = timeManager
        self.eventSystem = EventSystem()
        self.randomGenerator = SeededRandomGenerator(seed: village.seed)
    }
    
    // MARK: - Main Simulation Loop
    
    func processCatchUp() {
        isProcessing = true
        defer { isProcessing = false }
        
        let currentTime = Date()
        let ticks = timeManager.calculateTicksSinceLastUpdate(
            lastUpdate: village.lastUpdateTime,
            currentTime: currentTime
        )
        
        guard ticks > 0 else { return }
        
        // Process ticks in batches to prevent UI freezing
        let batchSize = 50
        var remainingTicks = ticks
        
        while remainingTicks > 0 {
            let ticksToProcess = min(batchSize, remainingTicks)
            for _ in 0..<ticksToProcess {
                processSingleTick()
            }
            remainingTicks -= ticksToProcess
        }
        
        village.lastUpdateTime = currentTime
    }
    
    func processSingleTick() {
        guard !village.isExtinct else { return }
        
        // NEW: Check for construction completion FIRST
        checkConstructionCompletion()
        
        // 1. Advance time
        advanceGameTime()
        
        // 2. Process resource production
        processProduction()
        
        // 3. Process resource consumption
        processConsumption()
        
        // 4. Process spoilage
        processSpoilage()
        
        // 5. Process population (births, deaths)
        processPopulation()
        
        // 6. Process active effects
        processActiveEffects()
        
        // 7. Process threats
        processThreats()
        
        // 8. Check for events
        checkForEvents()
        
        // 9. Check for discoveries
        checkForDiscoveries()
        
        // 10. Update stats
        updateStats()
        
        // 11. Decay panic naturally
        processPanicDecay()
        
        // 12. Check for epoch events
        checkForEpochEvents()
        
        // 13. Update grace period
        if village.gracePeriodsRemaining > 0 {
            // Grace period decreases at season change
        }
    }
    
    private func checkConstructionCompletion() {
        let now = Date()
        
        for index in village.buildings.indices {
            if village.buildings[index].isUnderConstruction,
               let endTime = village.buildings[index].constructionEndTime,
               endTime <= now {
                village.buildings[index].completeConstruction()
                
                // Announce completion
                let building = village.buildings[index]
                let event = GameEvent(
                    type: .minorRepair, // Reuse this type or create new one
                    title: "Construction Complete",
                    message: "\(building.name) has been completed and is now operational.",
                    effects: [],
                    year: village.gameYear,
                    season: village.currentSeason
                )
                pendingEvents.append(event)
            }
        }
    }
    
    // MARK: - Time Advancement
    
    private func advanceGameTime() {
        village.dayInSeason += 1
        
        // Season has ~42 days (168 ticks / 4)
        let daysPerSeason = 42
        
        if village.dayInSeason >= daysPerSeason {
            village.dayInSeason = 0
            advanceSeason()
        }
    }
    
    private func advanceSeason() {
        let previousSeason = village.currentSeason
        
        // Move to next season
        let nextSeasonRaw = (village.currentSeason.rawValue + 1) % 4
        village.currentSeason = Season(rawValue: nextSeasonRaw) ?? .spring
        
        // Year change
        if village.currentSeason == .spring && previousSeason == .winter {
            village.gameYear += 1
            village.yearsSurvived += 1
            
            village.addChronicleEntry(
                title: "Year \(village.gameYear) Begins",
                description: "The village enters its \(village.yearsSurvived + 1)\(ordinalSuffix(village.yearsSurvived + 1)) year."
            )
        }
        
        // Track winter survival
        if previousSeason == .winter {
            village.wintersSurvived += 1
        }
        
        // Grace period countdown
        if village.gracePeriodsRemaining > 0 {
            village.gracePeriodsRemaining -= 1
        }
        
        // Roll new weather for the season
        rollWeather()
    }
    
    private func rollWeather() {
        let roll = randomGenerator.nextDouble()
        
        // Weather distribution varies by season
        switch village.currentSeason {
        case .spring:
            if roll < 0.3 { village.currentWeather = .heavy }
            else if roll < 0.7 { village.currentWeather = .mild }
            else { village.currentWeather = .weak }
        case .summer:
            if roll < 0.05 { village.currentWeather = .dangerous }
            else if roll < 0.2 { village.currentWeather = .weak }
            else { village.currentWeather = .mild }
        case .fall:
            if roll < 0.2 { village.currentWeather = .heavy }
            else if roll < 0.8 { village.currentWeather = .mild }
            else { village.currentWeather = .weak }
        case .winter:
            if roll < 0.1 { village.currentWeather = .dangerous }
            else if roll < 0.4 { village.currentWeather = .heavy }
            else { village.currentWeather = .mild }
        }
    }
    
    // MARK: - Production
    
    private func processProduction() {
        var production = ResourceProduction()
        
        // Calculate production from buildings
        for building in village.buildings where !building.isUnderConstruction {
            let buildingProduction = building.type.baseProduction(level: building.level)
            let efficiency = building.isDamaged ? (1.0 - building.damageAmount * 0.5) : 1.0
            
            production.foodPerTick += buildingProduction.foodPerTick * efficiency
            production.waterPerTick += buildingProduction.waterPerTick * efficiency
            production.firewoodPerTick += buildingProduction.firewoodPerTick * efficiency
            production.saltPerTick += buildingProduction.saltPerTick * efficiency
            production.stonePerTick += buildingProduction.stonePerTick * efficiency
            production.metalPerTick += buildingProduction.metalPerTick * efficiency
            production.knowledgePerTick += buildingProduction.knowledgePerTick * efficiency
        }
        
        // Apply season modifiers
        production.foodPerTick *= village.currentSeason.foodProductionModifier
        
        // Apply weather modifiers
        production.foodPerTick *= village.currentWeather.foodProductionModifier
        
        // Apply population bonus
        let popBonus = 1.0 + village.populationProductionBonus
        production.foodPerTick *= popBonus
        production.waterPerTick *= popBonus
        production.firewoodPerTick *= popBonus
        
        // Apply active effect modifiers
        let productionMod = activeEffectModifier(for: .allProduction)
        let foodProdMod = activeEffectModifier(for: .foodProduction)
        let waterProdMod = activeEffectModifier(for: .waterProduction)
        let firewoodProdMod = activeEffectModifier(for: .firewoodProduction)
        
        production.foodPerTick *= (1.0 + productionMod + foodProdMod)
        production.waterPerTick *= (1.0 + productionMod + waterProdMod)
        production.firewoodPerTick *= (1.0 + productionMod + firewoodProdMod)
        
        // Legacy bonus
        if let legacy = village.legacyBonuses {
            production.foodPerTick *= (1.0 + legacy.productionBonus)
            production.waterPerTick *= (1.0 + legacy.productionBonus)
            production.firewoodPerTick *= (1.0 + legacy.productionBonus)
        }
        
        // Add to resources
        // Food goes to storage as fresh
        village.foodStorage.add(production.foodPerTick, type: .fresh)
        village.resources.water += production.waterPerTick
        village.resources.firewood += production.firewoodPerTick
        village.resources.salt += production.saltPerTick
        village.resources.stone += production.stonePerTick
        village.resources.metal += production.metalPerTick
        village.resources.knowledge += production.knowledgePerTick
    }
    
    // MARK: - Consumption
    
    private func processConsumption() {
        let baseConsumption = village.baseConsumption.scaled(by: village.population)
        
        // Apply active effect modifiers
        let foodConsMod = 1.0 + activeEffectModifier(for: .foodConsumption)
        let waterConsMod = 1.0 + activeEffectModifier(for: .waterConsumption)
        let firewoodConsMod = 1.0 + activeEffectModifier(for: .firewoodConsumption)
        
        let foodNeeded = baseConsumption.foodPerTick * foodConsMod
        let waterNeeded = baseConsumption.waterPerTick * waterConsMod
        let firewoodNeeded = baseConsumption.firewoodPerTick * firewoodConsMod
        
        // Consume food from storage
        let foodConsumed = village.foodStorage.consume(foodNeeded)
        
        // Check for shortages
        if foodConsumed < foodNeeded {
            // Food shortage - health and panic effects
            village.health -= 0.5
            village.panic += 0.2
        }
        
        // Consume water
        if village.resources.water >= waterNeeded {
            village.resources.water -= waterNeeded
        } else {
            village.resources.water = 0
            village.health -= 0.3
            village.panic += 0.1
        }
        
        // Consume firewood (mainly in winter)
        if village.resources.firewood >= firewoodNeeded {
            village.resources.firewood -= firewoodNeeded
        } else if village.currentSeason == .winter {
            // No firewood in winter is deadly
            village.resources.firewood = 0
            village.health -= 2.0
            village.panic += 0.5
        }
    }
    
    // MARK: - Spoilage
    
    private func processSpoilage() {
        let hasRefrigeration = village.hasDiscovery(.refrigeration)
        let hasSaltStorage = village.hasBuilding(.saltStorehouse)
        
        let spoiled = village.foodStorage.applySpoilage(
            hasRefrigeration: hasRefrigeration,
            hasSaltStorage: hasSaltStorage
        )
        
        if spoiled > 5 && !village.hasExperiencedFoodSpoilage {
            village.hasExperiencedFoodSpoilage = true
            // Trigger discovery progress for preservation
            village.discoveryState.addProgress(to: .saltPreservation, amount: 0.1)
        }
    }
    
    // MARK: - Population
    
    private func processPopulation() {
        // Check for deaths due to poor conditions
        if village.health < 20 {
            let deathChance = (20 - village.health) / 100.0
            if randomGenerator.nextDouble() < deathChance {
                let deaths = max(1, Int(Double(village.population) * 0.02))
                village.population -= deaths
                village.totalDeaths += deaths
                village.panic += Double(deaths) * 2
                
                if deaths > 0 {
                    village.addChronicleEntry(
                        title: "Tragedy Strikes",
                        description: "\(deaths) villager\(deaths == 1 ? "" : "s") perished due to harsh conditions."
                    )
                }
            }
        }
        
        // Check for births
        if village.population < village.housingCapacity && village.health > 50 && village.hasFoodSurplus {
            let birthChance = calculateBirthRate()
            if randomGenerator.nextDouble() < birthChance {
                village.population += 1
            }
        }
        
        // Check for extinction
        if village.population <= 0 {
            village.isExtinct = true
            village.addChronicleEntry(
                title: "The End",
                description: "The last villager has perished. \(village.name) is no more."
            )
        }
        
        // Update max population based on housing
        village.maxPopulation = max(village.population, village.housingCapacity)
    }
    
    private func calculateBirthRate() -> Double {
        var rate = 0.001  // Base rate per tick
        
        // Season modifier
        if village.currentSeason == .spring {
            rate *= 1.2
        } else if village.currentSeason == .winter {
            rate *= 0.5
        }
        
        // Food surplus bonus
        if village.daysOfFoodRemaining > 30 {
            rate *= 1.5
        }
        
        // Health modifier
        rate *= village.health / 100.0
        
        // Panic penalty
        rate *= max(0.2, 1.0 - village.panic / 100.0)
        
        // Housing quality bonus
        let avgHousingLevel = village.buildings
            .filter { $0.category == .housing }
            .map { Double($0.level) }
            .reduce(0, +) / max(1, Double(village.buildings.filter { $0.category == .housing }.count))
        rate *= (1.0 + avgHousingLevel * 0.05)
        
        return rate
    }
    
    // MARK: - Active Effects
    
    private func processActiveEffects() {
        // Decrement durations and remove expired effects
        activeEffects = activeEffects.compactMap { effect in
            var updated = effect
            if let duration = updated.remainingDuration {
                updated.remainingDuration = duration - 1
                if updated.remainingDuration! <= 0 {
                    return nil
                }
            }
            return updated
        }
    }
    
    private func activeEffectModifier(for type: EventEffect.EffectType) -> Double {
        activeEffects
            .filter { $0.effect.effectType == type }
            .reduce(0) { $0 + $1.effect.value }
    }
    
    func applyEffect(_ effect: EventEffect) {
        switch effect.effectType {
        case .food:
            if effect.value > 0 {
                village.foodStorage.add(effect.value, type: .fresh)
            } else {
                _ = village.foodStorage.consume(-effect.value)
            }
        case .water:
            village.resources.water += effect.value
        case .firewood:
            village.resources.firewood += effect.value
        case .salt:
            village.resources.salt += effect.value
        case .stone:
            village.resources.stone += effect.value
        case .metal:
            village.resources.metal += effect.value
        case .knowledge:
            village.resources.knowledge += effect.value
        case .guildMarks:
            village.resources.guildMarks += Int(effect.value)
        case .health:
            village.health = max(0, min(100, village.health + effect.value))
        case .morale:
            village.morale = max(0, min(100, village.morale + effect.value))
        case .panic:
            village.panic = max(0, min(100, village.panic + effect.value))
        case .population:
            village.population = max(0, village.population + Int(effect.value))
        case .threatPhase:
            let newPhase = ThreatPhase(rawValue: village.currentThreatPhase.rawValue + Int(effect.value))
            village.currentThreatPhase = newPhase ?? .raidImminent
        case .buildingDamage:
            // Damage a random building
            if let index = village.buildings.indices.randomElement() {
                village.buildings[index].damage(amount: effect.value)
            }
        case .discoveryProgress:
            // Add progress to a relevant discovery
            if let discovery = findNextDiscoveryTarget() {
                village.discoveryState.addProgress(to: discovery, amount: effect.value)
            }
        default:
            // Modifiers that need duration
            if let duration = effect.duration {
                activeEffects.append(ActiveEffect(effect: effect, remainingDuration: duration))
            }
        }
        
        village.resources.clampNonNegative()
    }
    
    private func findNextDiscoveryTarget() -> Discovery? {
        // Find the first discovery the village can work towards
        for discovery in Discovery.allCases {
            if !village.hasDiscovery(discovery) && village.discoveryState.canUnlock(discovery) {
                return discovery
            }
        }
        return nil
    }
    
    // MARK: - Threats
    
    private func processThreats() {
        // Calculate perceived wealth
        village.perceivedWealth = calculatePerceivedWealth()
        
        // Threat escalation based on wealth and time
        if village.currentThreatPhase == .none {
            let threatChance = calculateThreatChance()
            if randomGenerator.nextDouble() < threatChance && village.gracePeriodsRemaining <= 0 {
                village.currentThreatPhase = .rumors
                village.threatFaction = FactionType.allCases.randomElement()
            }
        } else if village.currentThreatPhase == .rumors {
            // Chance to escalate to scouts
            if randomGenerator.nextDouble() < 0.02 {
                village.currentThreatPhase = .scouts
            }
        } else if village.currentThreatPhase == .scouts {
            // Chance to escalate to raid
            if randomGenerator.nextDouble() < 0.01 {
                village.currentThreatPhase = .raidImminent
            }
        }
        
        // Process raid if imminent
        if village.currentThreatPhase == .raidImminent {
            if randomGenerator.nextDouble() < 0.05 {
                executeRaid()
            }
        }
    }
    
    private func calculatePerceivedWealth() -> Double {
        let resourceWealth = village.foodStorage.total + village.resources.salt * 2 + village.resources.metal * 5
        let populationWealth = Double(village.population) * 10
        let timeWealth = Double(village.yearsSurvived) * 5
        return resourceWealth + populationWealth + timeWealth
    }
    
    private func calculateThreatChance() -> Double {
        var chance = 0.001  // Base chance per tick
        
        // Wealth increases threat
        chance += village.perceivedWealth / 100000
        
        // Season modifier
        chance *= village.currentSeason.raidFrequencyModifier
        
        // Defense reduces chance slightly
        chance *= (1.0 - village.totalDefenseRating * 0.5)
        
        return min(0.01, chance)  // Cap at 1% per tick
    }
    
    private func executeRaid() {
        let severity = calculateRaidSeverity()
        let defense = village.totalDefenseRating
        
        let effectiveSeverity = severity * (1.0 - defense)
        
        if effectiveSeverity < 0.3 {
            // Raid repelled
            let smallLoss = village.perceivedWealth * 0.05
            _ = village.foodStorage.consume(smallLoss * 0.5)
            village.resources.salt -= smallLoss * 0.3
            village.resources.firewood -= smallLoss * 0.2
            
            village.raidsRepelled += 1
            village.morale += 2
            village.panic -= 2
            village.currentThreatPhase = .none
            
            let event = GameEvent(
                type: .raidRepelled,
                title: "Raid Repelled",
                message: "The \(village.threatFaction?.rawValue ?? "raiders") tested our walls and fled. We lost some supplies, but the village stands.",
                effects: [],
                year: village.gameYear,
                season: village.currentSeason
            )
            pendingEvents.append(event)
        } else {
            // Raid succeeds
            let foodLoss = Int(village.foodStorage.total * effectiveSeverity * 0.3)
            let saltLoss = Int(village.resources.salt * effectiveSeverity * 0.2)
            let firewoodLoss = Int(village.resources.firewood * effectiveSeverity * 0.2)
            
            _ = village.foodStorage.consume(Double(foodLoss))
            village.resources.salt -= Double(saltLoss)
            village.resources.firewood -= Double(firewoodLoss)
            
            village.raidsSuffered += 1
            village.panic += 6
            village.currentThreatPhase = .none
            
            // Possible building damage
            if effectiveSeverity > 0.5 && randomGenerator.nextDouble() < 0.3 {
                if let index = village.buildings.indices.randomElement() {
                    village.buildings[index].damage(amount: 0.3)
                }
            }
            
            let event = GameEvent(
                type: .raid,
                title: "Village Raided",
                message: "\(village.threatFaction?.rawValue ?? "Raiders") attacked at dawn. We lost \(foodLoss) food, \(saltLoss) salt, and \(firewoodLoss) firewood.",
                effects: [],
                year: village.gameYear,
                season: village.currentSeason
            )
            pendingEvents.append(event)
            
            village.addChronicleEntry(
                title: "Raid of \(village.gameYear)",
                description: "\(village.threatFaction?.rawValue ?? "Raiders") descended upon the village, taking supplies and leaving fear in their wake."
            )
        }
        
        village.resources.clampNonNegative()
    }
    
    private func calculateRaidSeverity() -> Double {
        var severity = 0.5  // Base
        
        // Faction modifier
        switch village.threatFaction {
        case .bandits: severity *= 0.8
        case .deserters: severity *= 1.0
        case .zealots: severity *= 1.1
        case .mercenaries: severity *= 1.3
        case .none: break
        }
        
        // Season modifier
        severity *= village.currentSeason.raidSeverityModifier
        
        // Wealth modifier
        severity *= (1.0 + village.perceivedWealth / 10000)
        
        return min(1.0, severity)
    }
    
    // MARK: - Events
    
    private func checkForEvents() {
        // Only check occasionally
        guard randomGenerator.nextDouble() < 0.01 else { return }
        
        let eligibleTemplates = EventTemplate.allTemplates.filter { $0.condition(village) }
        
        guard !eligibleTemplates.isEmpty else { return }
        
        // Weighted random selection
        let totalWeight = eligibleTemplates.reduce(0) { $0 + $1.weight }
        var roll = randomGenerator.nextDouble() * totalWeight
        
        for template in eligibleTemplates {
            roll -= template.weight
            if roll <= 0 {
                generateEvent(from: template)
                break
            }
        }
    }
    
    private func generateEvent(from template: EventTemplate) {
        let title = template.titles.randomElement() ?? template.titles[0]
        let messageGenerator = template.messages.randomElement() ?? template.messages[0]
        let message = messageGenerator(village)
        let effects = template.baseEffects(village)
        let choices = template.choices?(village)
        
        let event = GameEvent(
            type: template.type,
            title: title,
            message: message,
            effects: effects,
            choices: choices,
            year: village.gameYear,
            season: village.currentSeason
        )
        
        pendingEvents.append(event)
        
        // Apply non-choice effects immediately
        if !event.requiresChoice {
            for effect in effects {
                applyEffect(effect)
            }
        }
    }
    
    // MARK: - Discoveries
    
    private func checkForDiscoveries() {
        for trigger in DiscoveryTrigger.allTriggers {
            if !village.hasDiscovery(trigger.discovery) &&
               village.discoveryState.canUnlock(trigger.discovery) &&
               trigger.condition(village) {
                
                // Add progress for emergent/guided discoveries
                if trigger.discovery.era < .earlyScience {
                    village.discoveryState.addProgress(to: trigger.discovery, amount: 0.01)
                }
                
                // Check if newly completed
                if village.hasDiscovery(trigger.discovery) {
                    announceDiscovery(trigger.discovery)
                }
            }
        }
        
        // Check for scientist-driven discoveries
        if village.hasDiscovery(.scholars) && village.scientists > 0 {
            for discovery in Discovery.allCases {
                if !village.hasDiscovery(discovery) &&
                   village.discoveryState.canUnlock(discovery) &&
                   discovery.era >= .earlyScience {
                    
                    let progressRate = Double(village.scientists) * 0.001
                    let knowledgeCost = discovery.baseKnowledgeCost
                    
                    if village.resources.knowledge >= knowledgeCost {
                        village.discoveryState.addProgress(to: discovery, amount: progressRate)
                        
                        if village.hasDiscovery(discovery) {
                            village.resources.knowledge -= knowledgeCost
                            announceDiscovery(discovery)
                        }
                    }
                }
            }
        }
    }
    
    private func announceDiscovery(_ discovery: Discovery) {
        let event = GameEvent(
            type: .discoveryMade,
            title: "Discovery: \(discovery.name)",
            message: discovery.description,
            effects: [],
            year: village.gameYear,
            season: village.currentSeason
        )
        pendingEvents.append(event)
        
        village.addChronicleEntry(
            title: "Discovery: \(discovery.name)",
            description: "In \(village.currentSeason.name) of \(village.gameYear), the village discovered \(discovery.name). \(discovery.description)"
        )
    }
    
    // MARK: - Epoch Events
    
    private func checkForEpochEvents() {
        for epochEvent in EpochEvent.allEpochEvents {
            if epochEvent.year == village.gameYear && epochEvent.season == village.currentSeason {
                // Check if already triggered (would need tracking)
                triggerEpochEvent(epochEvent)
            }
        }
    }
    
    private func triggerEpochEvent(_ epochEvent: EpochEvent) {
        let event = GameEvent(
            type: .epochEvent,
            title: epochEvent.title,
            message: epochEvent.description,
            effects: epochEvent.baseEffects,
            year: village.gameYear,
            season: village.currentSeason
        )
        
        pendingEvents.append(event)
        
        for effect in epochEvent.baseEffects {
            applyEffect(effect)
        }
        
        village.addChronicleEntry(
            title: epochEvent.title,
            description: "\(epochEvent.year): \(epochEvent.description)"
        )
    }
    
    // MARK: - Stats & Decay
    
    private func updateStats() {
        // Morale from food variety
        let foodMorale = village.foodStorage.averageMoraleModifier() * 10
        village.morale = max(0, min(100, village.morale + foodMorale * 0.01))
        
        // Police state effects
        if village.isPoliceState {
            village.morale -= 0.1
        }
        if village.isSeverePoliceState {
            village.morale -= 0.2
        }
        
        // Religion effects on panic (before Enlightenment)
        if !village.hasDiscovery(.secularGovernance) {
            if village.hasBuilding(.shrine) || village.hasBuilding(.church) {
                village.panic -= 0.05
            }
        }
        
        // Health recovery when conditions are good
        if village.foodStorage.total > Double(village.population) * 10 &&
           village.resources.water > Double(village.population) * 5 {
            village.health = min(100, village.health + 0.1)
        }
    }
    
    private func processPanicDecay() {
        // Panic naturally decays under good conditions
        let consumption = village.baseConsumption.scaled(by: village.population)
        let foodRatio = village.foodStorage.total / max(1, consumption.foodPerTick * Double(village.population) * 24)
        
        if foodRatio > GameConstants.panicDecayFoodThreshold {
            village.panic = max(0, village.panic - 0.1)
        }
        
        // No deaths for a while reduces panic
        // No raids for a season reduces panic
        if village.currentThreatPhase == .none {
            village.panic = max(0, village.panic - 0.05)
        }
    }
    
    // MARK: - Helper
    
    private func ordinalSuffix(_ n: Int) -> String {
        let ones = n % 10
        let tens = (n / 10) % 10
        
        if tens == 1 { return "th" }
        
        switch ones {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
}

// MARK: - Active Effect
struct ActiveEffect: Codable, Identifiable {
    let id: UUID
    let effect: EventEffect
    var remainingDuration: Int?
    
    init(effect: EventEffect, remainingDuration: Int?) {
        self.id = UUID()
        self.effect = effect
        self.remainingDuration = remainingDuration
    }
}

// MARK: - Seeded Random Generator
class SeededRandomGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
    
    func nextDouble() -> Double {
        return Double(next()) / Double(UInt64.max)
    }
    
    func nextInt(max: Int) -> Int {
        return Int(next() % UInt64(max))
    }
}
