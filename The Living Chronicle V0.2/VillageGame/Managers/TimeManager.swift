import Foundation
import Combine

// MARK: - Time Manager
class TimeManager: ObservableObject {
    @Published var currentGameTime: GameTime
    @Published var isVerifyingTime: Bool = false
    @Published var lastVerificationStatus: VerificationStatus = .unverified
    
    private var lastKnownRealTime: Date
    private var lastVerifiedRealTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    // Time verification settings
    private let verificationIntervalHours: Double = 6.0
    private let maxAllowedDriftSeconds: TimeInterval = 300  // 5 minutes
    
    init() {
        self.currentGameTime = GameTime()
        self.lastKnownRealTime = Date()
    }
    
    // MARK: - Time Calculation
    
    func calculateTicksSinceLastUpdate(lastUpdate: Date, currentTime: Date = Date()) -> Int {
        // Get elapsed real time
        var elapsedSeconds = currentTime.timeIntervalSince(lastUpdate)
        
        // Clamp to max catch-up (72 hours)
        let maxCatchUpSeconds = GameConstants.maxCatchUpHours * 3600
        elapsedSeconds = min(elapsedSeconds, maxCatchUpSeconds)
        
        // Prevent time going backwards
        elapsedSeconds = max(0, elapsedSeconds)
        
        // Convert to ticks (15 minutes per tick)
        let tickIntervalSeconds = Double(GameConstants.tickIntervalMinutes * 60)
        return Int(elapsedSeconds / tickIntervalSeconds)
    }
    
    func calculateGameTimeAdvance(ticks: Int) -> GameTimeAdvance {
        // Each tick is 15 real minutes
        // 1 game year = 7 real days
        // So 1 game year = 7 * 24 * 4 = 672 ticks
        // 1 season = 168 ticks
        
        let ticksPerSeason = 168
        let ticksPerYear = ticksPerSeason * 4
        
        let yearsAdvanced = ticks / ticksPerYear
        let remainingTicks = ticks % ticksPerYear
        let seasonsAdvanced = remainingTicks / ticksPerSeason
        let daysAdvanced = remainingTicks % ticksPerSeason
        
        return GameTimeAdvance(
            ticks: ticks,
            years: yearsAdvanced,
            seasons: seasonsAdvanced,
            days: daysAdvanced
        )
    }
    
    // MARK: - Time Verification
    
    func verifyTime() async -> VerificationResult {
        isVerifyingTime = true
        defer { isVerifyingTime = false }
        
        // Try to get server time
        guard let serverTime = await fetchServerTime() else {
            lastVerificationStatus = .failed
            return VerificationResult(success: false, drift: nil, serverTime: nil)
        }
        
        let deviceTime = Date()
        let drift = deviceTime.timeIntervalSince(serverTime)
        
        lastVerifiedRealTime = serverTime
        
        if abs(drift) > maxAllowedDriftSeconds {
            lastVerificationStatus = .suspicious(drift: drift)
            return VerificationResult(success: false, drift: drift, serverTime: serverTime)
        }
        
        lastVerificationStatus = .verified
        return VerificationResult(success: true, drift: drift, serverTime: serverTime)
    }
    
    private func fetchServerTime() async -> Date? {
        // Use a trusted time source
        // For production, use Apple's NTP or own backend
        // For now, use worldtimeapi.org as a simple solution
        guard let url = URL(string: "https://worldtimeapi.org/api/ip") else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(WorldTimeResponse.self, from: data)
            return response.datetime
        } catch {
            print("Time verification failed: \(error)")
            return nil
        }
    }
    
    func shouldVerifyTime() -> Bool {
        guard let lastVerified = lastVerifiedRealTime else {
            return true  // Never verified
        }
        
        let hoursSinceVerification = Date().timeIntervalSince(lastVerified) / 3600
        return hoursSinceVerification >= verificationIntervalHours
    }
    
    // MARK: - Monotonic Time Enforcement
    
    func enforceMonotonicTime(requestedTime: Date) -> Date {
        // Time cannot go backwards
        let now = Date()
        
        if requestedTime > now {
            // Future time detected - possible cheating
            return lastKnownRealTime
        }
        
        if requestedTime < lastKnownRealTime {
            // Time went backwards - use last known time
            return lastKnownRealTime
        }
        
        lastKnownRealTime = requestedTime
        return requestedTime
    }
    
    // MARK: - Season Calculation
    
    func calculateSeason(fromStartYear startYear: Int, currentYear: Int, dayInYear: Int) -> Season {
        // 4 seasons per year, roughly 42 days each in game time
        let daysPerSeason = 42  // Simplified
        let seasonIndex = (dayInYear / daysPerSeason) % 4
        return Season(rawValue: seasonIndex) ?? .spring
    }
}

// MARK: - Supporting Types

struct GameTime: Codable {
    var year: Int
    var season: Season
    var dayInSeason: Int
    
    init(year: Int = GameConstants.startingYear, season: Season = .spring, dayInSeason: Int = 0) {
        self.year = year
        self.season = season
        self.dayInSeason = dayInSeason
    }
    
    var displayString: String {
        "\(season.name), Year \(year)"
    }
}

struct GameTimeAdvance {
    let ticks: Int
    let years: Int
    let seasons: Int
    let days: Int
    
    var isEmpty: Bool { ticks == 0 }
    
    var description: String {
        var parts: [String] = []
        if years > 0 { parts.append("\(years) year\(years == 1 ? "" : "s")") }
        if seasons > 0 { parts.append("\(seasons) season\(seasons == 1 ? "" : "s")") }
        if days > 0 { parts.append("\(days) day\(days == 1 ? "" : "s")") }
        return parts.isEmpty ? "No time passed" : parts.joined(separator: ", ")
    }
}

struct VerificationResult {
    let success: Bool
    let drift: TimeInterval?
    let serverTime: Date?
}

enum VerificationStatus {
    case unverified
    case verified
    case failed
    case suspicious(drift: TimeInterval)
    
    var displayText: String {
        switch self {
        case .unverified: return "Not verified"
        case .verified: return "Verified"
        case .failed: return "Verification failed"
        case .suspicious(let drift):
            return "Suspicious drift: \(Int(drift))s"
        }
    }
}

// MARK: - World Time API Response
struct WorldTimeResponse: Codable {
    let datetime: Date
    let unixtime: Int
    
    enum CodingKeys: String, CodingKey {
        case datetime
        case unixtime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let datetimeString = try container.decode(String.self, forKey: .datetime)
        unixtime = try container.decode(Int.self, forKey: .unixtime)
        
        // Parse ISO8601 date
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: datetimeString) {
            datetime = date
        } else {
            // Fallback to unix time
            datetime = Date(timeIntervalSince1970: TimeInterval(unixtime))
        }
    }
}
