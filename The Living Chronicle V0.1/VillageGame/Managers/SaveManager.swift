import Foundation

// MARK: - Save Manager
class SaveManager {
    static let shared = SaveManager()
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var savesDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let savesDir = documentsDirectory.appendingPathComponent("Saves", isDirectory: true)
        
        // Create directory if needed
        if !fileManager.fileExists(atPath: savesDir.path) {
            try? fileManager.createDirectory(at: savesDir, withIntermediateDirectories: true)
        }
        
        return savesDir
    }
    
    private init() {
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Save
    
    func save(_ village: Village) throws {
        let saveData = SaveData(village: village)
        let data = try encoder.encode(saveData)
        
        let filename = saveFilename(for: village.id)
        let fileURL = savesDirectory.appendingPathComponent(filename)
        
        try data.write(to: fileURL, options: .atomic)
        
        // Also save to quick-access current save
        let currentSaveURL = savesDirectory.appendingPathComponent("current.json")
        try data.write(to: currentSaveURL, options: .atomic)
        
        print("Saved village: \(village.name) to \(fileURL.path)")
    }
    
    func saveAsync(_ village: Village) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                do {
                    try self.save(village)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Load
    
    func loadVillage(id: UUID) throws -> Village {
        let filename = saveFilename(for: id)
        let fileURL = savesDirectory.appendingPathComponent(filename)
        
        let data = try Data(contentsOf: fileURL)
        let saveData = try decoder.decode(SaveData.self, from: data)
        
        return saveData.village
    }
    
    func loadCurrentSave() throws -> Village? {
        let currentSaveURL = savesDirectory.appendingPathComponent("current.json")
        
        guard fileManager.fileExists(atPath: currentSaveURL.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: currentSaveURL)
        let saveData = try decoder.decode(SaveData.self, from: data)
        
        return saveData.village
    }
    
    func loadAllSaves() -> [SaveInfo] {
        var saves: [SaveInfo] = []
        
        guard let contents = try? fileManager.contentsOfDirectory(
            at: savesDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else {
            return saves
        }
        
        for fileURL in contents {
            guard fileURL.pathExtension == "json",
                  fileURL.lastPathComponent != "current.json" else {
                continue
            }
            
            if let data = try? Data(contentsOf: fileURL),
               let saveData = try? decoder.decode(SaveData.self, from: data) {
                let modDate = (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date()
                
                saves.append(SaveInfo(
                    id: saveData.village.id,
                    villageName: saveData.village.name,
                    year: saveData.village.gameYear,
                    population: saveData.village.population,
                    lastPlayed: modDate,
                    isExtinct: saveData.village.isExtinct
                ))
            }
        }
        
        return saves.sorted { $0.lastPlayed > $1.lastPlayed }
    }
    
    // MARK: - Delete
    
    func deleteSave(id: UUID) throws {
        let filename = saveFilename(for: id)
        let fileURL = savesDirectory.appendingPathComponent(filename)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    func deleteAllSaves() throws {
        let contents = try fileManager.contentsOfDirectory(
            at: savesDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )
        
        for fileURL in contents {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    // MARK: - Export / Import
    
    func exportSave(_ village: Village) throws -> Data {
        let saveData = SaveData(village: village)
        return try encoder.encode(saveData)
    }
    
    func importSave(from data: Data) throws -> Village {
        let saveData = try decoder.decode(SaveData.self, from: data)
        try save(saveData.village)
        return saveData.village
    }
    
    // MARK: - Helpers
    
    private func saveFilename(for id: UUID) -> String {
        "village_\(id.uuidString).json"
    }
    
    func saveExists(for id: UUID) -> Bool {
        let filename = saveFilename(for: id)
        let fileURL = savesDirectory.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: fileURL.path)
    }
}

// MARK: - Save Data Structure
struct SaveData: Codable {
    let version: Int
    let savedAt: Date
    let village: Village
    
    init(village: Village) {
        self.version = 1
        self.savedAt = Date()
        self.village = village
    }
}

// MARK: - Save Info (for listing)
struct SaveInfo: Identifiable {
    let id: UUID
    let villageName: String
    let year: Int
    let population: Int
    let lastPlayed: Date
    let isExtinct: Bool
    
    var displayDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastPlayed, relativeTo: Date())
    }
}

// MARK: - Auto-Save Manager
class AutoSaveManager: ObservableObject {
    @Published var lastAutoSave: Date?
    @Published var isSaving: Bool = false
    
    private var saveTimer: Timer?
    private let saveInterval: TimeInterval = 60  // Auto-save every 60 seconds
    
    func startAutoSave(for engine: GameEngine) {
        stopAutoSave()
        
        saveTimer = Timer.scheduledTimer(withTimeInterval: saveInterval, repeats: true) { [weak self] _ in
            self?.performAutoSave(engine: engine)
        }
    }
    
    func stopAutoSave() {
        saveTimer?.invalidate()
        saveTimer = nil
    }
    
    private func performAutoSave(engine: GameEngine) {
        guard !isSaving else { return }
        
        isSaving = true
        
        Task {
            do {
                try await SaveManager.shared.saveAsync(engine.village)
                await MainActor.run {
                    self.lastAutoSave = Date()
                    self.isSaving = false
                }
            } catch {
                print("Auto-save failed: \(error)")
                await MainActor.run {
                    self.isSaving = false
                }
            }
        }
    }
    
    func forceSave(engine: GameEngine) {
        performAutoSave(engine: engine)
    }
}
