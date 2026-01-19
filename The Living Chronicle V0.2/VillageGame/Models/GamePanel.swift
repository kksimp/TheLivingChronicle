//
//  GamePanel.swift
//  VillageGame
//
//  Created by Kaleb on 1/18/26.
//

import SwiftUI

// MARK: - Game Panel
enum GamePanel: String, CaseIterable, Identifiable {
    case buildings = "Buildings"
    case population = "Population"
    case threats = "Threats"
    case research = "Research"
    case chronicle = "Chronicle"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .buildings: return "hammer.fill"
        case .population: return "person.3.fill"
        case .threats: return "shield.fill"
        case .research: return "lightbulb.fill"
        case .chronicle: return "book.fill"
        case .settings: return "gear"
        }
    }
}
