import Foundation

// MARK: - Injection Site Recommendation Service
// Tracks rotation separately for PED (IM) vs Peptide (SubQ) sites
final class InjectionSiteRecommendationService {

    // MARK: - Singleton
    static let shared = InjectionSiteRecommendationService()

    private init() {}

    // MARK: - Recommend Next Site for PEDs

    func recommendNextPEDSite() -> PEDInjectionSite {
        let history = CoreDataManager.shared.fetchInjectionHistory(
            for: .ped,
            limit: AppConstants.InjectionRotation.historyLookback
        )

        // Get recently used sites
        let recentSites = history.compactMap { log -> PEDInjectionSite? in
            guard let rawValue = log.injectionSiteRaw else { return nil }
            return PEDInjectionSite(rawValue: rawValue)
        }

        // If no history, start with left glute
        guard !recentSites.isEmpty else {
            return .gluteLeft
        }

        // Get last used site
        let lastSite = recentSites.first

        // Build usage frequency map
        var usageCount: [PEDInjectionSite: Int] = [:]
        for site in PEDInjectionSite.allCases {
            usageCount[site] = 0
        }
        for site in recentSites {
            usageCount[site, default: 0] += 1
        }

        // Find least used sites
        let minUsage = usageCount.values.min() ?? 0
        var candidates = usageCount.filter { $0.value == minUsage }.map { $0.key }

        // Exclude same side as last injection
        if let lastSite = lastSite {
            candidates = candidates.filter { !isSameSide($0, as: lastSite) }
        }

        // If no candidates after filtering, just avoid the exact same site
        if candidates.isEmpty {
            candidates = PEDInjectionSite.allCases.filter { $0 != lastSite }
        }

        // Prefer alternating body parts
        if let lastSite = lastSite {
            let differentBodyPart = candidates.filter { $0.bodyPart != lastSite.bodyPart }
            if !differentBodyPart.isEmpty {
                candidates = differentBodyPart
            }
        }

        // Return first candidate or default
        return candidates.first ?? .gluteLeft
    }

    // MARK: - Recommend Next Site for Peptides

    func recommendNextPeptideSite() -> PeptideInjectionSite {
        let history = CoreDataManager.shared.fetchInjectionHistory(
            for: .peptide,
            limit: AppConstants.InjectionRotation.historyLookback
        )

        // Get recently used sites
        let recentSites = history.compactMap { log -> PeptideInjectionSite? in
            guard let rawValue = log.injectionSiteRaw else { return nil }
            return PeptideInjectionSite(rawValue: rawValue)
        }

        // If no history, start with belly upper left
        guard !recentSites.isEmpty else {
            return .bellyUpperLeft
        }

        // Get last used site
        let lastSite = recentSites.first

        // Build usage frequency map
        var usageCount: [PeptideInjectionSite: Int] = [:]
        for site in PeptideInjectionSite.allCases {
            usageCount[site] = 0
        }
        for site in recentSites {
            usageCount[site, default: 0] += 1
        }

        // Find least used sites
        let minUsage = usageCount.values.min() ?? 0
        var candidates = usageCount.filter { $0.value == minUsage }.map { $0.key }

        // Exclude same side as last injection (for belly quadrants, alternate sides)
        if let lastSite = lastSite {
            let oppositeSide = candidates.filter { $0.isLeftSide != lastSite.isLeftSide }
            if !oppositeSide.isEmpty {
                candidates = oppositeSide
            }
        }

        // If no candidates after filtering, just avoid the exact same site
        if candidates.isEmpty {
            candidates = PeptideInjectionSite.allCases.filter { $0 != lastSite }
        }

        // Prefer belly sites as primary
        let bellySites = candidates.filter { $0.bodyPart == "Belly" }
        if !bellySites.isEmpty {
            candidates = bellySites
        }

        return candidates.first ?? .bellyUpperLeft
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

    // MARK: - Site Usage Statistics

    func siteUsageStats(for category: CompoundCategory) -> [(site: String, count: Int, lastUsed: Date?)] {
        let history = CoreDataManager.shared.fetchInjectionHistory(
            for: category,
            limit: 50 // Get more history for stats
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
