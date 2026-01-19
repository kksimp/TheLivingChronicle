import Foundation

// MARK: - Game Event
struct GameEvent: Codable, Identifiable {
    let id: UUID
    let type: EventType
    let title: String
    let message: String
    let effects: [EventEffect]
    let choices: [EventChoice]?
    let year: Int
    let season: Season
    let timestamp: Date
    var isAcknowledged: Bool
    
    init(
        type: EventType,
        title: String,
        message: String,
        effects: [EventEffect],
        choices: [EventChoice]? = nil,
        year: Int,
        season: Season
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.message = message
        self.effects = effects
        self.choices = choices
        self.year = year
        self.season = season
        self.timestamp = Date()
        self.isAcknowledged = false
    }
    
    var requiresChoice: Bool {
        choices != nil && !choices!.isEmpty
    }
}

// MARK: - Event Type
enum EventType: String, Codable {
    // Threat Events
    case threatRumor = "threat_rumor"
    case threatScout = "threat_scout"
    case raid = "raid"
    case raidRepelled = "raid_repelled"
    
    // Resource Events
    case foodSpoilage = "food_spoilage"
    case bountifulHarvest = "bountiful_harvest"
    case saltShortage = "salt_shortage"
    case wellFreezes = "well_freezes"
    case springFound = "spring_found"
    
    // Weather Events
    case weakRains = "weak_rains"
    case heavyStorms = "heavy_storms"
    case dangerousBlizzard = "dangerous_blizzard"
    case heatwave = "heatwave"
    
    // Disease Events
    case diseaseOutbreak = "disease_outbreak"
    case newRemedy = "new_remedy"
    case quarantineDebate = "quarantine_debate"
    
    // Social Events
    case festival = "festival"
    case breadLineRumors = "bread_line_rumors"
    case pettyTheft = "petty_theft"
    case civilUnrest = "civil_unrest"
    case nightWatchSuccess = "night_watch_success"
    
    // Discovery Events
    case discoveryMade = "discovery_made"
    case discoveryProgress = "discovery_progress"
    
    // Epoch Events (baked in)
    case epochEvent = "epoch_event"
    
    // Misc
    case traveler = "traveler"
    case coldSnap = "cold_snap"
    case minorRepair = "minor_repair"
    
    var severity: EventSeverity {
        switch self {
        case .raid, .diseaseOutbreak, .dangerousBlizzard, .civilUnrest:
            return .critical
        case .threatScout, .foodSpoilage, .heavyStorms, .heatwave, .saltShortage:
            return .warning
        case .threatRumor, .weakRains, .wellFreezes, .breadLineRumors:
            return .notice
        case .bountifulHarvest, .festival, .discoveryMade, .raidRepelled, .newRemedy, .springFound, .nightWatchSuccess:
            return .positive
        default:
            return .info
        }
    }
}

enum EventSeverity: String, Codable {
    case critical = "critical"
    case warning = "warning"
    case notice = "notice"
    case info = "info"
    case positive = "positive"
}

// MARK: - Event Effect
struct EventEffect: Codable {
    let effectType: EffectType
    let value: Double
    let duration: Int?  // In ticks, nil = permanent/instant
    
    enum EffectType: String, Codable {
        // Resources
        case food
        case water
        case firewood
        case salt
        case stone
        case metal
        case knowledge
        case guildMarks
        
        // Stats
        case health
        case morale
        case panic
        case population
        
        // Production modifiers
        case foodProduction
        case waterProduction
        case firewoodProduction
        case allProduction
        
        // Consumption modifiers
        case foodConsumption
        case waterConsumption
        case firewoodConsumption
        
        // Other
        case diseaseRisk
        case raidChance
        case defenseBonus
        case discoveryProgress
        case threatPhase
        case buildingDamage
    }
}

// MARK: - Event Choice
struct EventChoice: Codable, Identifiable {
    let id: UUID
    let label: String
    let description: String
    let effects: [EventEffect]
    
    init(label: String, description: String, effects: [EventEffect]) {
        self.id = UUID()
        self.label = label
        self.description = description
        self.effects = effects
    }
}

// MARK: - Epoch Event Definition
struct EpochEvent: Codable {
    let year: Int
    let season: Season
    let title: String
    let description: String
    let baseEffects: [EventEffect]
    
    static let allEpochEvents: [EpochEvent] = [
        EpochEvent(
            year: 1562,
            season: .winter,
            title: "The Long Freeze",
            description: "A winter unlike any in living memory grips the land. Fires must burn day and night.",
            baseEffects: [
                EventEffect(effectType: .firewoodConsumption, value: 0.50, duration: 96),
                EventEffect(effectType: .panic, value: 5, duration: nil)
            ]
        ),
        EpochEvent(
            year: 1609,
            season: .fall,
            title: "The Great Mouse Year",
            description: "A plague of mice descended upon the granaries. Much grain was lost.",
            baseEffects: [
                EventEffect(effectType: .food, value: -50, duration: nil),
                EventEffect(effectType: .panic, value: 3, duration: nil)
            ]
        ),
        EpochEvent(
            year: 1671,
            season: .spring,
            title: "A Traveling Scholar",
            description: "A learned traveler shares knowledge with the village elders.",
            baseEffects: [
                EventEffect(effectType: .knowledge, value: 20, duration: nil),
                EventEffect(effectType: .morale, value: 5, duration: nil)
            ]
        ),
        EpochEvent(
            year: 1723,
            season: .winter,
            title: "The Great Hunger",
            description: "Blight and frost conspire. Mouths outnumber meals.",
            baseEffects: [
                EventEffect(effectType: .foodConsumption, value: 0.40, duration: 96),
                EventEffect(effectType: .panic, value: 8, duration: nil)
            ]
        ),
        EpochEvent(
            year: 1804,
            season: .summer,
            title: "The War Draft",
            description: "Soldiers came recruiting. Some villagers left to fight in distant lands.",
            baseEffects: [
                EventEffect(effectType: .population, value: -5, duration: nil),
                EventEffect(effectType: .raidChance, value: 0.20, duration: 192),
                EventEffect(effectType: .panic, value: 4, duration: nil)
            ]
        ),
        EpochEvent(
            year: 1847,
            season: .fall,
            title: "The Canning Breakthrough",
            description: "News arrives of a revolutionary preservation method.",
            baseEffects: [
                EventEffect(effectType: .discoveryProgress, value: 0.25, duration: nil),
                EventEffect(effectType: .morale, value: 3, duration: nil)
            ]
        ),
        EpochEvent(
            year: 1918,
            season: .spring,
            title: "The Pale Cough",
            description: "A terrible illness spreads. The young and old are most at risk.",
            baseEffects: [
                EventEffect(effectType: .diseaseRisk, value: 0.50, duration: 192),
                EventEffect(effectType: .health, value: -20, duration: nil),
                EventEffect(effectType: .panic, value: 10, duration: nil)
            ]
        ),
        EpochEvent(
            year: 1936,
            season: .summer,
            title: "The Great Heat",
            description: "The sun beats down relentlessly. Wells run low and crops wither.",
            baseEffects: [
                EventEffect(effectType: .waterConsumption, value: 0.40, duration: 96),
                EventEffect(effectType: .foodProduction, value: -0.30, duration: 96),
                EventEffect(effectType: .panic, value: 5, duration: nil)
            ]
        ),
        EpochEvent(
            year: 1977,
            season: .winter,
            title: "Energy Shock",
            description: "The cost of keeping warm and powered has skyrocketed.",
            baseEffects: [
                EventEffect(effectType: .firewoodConsumption, value: 0.30, duration: 192),
                EventEffect(effectType: .morale, value: -5, duration: nil)
            ]
        ),
        EpochEvent(
            year: 2001,
            season: .fall,
            title: "Religious Enlightenment",
            description: "A new understanding spreads. Faith remains, but superstition fades.",
            baseEffects: [
                EventEffect(effectType: .panic, value: -10, duration: nil),
                EventEffect(effectType: .morale, value: 5, duration: nil)
            ]
        )
    ]
}

// MARK: - Event Templates
struct EventTemplate {
    let type: EventType
    let titles: [String]
    let messages: [(Village) -> String]
    let baseEffects: (Village) -> [EventEffect]
    let choices: ((Village) -> [EventChoice])?
    let condition: (Village) -> Bool
    let weight: Double
    
    static let allTemplates: [EventTemplate] = [
        // Threat Phase 1: Rumors
        EventTemplate(
            type: .threatRumor,
            titles: ["Strange Tracks", "Whispers of Unrest", "Distant Smoke"],
            messages: [
                { _ in "Villagers found fresh tracks near the treeline. Perhaps we should strengthen our defenses." },
                { _ in "Villagers whisper of unrest beyond the valley." },
                { _ in "Smoke rises from beyond the hills. Someone is out there." }
            ],
            baseEffects: { _ in [
                EventEffect(effectType: .panic, value: 2, duration: nil),
                EventEffect(effectType: .threatPhase, value: 1, duration: nil)
            ]},
            choices: nil,
            condition: { village in
                village.currentThreatPhase == .none &&
                village.totalDefenseRating < 0.3 &&
                village.gracePeriodsRemaining <= 0
            },
            weight: 1.0
        ),
        
        // Bountiful Harvest
        EventTemplate(
            type: .bountifulHarvest,
            titles: ["Bountiful Harvest", "Nature's Blessing", "Abundant Crops"],
            messages: [
                { village in "The harvest was unusually strong. We gained \(Int(village.population * 3)) food." }
            ],
            baseEffects: { village in [
                EventEffect(effectType: .food, value: Double(village.population * 3), duration: nil),
                EventEffect(effectType: .morale, value: 2, duration: nil)
            ]},
            choices: nil,
            condition: { village in
                village.currentSeason == .fall &&
                village.hasBuilding(.farm) &&
                village.currentWeather != .dangerous
            },
            weight: 0.8
        ),
        
        // Food Spoilage
        EventTemplate(
            type: .foodSpoilage,
            titles: ["Grain Weevils", "Mold in the Stores", "Food Gone Bad"],
            messages: [
                { village in
                    let loss = Int(village.foodStorage.total * 0.15)
                    return "Weevils got into the grain stores. We lost \(loss) food."
                }
            ],
            baseEffects: { village in
                let loss = village.foodStorage.total * 0.15
                return [
                    EventEffect(effectType: .food, value: -loss, duration: nil),
                    EventEffect(effectType: .panic, value: village.daysOfFoodRemaining < 7 ? 2 : 0, duration: nil)
                ]
            },
            choices: nil,
            condition: { village in
                village.foodStorage.total > 50 &&
                !village.hasBuilding(.granary) &&
                !village.hasDiscovery(.refrigeration) &&
                (village.currentSeason == .summer || village.currentSeason == .spring)
            },
            weight: 0.6
        ),
        
        // Disease Outbreak
        EventTemplate(
            type: .diseaseOutbreak,
            titles: ["Red Lung Spreads", "Black Fever", "The Shaking Sickness"],
            messages: [
                { _ in "A coughing illness spreads through cramped homes. Some cannot work." },
                { _ in "Black Fever has appeared. The village is afraid." },
                { _ in "A strange illness causes tremors and weakness." }
            ],
            baseEffects: { village in
                let severity = village.hasBuilding(.herbalist) ? 0.5 : 1.0
                return [
                    EventEffect(effectType: .health, value: -15 * severity, duration: nil),
                    EventEffect(effectType: .allProduction, value: -0.10 * severity, duration: 96),
                    EventEffect(effectType: .panic, value: 5 * severity, duration: nil)
                ]
            },
            choices: nil,
            condition: { village in
                (village.currentWeather == .heavy || village.currentSeason == .winter) &&
                village.gracePeriodsRemaining <= 0
            },
            weight: 0.4
        ),
        
        // Quarantine Debate (choice event)
        EventTemplate(
            type: .quarantineDebate,
            titles: ["Quarantine Debate"],
            messages: [
                { _ in "Leaders argue over quarantine. People want safety, but fear isolation." }
            ],
            baseEffects: { _ in [] },
            choices: { _ in [
                EventChoice(
                    label: "Enforce Quarantine",
                    description: "Reduce disease severity but hurt morale and production",
                    effects: [
                        EventEffect(effectType: .diseaseRisk, value: -0.20, duration: 96),
                        EventEffect(effectType: .morale, value: -2, duration: nil),
                        EventEffect(effectType: .allProduction, value: -0.05, duration: 72)
                    ]
                ),
                EventChoice(
                    label: "No Quarantine",
                    description: "Maintain morale but risk worse outbreak",
                    effects: [
                        EventEffect(effectType: .morale, value: 1, duration: nil),
                        EventEffect(effectType: .diseaseRisk, value: 0.15, duration: 96)
                    ]
                )
            ]},
            condition: { village in
                village.health < 70 &&
                village.panic > 20
            },
            weight: 0.3
        ),
        
        // Festival
        EventTemplate(
            type: .festival,
            titles: ["Festival of Lanterns", "Harvest Festival", "Celebration"],
            messages: [
                { _ in "Lanterns lit the night. For a moment, everyone remembered why they endure." },
                { _ in "The village gathered to celebrate. Spirits are lifted." }
            ],
            baseEffects: { _ in [
                EventEffect(effectType: .morale, value: 3, duration: nil),
                EventEffect(effectType: .panic, value: -3, duration: nil)
            ]},
            choices: nil,
            condition: { village in
                (village.currentSeason == .fall || village.currentSeason == .spring) &&
                (village.hasBuilding(.shrine) || village.hasBuilding(.church) || village.morale < 50)
            },
            weight: 0.5
        ),
        
        // Night Watch Success
        EventTemplate(
            type: .nightWatchSuccess,
            titles: ["Night Watch Success", "Scout Captured", "Intruder Spotted"],
            messages: [
                { _ in "The night watch caught a scout in the brush. The village sleeps easier." }
            ],
            baseEffects: { _ in [
                EventEffect(effectType: .raidChance, value: -0.10, duration: 192),
                EventEffect(effectType: .morale, value: 1, duration: nil),
                EventEffect(effectType: .panic, value: -1, duration: nil)
            ]},
            choices: nil,
            condition: { village in
                village.guards > 0 &&
                village.currentThreatPhase >= .scouts
            },
            weight: 0.6
        ),
        
        // Heavy Storms
        EventTemplate(
            type: .heavyStorms,
            titles: ["Heavy Storms", "Tempest", "Wild Weather"],
            messages: [
                { _ in "Heavy storms battered the village. Repairs will take time." }
            ],
            baseEffects: { _ in [
                EventEffect(effectType: .buildingDamage, value: 0.20, duration: nil),
                EventEffect(effectType: .panic, value: 1, duration: nil)
            ]},
            choices: nil,
            condition: { village in
                village.currentWeather == .heavy
            },
            weight: 0.5
        ),
        
        // Well Freezes
        EventTemplate(
            type: .wellFreezes,
            titles: ["Well Freezes", "Frozen Water"],
            messages: [
                { _ in "The well iced over. Water collection slowed." }
            ],
            baseEffects: { village in
                let reduction = village.hasDiscovery(.fireManagement) ? 0.20 : 0.30
                return [
                    EventEffect(effectType: .waterProduction, value: -reduction, duration: 72),
                    EventEffect(effectType: .panic, value: 1, duration: nil)
                ]
            },
            choices: nil,
            condition: { village in
                village.currentSeason == .winter &&
                village.hasBuilding(.well) &&
                !village.hasDiscovery(.insulation)
            },
            weight: 0.4
        ),
        
        // Helpful Traveler (early game)
        EventTemplate(
            type: .traveler,
            titles: ["A Helpful Traveler"],
            messages: [
                { _ in "A traveler offered advice and a few supplies in exchange for a warm meal." }
            ],
            baseEffects: { _ in [
                EventEffect(effectType: .food, value: 15, duration: nil),
                EventEffect(effectType: .morale, value: 1, duration: nil),
                EventEffect(effectType: .discoveryProgress, value: 0.05, duration: nil)
            ]},
            choices: nil,
            condition: { village in
                village.yearsSurvived <= 1 &&
                (village.foodStorage.total < 30 || village.resources.metal < 5)
            },
            weight: 0.7
        ),
        
        // Civil Unrest (police state)
        EventTemplate(
            type: .civilUnrest,
            titles: ["Civil Unrest", "Discontent Grows", "Tensions Rise"],
            messages: [
                { _ in "Some claim we live under constant watch. People refuse orders." },
                { _ in "Merchants complain of constant watch. Trade suffers." }
            ],
            baseEffects: { village in
                let severity = village.isSeverePoliceState ? 1.5 : 1.0
                return [
                    EventEffect(effectType: .morale, value: -3 * severity, duration: nil),
                    EventEffect(effectType: .panic, value: 2 * severity, duration: nil),
                    EventEffect(effectType: .allProduction, value: -0.15, duration: 72)
                ]
            },
            choices: nil,
            condition: { village in
                village.isPoliceState
            },
            weight: 0.8
        )
    ]
}
