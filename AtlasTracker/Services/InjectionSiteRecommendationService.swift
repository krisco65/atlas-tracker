import Foundation

// MARK: - Injection Site Recommendation Service
// Tracks rotation separately for PED (IM) vs Peptide (SubQ) sites
// Uses time-weighted scoring and body part balancing for better rotation
final class InjectionSiteRecommendationService {

    // MARK: - Singleton
    static let shared = InjectionSiteRecommendationService()

    private init() {}

    // MARK: - Time-Weighted Scoring

    /// Calculates a score for a site based on recent usage.
    /// Lower score = better candidate (used less recently/frequently)
    private func calculateTimeWeightedScore<T: Hashable>(
        for site: T,
        in history: [(site: T, date: Date)]
    ) -> Double {
        let now = Date()
        var score = 0.0

        for entry in history where entry.site == site {
            let daysSince = max(0, now.daysBetween(entry.date))
            // Recent usage adds more to the score (higher penalty)
            // Score = 1 / (days + 1) so same-day = 1.0, 1 day ago = 0.5, etc.
            score += 1.0 / Double(daysSince + 1)
        }

        return score
    }

    /// Gets the date a site was last used, returns distant past if never used
    private func lastUsedDate<T: Hashable>(for site: T, in history: [(site: T, date: Date)]) -> Date {
        for entry in history where entry.site == site {
            return entry.date
        }
        return Date.distantPast
    }

    // MARK: - Body Part Balancing

    /// Groups sites by body part and returns the least-used body part
    private func leastUsedBodyPart(
        for sites: [PEDInjectionSite],
        history: [PEDInjectionSite]
    ) -> String? {
        var bodyPartUsage: [String: Int] = [:]

        // Initialize all body parts
        for site in PEDInjectionSite.allCases {
            bodyPartUsage[site.bodyPart] = 0
        }

        // Count usage per body part
        for site in history {
            bodyPartUsage[site.bodyPart, default: 0] += 1
        }

        // Return the body part with minimum usage
        return bodyPartUsage.min(by: { $0.value < $1.value })?.key
    }

    // MARK: - Recommend Next Site for PEDs

    func recommendNextPEDSite() -> PEDInjectionSite {
        let historyLogs = CoreDataManager.shared.fetchInjectionHistory(
            for: .ped,
            limit: AppConstants.InjectionRotation.historyLookback
        )

        // Convert to tuple array with dates for time-weighted scoring
        let history: [(site: PEDInjectionSite, date: Date)] = historyLogs.compactMap { log in
            guard let rawValue = log.injectionSiteRaw,
                  let site = PEDInjectionSite(rawValue: rawValue),
                  let date = log.timestamp else { return nil }
            return (site: site, date: date)
        }

        // If no history, start with left glute upper
        guard !history.isEmpty else {
            return .gluteLeftUpper
        }

        // Get last used site
        let lastSite = history.first?.site
        let recentSites = history.map { $0.site }

        // STEP 1: Find the least-used body part first
        let targetBodyPart = leastUsedBodyPart(for: PEDInjectionSite.allCases, history: recentSites)

        // STEP 2: Get sites in the target body part
        var candidates = PEDInjectionSite.allCases.filter { site in
            targetBodyPart == nil || site.bodyPart == targetBodyPart
        }

        // STEP 3: Exclude same side as last injection
        if let lastSite = lastSite {
            let oppositeSide = candidates.filter { !isSameSide($0, as: lastSite) }
            if !oppositeSide.isEmpty {
                candidates = oppositeSide
            }
        }

        // STEP 4: If no candidates, fall back to all sites except last used
        if candidates.isEmpty {
            candidates = PEDInjectionSite.allCases.filter { $0 != lastSite }
        }

        // STEP 5: Calculate time-weighted scores for remaining candidates
        let scoredCandidates = candidates.map { site -> (site: PEDInjectionSite, score: Double, lastUsed: Date) in
            let score = calculateTimeWeightedScore(for: site, in: history)
            let lastUsed = lastUsedDate(for: site, in: history)
            return (site: site, score: score, lastUsed: lastUsed)
        }

        // STEP 6: Sort by score (lowest first), then by last used date (oldest first)
        let sorted = scoredCandidates.sorted { a, b in
            if a.score != b.score {
                return a.score < b.score // Prefer lower score
            }
            return a.lastUsed < b.lastUsed // Tie-break: older = better
        }

        return sorted.first?.site ?? .gluteLeftUpper
    }

    // MARK: - Body Part Balancing for Peptides

    /// Groups peptide sites by body part and returns the least-used body part
    private func leastUsedPeptideBodyPart(history: [PeptideInjectionSite]) -> String? {
        var bodyPartUsage: [String: Int] = [:]

        // Initialize all body parts
        for site in PeptideInjectionSite.allCases {
            bodyPartUsage[site.bodyPart] = 0
        }

        // Count usage per body part
        for site in history {
            bodyPartUsage[site.bodyPart, default: 0] += 1
        }

        // Prefer belly sites when equally used
        let minUsage = bodyPartUsage.values.min() ?? 0
        let leastUsedParts = bodyPartUsage.filter { $0.value == minUsage }.map { $0.key }

        // If belly is among least used, prefer it
        if leastUsedParts.contains("Belly") {
            return "Belly"
        }

        return leastUsedParts.first
    }

    // MARK: - Recommend Next Site for Peptides

    func recommendNextPeptideSite() -> PeptideInjectionSite {
        let historyLogs = CoreDataManager.shared.fetchInjectionHistory(
            for: .peptide,
            limit: AppConstants.InjectionRotation.historyLookback
        )

        // Convert to tuple array with dates for time-weighted scoring
        let history: [(site: PeptideInjectionSite, date: Date)] = historyLogs.compactMap { log in
            guard let rawValue = log.injectionSiteRaw,
                  let site = PeptideInjectionSite(rawValue: rawValue),
                  let date = log.timestamp else { return nil }
            return (site: site, date: date)
        }

        // If no history, start with left belly upper
        guard !history.isEmpty else {
            return .leftBellyUpper
        }

        // Get last used site
        let lastSite = history.first?.site
        let recentSites = history.map { $0.site }

        // STEP 1: Find the least-used body part first (with belly preference)
        let targetBodyPart = leastUsedPeptideBodyPart(history: recentSites)

        // STEP 2: Get sites in the target body part
        var candidates = PeptideInjectionSite.allCases.filter { site in
            targetBodyPart == nil || site.bodyPart == targetBodyPart
        }

        // STEP 3: Exclude same side as last injection
        if let lastSite = lastSite {
            let oppositeSide = candidates.filter { $0.isLeftSide != lastSite.isLeftSide }
            if !oppositeSide.isEmpty {
                candidates = oppositeSide
            }
        }

        // STEP 4: If no candidates, fall back to all sites except last used
        if candidates.isEmpty {
            candidates = PeptideInjectionSite.allCases.filter { $0 != lastSite }
        }

        // STEP 5: Calculate time-weighted scores for remaining candidates
        let scoredCandidates = candidates.map { site -> (site: PeptideInjectionSite, score: Double, lastUsed: Date) in
            let score = calculateTimeWeightedScore(for: site, in: history)
            let lastUsed = lastUsedDate(for: site, in: history)
            return (site: site, score: score, lastUsed: lastUsed)
        }

        // STEP 6: Sort by score (lowest first), then by last used date (oldest first)
        let sorted = scoredCandidates.sorted { a, b in
            if a.score != b.score {
                return a.score < b.score // Prefer lower score
            }
            return a.lastUsed < b.lastUsed // Tie-break: older = better
        }

        return sorted.first?.site ?? .leftBellyUpper
    }

    // MARK: - Recommend Next Site (Generic)

    func recommendNextSite(for compound: Compound) -> String? {
        guard compound.requiresInjection else { return nil }

        switch compound.category {
        case .ped:
            return recommendNextPEDSite().displayName
        case .peptide:
            return recommendNextPeptideSite().displayName
        default:
            return nil
        }
    }

    func recommendNextSiteRawValue(for compound: Compound) -> String? {
        guard compound.requiresInjection else { return nil }

        switch compound.category {
        case .ped:
            return recommendNextPEDSite().rawValue
        case .peptide:
            return recommendNextPeptideSite().rawValue
        default:
            return nil
        }
    }

    // MARK: - Get Last Used Site

    func lastUsedSite(for compound: Compound) -> String? {
        let logs = CoreDataManager.shared.fetchDoseLogs(for: compound, limit: 1)
        return logs.first?.injectionSiteRaw
    }

    func lastUsedSiteDisplayName(for compound: Compound) -> String? {
        guard let rawValue = lastUsedSite(for: compound) else { return nil }

        switch compound.category {
        case .ped:
            return PEDInjectionSite(rawValue: rawValue)?.displayName
        case .peptide:
            return PeptideInjectionSite(rawValue: rawValue)?.displayName
        default:
            return nil
        }
    }

    func lastUsedSiteRawValue(for compound: Compound) -> String? {
        return lastUsedSite(for: compound)
    }

    // MARK: - Recent Site History

    struct SiteHistoryEntry {
        let rawValue: String
        let displayName: String
        let date: Date
    }

    func recentSiteHistory(for compound: Compound, limit: Int = 5) -> [SiteHistoryEntry] {
        let logs = CoreDataManager.shared.fetchDoseLogs(for: compound, limit: limit)

        return logs.compactMap { log -> SiteHistoryEntry? in
            guard let rawValue = log.injectionSiteRaw,
                  let timestamp = log.timestamp else { return nil }

            let displayName: String
            switch compound.category {
            case .ped:
                displayName = PEDInjectionSite(rawValue: rawValue)?.displayName ?? rawValue
            case .peptide:
                displayName = PeptideInjectionSite(rawValue: rawValue)?.displayName ?? rawValue
            default:
                displayName = rawValue
            }

            return SiteHistoryEntry(rawValue: rawValue, displayName: displayName, date: timestamp)
        }
    }

    // MARK: - Site Usage Statistics

    func siteUsageStats(for category: CompoundCategory) -> [(site: String, count: Int, lastUsed: Date?)] {
        let history = CoreDataManager.shared.fetchInjectionHistory(
            for: category,
            limit: AppConstants.InjectionRotation.statsLookback
        )

        var stats: [String: (count: Int, lastUsed: Date?)] = [:]

        // Initialize all sites with 0 count
        let allSites: [String]
        switch category {
        case .ped:
            allSites = PEDInjectionSite.allCases.map { $0.displayName }
        case .peptide:
            allSites = PeptideInjectionSite.allCases.map { $0.displayName }
        default:
            return []
        }

        for site in allSites {
            stats[site] = (count: 0, lastUsed: nil)
        }

        // Count usage
        for log in history {
            guard let siteName = log.injectionSiteDisplayName else { continue }
            var current = stats[siteName] ?? (count: 0, lastUsed: nil)
            current.count += 1
            if current.lastUsed == nil {
                current.lastUsed = log.timestamp
            }
            stats[siteName] = current
        }

        // Convert to array and sort
        return stats.map { (site: $0.key, count: $0.value.count, lastUsed: $0.value.lastUsed) }
            .sorted { $0.count < $1.count }
    }

    // MARK: - Helpers

    private func isSameSide(_ site1: PEDInjectionSite, as site2: PEDInjectionSite) -> Bool {
        return site1.isLeftSide == site2.isLeftSide
    }

    // MARK: - Minimum Interval Enforcement

    struct IntervalCheckResult {
        let isAllowed: Bool
        let site: String
        let hoursRemaining: Int?
        let warning: String?

        var formattedTimeRemaining: String? {
            guard let hours = hoursRemaining else { return nil }
            if hours < 1 {
                return "less than 1 hour"
            } else if hours == 1 {
                return "1 hour"
            } else if hours < 24 {
                return "\(hours) hours"
            } else {
                let days = hours / 24
                let remainingHours = hours % 24
                if remainingHours == 0 {
                    return days == 1 ? "1 day" : "\(days) days"
                } else {
                    return days == 1 ? "1 day, \(remainingHours)h" : "\(days) days, \(remainingHours)h"
                }
            }
        }
    }

    /// Checks if enough time has passed since the last injection at the specified site.
    /// Enforces minimum intervals: 48h for PED (IM), 24h for peptide (SubQ).
    func checkMinimumInterval(for site: String, category: CompoundCategory) -> IntervalCheckResult {
        let minimumHours: Int
        switch category {
        case .ped:
            minimumHours = AppConstants.InjectionRotation.pedMinimumIntervalHours
        case .peptide:
            minimumHours = AppConstants.InjectionRotation.peptideMinimumIntervalHours
        default:
            return IntervalCheckResult(isAllowed: true, site: site, hoursRemaining: nil, warning: nil)
        }

        // Find last injection at this site
        let history = CoreDataManager.shared.fetchInjectionHistory(for: category, limit: 50)
        let matchingLogs = history.filter { $0.injectionSiteRaw == site }

        guard let lastInjection = matchingLogs.first,
              let timestamp = lastInjection.timestamp else {
            return IntervalCheckResult(isAllowed: true, site: site, hoursRemaining: nil, warning: nil)
        }

        let hoursSinceLastInjection = Int(Date().timeIntervalSince(timestamp) / 3600)

        if hoursSinceLastInjection >= minimumHours {
            return IntervalCheckResult(isAllowed: true, site: site, hoursRemaining: nil, warning: nil)
        }

        let hoursRemaining = minimumHours - hoursSinceLastInjection
        let siteDisplayName = displayName(for: site, category: category)

        return IntervalCheckResult(
            isAllowed: false,
            site: siteDisplayName,
            hoursRemaining: hoursRemaining,
            warning: "\(siteDisplayName) was used recently. Wait \(hoursRemaining)h for tissue recovery."
        )
    }

    /// Checks minimum interval and returns sites that are currently available.
    func availableSites(for category: CompoundCategory) -> [String] {
        let allSites: [String]

        switch category {
        case .ped:
            allSites = PEDInjectionSite.allCases.map { $0.rawValue }
        case .peptide:
            allSites = PeptideInjectionSite.allCases.map { $0.rawValue }
        default:
            return []
        }

        return allSites.filter { site in
            checkMinimumInterval(for: site, category: category).isAllowed
        }
    }

    /// Returns sites that are blocked due to minimum interval, with remaining wait time.
    func blockedSites(for category: CompoundCategory) -> [(site: String, hoursRemaining: Int)] {
        let allSites: [String]

        switch category {
        case .ped:
            allSites = PEDInjectionSite.allCases.map { $0.rawValue }
        case .peptide:
            allSites = PeptideInjectionSite.allCases.map { $0.rawValue }
        default:
            return []
        }

        return allSites.compactMap { site -> (site: String, hoursRemaining: Int)? in
            let result = checkMinimumInterval(for: site, category: category)
            guard !result.isAllowed, let hours = result.hoursRemaining else { return nil }
            return (site: displayName(for: site, category: category), hoursRemaining: hours)
        }.sorted { $0.hoursRemaining < $1.hoursRemaining }
    }

    /// Returns display name for a raw site value
    private func displayName(for rawValue: String, category: CompoundCategory) -> String {
        switch category {
        case .ped:
            return PEDInjectionSite(rawValue: rawValue)?.displayName ?? rawValue
        case .peptide:
            return PeptideInjectionSite(rawValue: rawValue)?.displayName ?? rawValue
        default:
            return rawValue
        }
    }

    // MARK: - Rotation Pattern Validation

    func validateRotation(for compound: Compound) -> (isGood: Bool, message: String) {
        let history = CoreDataManager.shared.fetchDoseLogs(for: compound, limit: 5)

        guard history.count >= 2 else {
            return (true, "Not enough history to evaluate rotation")
        }

        let sites = history.compactMap { $0.injectionSiteRaw }
        let uniqueSites = Set(sites)

        if uniqueSites.count == 1 && sites.count > 2 {
            return (false, "Warning: Same site used multiple times. Consider rotating to prevent scar tissue.")
        }

        // Check for consecutive same-side injections
        var consecutiveSameSide = 0
        for i in 1..<sites.count {
            let current = sites[i]
            let previous = sites[i-1]

            let currentIsLeft: Bool
            let previousIsLeft: Bool

            if compound.category == .ped {
                currentIsLeft = PEDInjectionSite(rawValue: current)?.isLeftSide ?? false
                previousIsLeft = PEDInjectionSite(rawValue: previous)?.isLeftSide ?? false
            } else {
                currentIsLeft = PeptideInjectionSite(rawValue: current)?.isLeftSide ?? false
                previousIsLeft = PeptideInjectionSite(rawValue: previous)?.isLeftSide ?? false
            }

            if currentIsLeft == previousIsLeft {
                consecutiveSameSide += 1
            }
        }

        if consecutiveSameSide >= 2 {
            return (false, "Tip: Try alternating between left and right sides for better rotation.")
        }

        return (true, "Good rotation pattern!")
    }

    // MARK: - Rotation Quality Score

    struct RotationQualityResult {
        let score: Int  // 0-100
        let rating: Rating
        let factors: [QualityFactor]

        enum Rating: String {
            case excellent = "Excellent"
            case good = "Good"
            case fair = "Fair"
            case poor = "Poor"
            case insufficient = "Insufficient Data"

            var color: String {
                switch self {
                case .excellent: return "statusSuccess"
                case .good: return "accentSecondary"
                case .fair: return "statusWarning"
                case .poor: return "statusError"
                case .insufficient: return "textTertiary"
                }
            }
        }

        struct QualityFactor {
            let name: String
            let score: Int  // 0-100 for this factor
            let weight: Double
            let feedback: String
        }
    }

    /// Calculates a rotation quality score from 0-100 based on injection site rotation patterns.
    /// Evaluates: site diversity, side alternation, body part distribution, and recovery time.
    func calculateRotationQualityScore(for category: CompoundCategory) -> RotationQualityResult {
        let historyLogs = CoreDataManager.shared.fetchInjectionHistory(
            for: category,
            limit: AppConstants.InjectionRotation.historyLookback
        )

        guard historyLogs.count >= 3 else {
            return RotationQualityResult(
                score: 0,
                rating: .insufficient,
                factors: []
            )
        }

        var factors: [RotationQualityResult.QualityFactor] = []

        // Factor 1: Site Diversity (30% weight)
        let diversityResult = calculateDiversityScore(historyLogs, category: category)
        factors.append(diversityResult)

        // Factor 2: Side Alternation (25% weight)
        let alternationResult = calculateAlternationScore(historyLogs, category: category)
        factors.append(alternationResult)

        // Factor 3: Body Part Distribution (25% weight)
        let distributionResult = calculateDistributionScore(historyLogs, category: category)
        factors.append(distributionResult)

        // Factor 4: Recovery Time (20% weight)
        let recoveryResult = calculateRecoveryScore(historyLogs, category: category)
        factors.append(recoveryResult)

        // Calculate weighted total score
        let totalScore = factors.reduce(0.0) { $0 + Double($1.score) * $1.weight }
        let finalScore = Int(min(100, max(0, totalScore)))

        let rating: RotationQualityResult.Rating
        switch finalScore {
        case 85...100: rating = .excellent
        case 70..<85: rating = .good
        case 50..<70: rating = .fair
        default: rating = .poor
        }

        return RotationQualityResult(score: finalScore, rating: rating, factors: factors)
    }

    // MARK: - Quality Factor Calculations

    private func calculateDiversityScore(
        _ logs: [DoseLog],
        category: CompoundCategory
    ) -> RotationQualityResult.QualityFactor {
        let sites = logs.compactMap { $0.injectionSiteRaw }
        let uniqueSites = Set(sites)
        let totalPossibleSites = category == .ped ? PEDInjectionSite.allCases.count : PeptideInjectionSite.allCases.count

        // Score based on percentage of available sites used
        let usageRatio = Double(uniqueSites.count) / Double(totalPossibleSites)
        let score = Int(min(100, usageRatio * 150))  // Using 150% allows partial use to still score well

        let feedback: String
        if score >= 80 {
            feedback = "Using a wide variety of injection sites"
        } else if score >= 50 {
            feedback = "Good variety, consider exploring more sites"
        } else {
            feedback = "Try using more different injection sites"
        }

        return RotationQualityResult.QualityFactor(
            name: "Site Diversity",
            score: score,
            weight: 0.30,
            feedback: feedback
        )
    }

    private func calculateAlternationScore(
        _ logs: [DoseLog],
        category: CompoundCategory
    ) -> RotationQualityResult.QualityFactor {
        guard logs.count >= 2 else {
            return RotationQualityResult.QualityFactor(
                name: "Side Alternation",
                score: 100,
                weight: 0.25,
                feedback: "Not enough data"
            )
        }

        var alternations = 0
        var total = 0

        for i in 1..<logs.count {
            guard let currentRaw = logs[i].injectionSiteRaw,
                  let previousRaw = logs[i-1].injectionSiteRaw else { continue }

            let currentIsLeft: Bool
            let previousIsLeft: Bool

            if category == .ped {
                currentIsLeft = PEDInjectionSite(rawValue: currentRaw)?.isLeftSide ?? false
                previousIsLeft = PEDInjectionSite(rawValue: previousRaw)?.isLeftSide ?? false
            } else {
                currentIsLeft = PeptideInjectionSite(rawValue: currentRaw)?.isLeftSide ?? false
                previousIsLeft = PeptideInjectionSite(rawValue: previousRaw)?.isLeftSide ?? false
            }

            total += 1
            if currentIsLeft != previousIsLeft {
                alternations += 1
            }
        }

        let score = total > 0 ? Int((Double(alternations) / Double(total)) * 100) : 100

        let feedback: String
        if score >= 80 {
            feedback = "Excellent left/right alternation"
        } else if score >= 50 {
            feedback = "Consider alternating sides more consistently"
        } else {
            feedback = "Alternate between left and right sides"
        }

        return RotationQualityResult.QualityFactor(
            name: "Side Alternation",
            score: score,
            weight: 0.25,
            feedback: feedback
        )
    }

    private func calculateDistributionScore(
        _ logs: [DoseLog],
        category: CompoundCategory
    ) -> RotationQualityResult.QualityFactor {
        var bodyPartCounts: [String: Int] = [:]

        for log in logs {
            guard let rawValue = log.injectionSiteRaw else { continue }

            let bodyPart: String?
            if category == .ped {
                bodyPart = PEDInjectionSite(rawValue: rawValue)?.bodyPart
            } else {
                bodyPart = PeptideInjectionSite(rawValue: rawValue)?.bodyPart
            }

            if let part = bodyPart {
                bodyPartCounts[part, default: 0] += 1
            }
        }

        guard !bodyPartCounts.isEmpty else {
            return RotationQualityResult.QualityFactor(
                name: "Body Part Distribution",
                score: 0,
                weight: 0.25,
                feedback: "No injection data available"
            )
        }

        // Calculate standard deviation to measure balance
        let values = Array(bodyPartCounts.values)
        let mean = Double(values.reduce(0, +)) / Double(values.count)
        let variance = values.map { pow(Double($0) - mean, 2) }.reduce(0, +) / Double(values.count)
        let stdDev = sqrt(variance)

        // Lower stdDev = more balanced = higher score
        // Normalize: if stdDev is 0, score is 100; increases reduce score
        let normalizedStdDev = stdDev / mean  // Coefficient of variation
        let score = Int(max(0, 100 - normalizedStdDev * 100))

        let feedback: String
        if score >= 80 {
            feedback = "Well-balanced across body parts"
        } else if score >= 50 {
            feedback = "Some body parts used more than others"
        } else {
            feedback = "Distribute injections more evenly"
        }

        return RotationQualityResult.QualityFactor(
            name: "Body Part Balance",
            score: score,
            weight: 0.25,
            feedback: feedback
        )
    }

    private func calculateRecoveryScore(
        _ logs: [DoseLog],
        category: CompoundCategory
    ) -> RotationQualityResult.QualityFactor {
        // Track minimum days between same-site injections
        var siteLastUsed: [String: Date] = [:]
        var minRecoveryDays: [Int] = []

        // Process logs oldest to newest
        let sortedLogs = logs.sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }

        for log in sortedLogs {
            guard let site = log.injectionSiteRaw,
                  let timestamp = log.timestamp else { continue }

            if let lastUsed = siteLastUsed[site] {
                let daysBetween = Calendar.current.dateComponents([.day], from: lastUsed, to: timestamp).day ?? 0
                minRecoveryDays.append(daysBetween)
            }
            siteLastUsed[site] = timestamp
        }

        guard !minRecoveryDays.isEmpty else {
            return RotationQualityResult.QualityFactor(
                name: "Recovery Time",
                score: 100,
                weight: 0.20,
                feedback: "No repeat sites yet"
            )
        }

        // Ideal minimum recovery: 7 days for same site
        let idealRecoveryDays = 7
        let avgRecovery = minRecoveryDays.reduce(0, +) / minRecoveryDays.count
        let score = Int(min(100, (Double(avgRecovery) / Double(idealRecoveryDays)) * 100))

        let feedback: String
        if score >= 80 {
            feedback = "Good recovery time between same-site uses"
        } else if score >= 50 {
            feedback = "Allow more time before reusing sites"
        } else {
            feedback = "Wait longer before reusing injection sites"
        }

        return RotationQualityResult.QualityFactor(
            name: "Recovery Time",
            score: score,
            weight: 0.20,
            feedback: feedback
        )
    }
}
