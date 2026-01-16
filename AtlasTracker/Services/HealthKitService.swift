import Foundation
import HealthKit

/// Service for integrating with Apple Health
final class HealthKitService {

    static let shared = HealthKitService()

    // Lazy initialization to prevent crashes on devices without HealthKit
    private var _healthStore: HKHealthStore?
    private var healthStore: HKHealthStore? {
        if _healthStore == nil && isHealthKitAvailable {
            _healthStore = HKHealthStore()
        }
        return _healthStore
    }

    private init() {}

    // MARK: - Availability

    var isHealthKitAvailable: Bool {
        // Check if HealthKit is available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }
        return true
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard isHealthKitAvailable, let store = healthStore else {
            print("HealthKit not available on this device")
            return false
        }

        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            print("HealthKit bodyMass type not available")
            return false
        }

        do {
            try await store.requestAuthorization(toShare: [weightType], read: [weightType])
            return true
        } catch {
            print("HealthKit authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    func isAuthorized() -> Bool {
        guard isHealthKitAvailable, let store = healthStore else { return false }

        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return false
        }

        let status = store.authorizationStatus(for: weightType)
        return status == .sharingAuthorized
    }

    // MARK: - Read Weight Data

    /// Fetches weight entries from Apple Health within the given date range
    func fetchWeightEntries(from startDate: Date, to endDate: Date) async -> [HealthWeightEntry] {
        guard isHealthKitAvailable, let store = healthStore else { return [] }

        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("HealthKit query failed: \(error)")
                    continuation.resume(returning: [])
                    return
                }

                guard let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let entries = quantitySamples.map { sample -> HealthWeightEntry in
                    // Get weight in pounds (default unit for US)
                    let weightInPounds = sample.quantity.doubleValue(for: .pound())
                    let weightInKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))

                    return HealthWeightEntry(
                        date: sample.startDate,
                        weightLbs: weightInPounds,
                        weightKg: weightInKg,
                        source: sample.sourceRevision.source.name
                    )
                }

                continuation.resume(returning: entries)
            }

            store.execute(query)
        }
    }

    /// Fetches the most recent weight entry from Apple Health
    func fetchLatestWeight() async -> HealthWeightEntry? {
        guard isHealthKitAvailable, let store = healthStore else { return nil }

        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return nil
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("HealthKit query failed: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let entry = HealthWeightEntry(
                    date: sample.startDate,
                    weightLbs: sample.quantity.doubleValue(for: .pound()),
                    weightKg: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)),
                    source: sample.sourceRevision.source.name
                )

                continuation.resume(returning: entry)
            }

            store.execute(query)
        }
    }

    // MARK: - Write Weight Data

    /// Saves a weight entry to Apple Health
    func saveWeight(_ weight: Double, unit: WeightUnit, date: Date) async -> Bool {
        guard isHealthKitAvailable, let store = healthStore else { return false }

        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return false
        }

        // Convert to HKUnit
        let hkUnit: HKUnit = unit == .lbs ? .pound() : .gramUnit(with: .kilo)
        let quantity = HKQuantity(unit: hkUnit, doubleValue: weight)

        let sample = HKQuantitySample(
            type: weightType,
            quantity: quantity,
            start: date,
            end: date
        )

        do {
            try await store.save(sample)
            return true
        } catch {
            print("HealthKit save failed: \(error)")
            return false
        }
    }

    // MARK: - Import to CoreData

    /// Imports weight entries from Apple Health to CoreData
    func importWeightEntriesToCoreData(from startDate: Date, to endDate: Date) async -> Int {
        let healthEntries = await fetchWeightEntries(from: startDate, to: endDate)

        var importCount = 0

        for entry in healthEntries {
            // Check if entry already exists (by date, within 1 minute tolerance)
            let existingEntries = CoreDataManager.shared.fetchWeightEntries(from: entry.date.addingTimeInterval(-60), to: entry.date.addingTimeInterval(60))

            if existingEntries.isEmpty {
                // Import the entry
                let preferredUnit = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.preferredWeightUnit) ?? WeightUnit.lbs.rawValue
                let unit = WeightUnit(rawValue: preferredUnit) ?? .lbs
                let weight = unit == .lbs ? entry.weightLbs : entry.weightKg

                CoreDataManager.shared.logWeight(
                    weight: weight,
                    unit: unit,
                    date: entry.date,
                    notes: "Imported from Apple Health (\(entry.source))"
                )
                importCount += 1
            }
        }

        return importCount
    }
}

// MARK: - Health Weight Entry

struct HealthWeightEntry {
    let date: Date
    let weightLbs: Double
    let weightKg: Double
    let source: String

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
