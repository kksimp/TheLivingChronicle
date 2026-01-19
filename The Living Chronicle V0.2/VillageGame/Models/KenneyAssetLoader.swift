import Foundation
import SceneKit

// MARK: - Kenney Asset Loader
class KenneyAssetLoader {
    static let shared = KenneyAssetLoader()
    
    private var assetCache: [String: SCNNode] = [:]
    private let assetBasePath = "Kenney"
    
    private init() {}
    
    // MARK: - Load Asset
    
    func loadAsset(category: KenneyCategory, filename: String) -> SCNNode? {
        let cacheKey = "\(category.rawValue)/\(filename)"
        
        // Check cache first
        if let cached = assetCache[cacheKey] {
            return cached.clone()
        }
        
        // Build path to GLB file
        let fullPath = "\(assetBasePath)/\(category.rawValue)/\(filename)"
        
        guard let url = Bundle.main.url(forResource: fullPath, withExtension: "glb") else {
            print("⚠️ Failed to find asset: \(fullPath).glb")
            return nil
        }
        
        do {
            let scene = try SCNScene(url: url, options: nil)
            
            // Get the root node (or first child)
            let modelNode: SCNNode
            if let firstChild = scene.rootNode.childNodes.first {
                modelNode = firstChild
            } else {
                modelNode = scene.rootNode
            }
            
            // Cache the original
            assetCache[cacheKey] = modelNode
            
            // Return a clone
            return modelNode.clone()
        } catch {
            print("❌ Failed to load asset \(fullPath): \(error)")
            return nil
        }
    }
    
    // MARK: - Building Type to Kenney Asset Mapping
    
    func assetForBuilding(_ type: BuildingType) -> (category: KenneyCategory, filename: String)? {
        switch type {
        // ============ MEDIEVAL ERA ============
        
        // Housing - Medieval
        case .groundShelter:
            return (.medieval, "barrels")
        case .tent:
            return (.medieval, "detail-crate")
        case .hut:
            return (.medieval, "structure")
            
        // Production - Early Game
        case .campfire:
            return (.medieval, "detail-barrel")
        case .gatheringPost:
            return (.medieval, "detail-crate-small")
        case .fishingSpot:
            return (.medieval, "dock-side")
            
        // Production - Medieval Standard
        case .farm:
            return (.medieval, "fence-wood")
        case .orchard:
            return (.medieval, "tree-large")
        case .well:
            return (.medieval, "pulley")
        case .woodpile:
            return (.medieval, "detail-crate-ropes")
        case .quarry:
            return (.medieval, "bricks")
        case .mine:
            return (.medieval, "ladder")
            
        // Storage - Medieval
        case .granary:
            return (.medieval, "structure-wall")
        case .saltStorehouse:
            return (.medieval, "barrels")
        case .smokehouse:
            return (.medieval, "structure-poles")
            
        // Defense - Medieval
        case .watchtower:
            return (.medieval, "tower")
        case .palisade:
            return (.medieval, "wall-fortified")
        case .stoneWall:
            return (.medieval, "wall-fortified-gate")
            
        // Special - Medieval
        case .shrine:
            return (.medieval, "structure-cross")
        case .church:
            return (.medieval, "tower-top")
        case .herbalist:
            return (.medieval, "detail-crate-small")
        case .scholarsHut:
            return (.medieval, "structure-pole")
        case .market:
            return (.medieval, "overhang")
            
        // ============ TRANSITION ERA ============
        
        case .stoneHome:
            return (.urban, "wall-a")
            
        // ============ URBAN ERA ============
        
        case .insulatedHouse:
            return (.suburban, "building-type-a")
        case .houseWithAC:
            return (.suburban, "building-type-e")
            
        // Storage - Modern
        case .refrigeratedStorage:
            return (.industrial, "building-a")
            
        // Special - Urban/Modern
        case .townHall:
            return (.commercial, "building-e")
        case .medicalHall:
            return (.commercial, "building-h")
            
        default:
            return nil
        }
    }
    
    // MARK: - Environment Assets
    
    func getEnvironmentAssets() -> [EnvironmentAsset] {
        return [
            // Medieval trees
            EnvironmentAsset(category: .medieval, filename: "tree-large", type: .tree),
            EnvironmentAsset(category: .medieval, filename: "tree-shrub", type: .decoration),
            
            // Urban trees
            EnvironmentAsset(category: .urban, filename: "tree-large", type: .tree),
            EnvironmentAsset(category: .urban, filename: "tree-pine-large", type: .tree),
            EnvironmentAsset(category: .urban, filename: "tree-park-large", type: .tree),
            EnvironmentAsset(category: .urban, filename: "tree-shrub", type: .decoration),
            
            // Suburban landscaping
            EnvironmentAsset(category: .suburban, filename: "tree-large", type: .tree),
            EnvironmentAsset(category: .suburban, filename: "tree-small", type: .tree),
            EnvironmentAsset(category: .suburban, filename: "planter", type: .decoration),
            EnvironmentAsset(category: .suburban, filename: "fence", type: .decoration),
            
            // Medieval decorations
            EnvironmentAsset(category: .medieval, filename: "detail-barrel", type: .decoration),
            EnvironmentAsset(category: .medieval, filename: "fence", type: .decoration),
            
            // Urban decorations
            EnvironmentAsset(category: .urban, filename: "detail-bench", type: .decoration),
            EnvironmentAsset(category: .urban, filename: "detail-dumpster-closed", type: .decoration),
            EnvironmentAsset(category: .urban, filename: "detail-barrier-type-a", type: .decoration),
        ]
    }
}

// MARK: - Supporting Types

enum KenneyCategory: String {
    case medieval = "Medieval"
    case urban = "Urban"
    case roads = "Roads"
    case commercial = "Commercial"
    case industrial = "Industrial"
    case suburban = "Suburban"

}
struct EnvironmentAsset {
    let category: KenneyCategory
    let filename: String
    let type: EnvironmentType
    
    enum EnvironmentType {
        case tree
        case decoration
    }
}

