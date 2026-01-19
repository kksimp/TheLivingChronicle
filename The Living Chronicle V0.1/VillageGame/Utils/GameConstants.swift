import Foundation
import SwiftUI

// MARK: - Game Constants
enum GameConstants {
    // Time System
    static let realDaysPerGameYear: Double = 7.0
    static let seasonsPerYear: Int = 4
    static let realDaysPerSeason: Double = 1.75
    static let tickIntervalMinutes: Int = 15
    static let maxCatchUpHours: Double = 72.0
    
    // Population
    static let startingPopulation: Int = 10
    static let productionBonusPerVillager: Double = 0.001  // 0.1%
    static let maxProductionBonus: Double = 0.25  // 25%
    static let populationCapForMaxBonus: Int = 250
    
    // Builders
    static let startingBuilders: Int = 2
    static let maxBuilders: Int = 4
    
    // Upgrade Time Formula Constants
    static let minUpgradeHours: Double = 1.0
    static let maxUpgradeHours: Double = 24.0
    static let yearDivisor: Double = 3000.0
    static let levelMultiplier: Double = 0.15
    
    // Guards
    static let guardProtectionPerGuard: Double = 0.000025  // 0.0025%
    static let maxGuardProtection: Double = 0.10  // 10%
    static let policeStateThreshold: Double = 0.50  // 50%
    static let severePoliceStateThreshold: Double = 0.75  // 75%
    
    // Panic
    static let panicDecayFoodThreshold: Double = 1.20  // 120% of consumption
    
    // Starting Year
    static let startingYear: Int = 1500
    
    // Resource Defaults
    static let startingFood: Double = 100.0
    static let startingWater: Double = 100.0
    static let startingFirewood: Double = 50.0
    static let startingSalt: Double = 20.0
    static let startingStone: Double = 0.0
    static let startingMetal: Double = 0.0
    static let startingKnowledge: Double = 0.0
    static let startingGuildMarks: Int = 100
    
    // Ad System
    static let adBuildTimeReductionHours: Double = 1.0
    static let adsForContinueAfterExtinction: Int = 3
    static let adsForLegacyMode: Int = 1
    
    // Year Skip
    static let healthThresholdForYearSkip: Double = 0.50  // 50%
}

// MARK: - Safe Area Insets Environment
struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .windows.first?.safeAreaInsets.toEdgeInsets ?? EdgeInsets()
    }
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}

extension UIEdgeInsets {
    var toEdgeInsets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

// MARK: - Season
enum Season: Int, CaseIterable, Codable {
    case spring = 0
    case summer = 1
    case fall = 2
    case winter = 3
    
    var name: String {
        switch self {
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .fall: return "Fall"
        case .winter: return "Winter"
        }
    }
    
    var foodProductionModifier: Double {
        switch self {
        case .spring: return 1.15
        case .summer: return 1.25
        case .fall: return 1.10
        case .winter: return 0.0
        }
    }
    
    var waterConsumptionModifier: Double {
        switch self {
        case .spring: return 1.0
        case .summer: return 1.20
        case .fall: return 1.0
        case .winter: return 0.90
        }
    }
    
    var firewoodConsumptionModifier: Double {
        switch self {
        case .spring: return 0.5
        case .summer: return 0.1
        case .fall: return 0.7
        case .winter: return 2.0
        }
    }
    
    var diseaseRiskModifier: Double {
        switch self {
        case .spring: return 1.15
        case .summer: return 1.0
        case .fall: return 1.0
        case .winter: return 1.30
        }
    }
    
    var raidFrequencyModifier: Double {
        switch self {
        case .spring: return 0.7
        case .summer: return 1.2
        case .fall: return 1.0
        case .winter: return 0.5
        }
    }
    
    var raidSeverityModifier: Double {
        switch self {
        case .spring: return 1.0
        case .summer: return 1.0
        case .fall: return 1.0
        case .winter: return 1.5
        }
    }
}

// MARK: - Weather
enum Weather: Int, CaseIterable, Codable {
    case weak = 0
    case mild = 1
    case heavy = 2
    case dangerous = 3
    
    var name: String {
        switch self {
        case .weak: return "Clear"
        case .mild: return "Mild"
        case .heavy: return "Stormy"
        case .dangerous: return "Severe"
        }
    }
    
    var foodProductionModifier: Double {
        switch self {
        case .weak: return 0.90
        case .mild: return 1.0
        case .heavy: return 0.80
        case .dangerous: return 0.50
        }
    }
    
    var diseaseModifier: Double {
        switch self {
        case .weak: return 0.9
        case .mild: return 1.0
        case .heavy: return 1.2
        case .dangerous: return 1.5
        }
    }
}

// MARK: - Era
enum Era: Int, CaseIterable, Codable, Comparable {
    case founding = 0        // Year ~1500
    case earlySettlement = 1  // Era 1
    case organizedVillage = 2 // Era 2
    case structuredSociety = 3 // Era 3
    case earlyScience = 4     // Era 4
    case medicalRevolution = 5 // Era 5
    case industrialTransition = 6 // Era 6
    case modernization = 7    // Era 7
    case enlightenment = 8    // Era 8+
    
    static func < (lhs: Era, rhs: Era) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var name: String {
        switch self {
        case .founding: return "Founding"
        case .earlySettlement: return "Early Settlement"
        case .organizedVillage: return "Organized Village"
        case .structuredSociety: return "Structured Society"
        case .earlyScience: return "Early Science"
        case .medicalRevolution: return "Medical Revolution"
        case .industrialTransition: return "Industrial Transition"
        case .modernization: return "Modernization"
        case .enlightenment: return "Enlightenment"
        }
    }
}

// MARK: - Food Type
enum FoodType: Codable {
    case fresh
    case preserved
    case salted
    case smoked
    case refrigerated
    case industrial
    
    var moraleModifier: Double {
        switch self {
        case .fresh: return 0.10
        case .preserved: return 0.0
        case .salted: return -0.02
        case .smoked: return 0.0
        case .refrigerated: return 0.02
        case .industrial: return -0.03
        }
    }
    
    var spoilageRate: Double {
        switch self {
        case .fresh: return 0.15  // 15% per day
        case .preserved: return 0.05
        case .salted: return 0.03
        case .smoked: return 0.03
        case .refrigerated: return 0.01
        case .industrial: return 0.005
        }
    }
}

// MARK: - Threat Phase
enum ThreatPhase: Int, Codable, Comparable {
    case none = 0
    case rumors = 1
    case scouts = 2
    case raidImminent = 3
    
    static func < (lhs: ThreatPhase, rhs: ThreatPhase) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var name: String {
        switch self {
        case .none: return "Peace"
        case .rumors: return "Rumors"
        case .scouts: return "Scout Activity"
        case .raidImminent: return "Raid Imminent"
        }
    }
}


// MARK: - Faction Type
enum FactionType: String, Codable, CaseIterable {
    case bandits = "Bandits"
    case deserters = "Deserters"
    case zealots = "Zealots"
    case mercenaries = "Mercenaries"
    
    var description: String {
        switch self {
        case .bandits: return "Resource-driven raiders"
        case .deserters: return "War refugees turned hostile"
        case .zealots: return "Faith-driven attackers"
        case .mercenaries: return "Wealth-seeking professionals"
        }
    }
}
