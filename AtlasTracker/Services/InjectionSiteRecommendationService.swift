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

        // If no history, start with left glute
        guard !history.isEmpty else {
            return .gluteLeft
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

        return sorted.first?.site ?? .gluteLeft
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
}
