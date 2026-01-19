import Foundation

// MARK: - Event System
class EventSystem {
    private var triggeredEpochEvents: Set<Int> = []  // Track by year
    
    // MARK: - Event Salt/Seed System
    
    func calculateEventSeed(
        worldSeed: UInt64,
        villageSeed: UInt64,
        villageName: String,
        utcDay: Int,
        gameYear: Int,
        season: Season,
        population: Int,
        panic: Double
    ) -> UInt64 {
        var hash: UInt64 = worldSeed
        hash ^= villageSeed
        hash ^= hashString(villageName)
        hash ^= UInt64(utcDay) << 16
        hash ^= UInt64(gameYear) << 24
        hash ^= UInt64(season.rawValue) << 32
        hash ^= UInt64(population) << 40
        hash ^= UInt64(panic) << 48
        
        // Mix the hash
        hash = hash &* 0x517cc1b727220a95
        hash ^= hash >> 32
        
        return hash
    }
    
    private func hashString(_ string: String) -> UInt64 {
        var hash: UInt64 = 5381
        for char in string.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(char)
        }
        return hash
    }
    
    // MARK: - Event Selection
    
    func selectRandomEvent(
        from templates: [EventTemplate],
        village: Village,
        seed: UInt64
    ) -> EventTemplate? {
        let eligibleTemplates = templates.filter { $0.condition(village) }
        guard !eligibleTemplates.isEmpty else { return nil }
        
        let generator = SeededRandomGenerator(seed: seed)
        let totalWeight = eligibleTemplates.reduce(0) { $0 + $1.weight }
        var roll = generator.nextDouble() * totalWeight
        
        for template in eligibleTemplates {
            roll -= template.weight
            if roll <= 0 {
                return template
            }
        }
        
        return eligibleTemplates.last
    }
    
    // MARK: - Epoch Event Checking
    
    func checkEpochEvent(year: Int, season: Season) -> EpochEvent? {
        guard !triggeredEpochEvents.contains(year) else { return nil }
        
        for event in EpochEvent.allEpochEvents {
            if event.year == year && event.season == season {
                triggeredEpochEvents.insert(year)
                return event
            }
        }
        
        return nil
    }
    
    // MARK: - Event Effect Scaling
    
    func scaleEffects(_ effects: [EventEffect], for village: Village) -> [EventEffect] {
        return effects.map { effect in
            let scaled = effect
            
            // Scale resource effects by population
            switch effect.effectType {
            case .food, .water, .firewood:
                let popScale = Double(village.population) / 50.0  // Normalize around 50 pop
                return EventEffect(
                    effectType: effect.effectType,
                    value: effect.value * max(0.5, min(2.0, popScale)),
                    duration: effect.duration
                )
            default:
                return scaled
            }
        }
    }
    
    // MARK: - Choice Resolution
    
    func resolveChoice(_ choice: EventChoice, for village: inout Village, engine: GameEngine) {
        for effect in choice.effects {
            engine.applyEffect(effect)
        }
    }
}

// MARK: - Event Queue Manager
class EventQueueManager: ObservableObject {
    @Published var currentEvent: GameEvent?
    @Published var eventQueue: [GameEvent] = []
    @Published var eventHistory: [GameEvent] = []
    
    private let maxHistorySize = 100
    
    func enqueue(_ event: GameEvent) {
        if event.requiresChoice {
            // Choice events go to the front
            eventQueue.insert(event, at: 0)
        } else {
            eventQueue.append(event)
        }
        
        processNextEvent()
    }
    
    func enqueueMultiple(_ events: [GameEvent]) {
        for event in events {
            enqueue(event)
        }
    }
    
    func processNextEvent() {
        guard currentEvent == nil, !eventQueue.isEmpty else { return }
        currentEvent = eventQueue.removeFirst()
    }
    
    func acknowledgeCurrentEvent() {
        guard var event = currentEvent else { return }
        event.isAcknowledged = true
        
        // Add to history
        eventHistory.append(event)
        if eventHistory.count > maxHistorySize {
            eventHistory.removeFirst()
        }
        
        currentEvent = nil
        processNextEvent()
    }
    
    func selectChoice(_ choice: EventChoice, engine: GameEngine) {
        guard let event = currentEvent, event.requiresChoice else { return }
        
        // Apply choice effects
        for effect in choice.effects {
            engine.applyEffect(effect)
        }
        
        acknowledgeCurrentEvent()
    }
    
    func clearQueue() {
        eventQueue.removeAll()
        currentEvent = nil
    }
}

// MARK: - Event Notification
struct EventNotification: Identifiable {
    let id: UUID
    let event: GameEvent
    let timestamp: Date
    var isRead: Bool
    
    init(event: GameEvent) {
        self.id = UUID()
        self.event = event
        self.timestamp = Date()
        self.isRead = false
    }
}

// MARK: - Event Filters
enum EventFilter: String, CaseIterable {
    case all = "All"
    case threats = "Threats"
    case resources = "Resources"
    case social = "Social"
    case discoveries = "Discoveries"
    case weather = "Weather"
    
    func matches(_ event: GameEvent) -> Bool {
        switch self {
        case .all:
            return true
        case .threats:
            return [.threatRumor, .threatScout, .raid, .raidRepelled, .civilUnrest].contains(event.type)
        case .resources:
            return [.foodSpoilage, .bountifulHarvest, .saltShortage, .wellFreezes, .springFound].contains(event.type)
        case .social:
            return [.festival, .breadLineRumors, .pettyTheft, .civilUnrest].contains(event.type)
        case .discoveries:
            return [.discoveryMade, .discoveryProgress].contains(event.type)
        case .weather:
            return [.weakRains, .heavyStorms, .dangerousBlizzard, .heatwave].contains(event.type)
        }
    }
}
