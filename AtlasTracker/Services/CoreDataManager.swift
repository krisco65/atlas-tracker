import Foundation
import CoreData
import Combine

// MARK: - Core Data Manager
final class CoreDataManager: ObservableObject {

    // MARK: - Singleton
    static let shared = CoreDataManager()

    // MARK: - Published Properties
    @Published var compounds: [Compound] = []
    @Published var trackedCompounds: [TrackedCompound] = []

    // MARK: - Error State
    @Published private(set) var initializationError: Error?
    @Published private(set) var isStoreLoaded: Bool = false

    /// Returns true if Core Data is ready to use
    var isReady: Bool {
        return isStoreLoaded && initializationError == nil
    }

    // MARK: - Persistent Container
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: AppConstants.coreDataModelName, managedObjectModel: CoreDataModelCreator.createModel())

        // Enable Data Protection for encrypted storage at rest
        if let storeDescription = container.persistentStoreDescriptions.first {
            storeDescription.setOption(
                FileProtectionType.complete as NSObject,
                forKey: NSPersistentStoreFileProtectionKey
            )

            // Enable lightweight migration
            storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }

        container.loadPersistentStores { [weak self] description, error in
            if let error = error {
                // Log the error instead of crashing
                Logger.error("Failed to load persistent store", error: error)

                // Store the error for UI to display
                DispatchQueue.main.async {
                    self?.initializationError = error
                    self?.isStoreLoaded = false
                }

                // Attempt recovery: delete and recreate store if corrupted
                if let storeURL = description.url {
                    self?.attemptStoreRecovery(at: storeURL, container: container)
                }
                return
            }

            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            DispatchQueue.main.async {
                self?.isStoreLoaded = true
                self?.initializationError = nil
            }

            Logger.coreData("Persistent store loaded successfully")
        }

        return container
    }()

    /// Attempt to recover from a corrupted store by deleting and recreating it
    private func attemptStoreRecovery(at url: URL, container: NSPersistentContainer) {
        Logger.warning("Attempting store recovery at: \(url.path)")

        do {
            // Remove the corrupted store files
            let fileManager = FileManager.default
            let storeDirectory = url.deletingLastPathComponent()
            let storeName = url.deletingPathExtension().lastPathComponent

            // Remove all related store files
            let storeFiles = try fileManager.contentsOfDirectory(at: storeDirectory, includingPropertiesForKeys: nil)
            for file in storeFiles where file.lastPathComponent.hasPrefix(storeName) {
                try fileManager.removeItem(at: file)
                Logger.coreData("Removed corrupted file: \(file.lastPathComponent)")
            }

            // Attempt to reload the store
            container.loadPersistentStores { [weak self] _, retryError in
                DispatchQueue.main.async {
                    if let retryError = retryError {
                        Logger.error("Recovery failed", error: retryError)
                        self?.initializationError = retryError
                        self?.isStoreLoaded = false
                    } else {
                        Logger.coreData("Store recovery successful - data has been reset")
                        self?.isStoreLoaded = true
                        self?.initializationError = nil
                    }
                }
            }
        } catch {
            Logger.error("Store recovery failed", error: error)
            DispatchQueue.main.async {
                self.initializationError = error
                self.isStoreLoaded = false
            }
        }
    }

    // MARK: - View Context
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Background Context
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }

    // MARK: - Initialization
    private init() {}

    // MARK: - Save Context
    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                Logger.coreData("Core Data save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    // MARK: - COMPOUND OPERATIONS

    /// Fetch all compounds
    func fetchAllCompounds() -> [Compound] {
        let request: NSFetchRequest<Compound> = Compound.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Compound.name, ascending: true)]

        do {
            let compounds = try viewContext.fetch(request)
            self.compounds = compounds
            return compounds
        } catch {
            Logger.coreData("Error fetching compounds: \(error)")
            return []
        }
    }

    /// Fetch compounds by category
    func fetchCompounds(category: CompoundCategory) -> [Compound] {
        let request: NSFetchRequest<Compound> = Compound.fetchRequest()
        request.predicate = NSPredicate(format: "categoryRaw == %@", category.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Compound.name, ascending: true)]

        do {
            return try viewContext.fetch(request)
        } catch {
            Logger.coreData("Error fetching compounds by category: \(error)")
            return []
        }
    }

    /// Search compounds by name
    func searchCompounds(query: String) -> [Compound] {
        guard !query.isEmpty else { return fetchAllCompounds() }

        let request: NSFetchRequest<Compound> = Compound.fetchRequest()
        request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Compound.name, ascending: true)]

        do {
            return try viewContext.fetch(request)
        } catch {
            Logger.coreData("Error searching compounds: \(error)")
            return []
        }
    }

    /// Fetch compounds sorted by favorites
    func fetchFavoriteCompounds() -> [Compound] {
        let request: NSFetchRequest<Compound> = Compound.fetchRequest()
        request.predicate = NSPredicate(format: "isFavorited == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Compound.name, ascending: true)]

        do {
            return try viewContext.fetch(request)
        } catch {
            Logger.coreData("Error fetching favorites: \(error)")
            return []
        }
    }

    /// Fetch compounds sorted by use count (frequently used)
    func fetchFrequentlyUsedCompounds(limit: Int = 20) -> [Compound] {
        let request: NSFetchRequest<Compound> = Compound.fetchRequest()
        request.predicate = NSPredicate(format: "useCount > 0")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Compound.useCount, ascending: false)]
        request.fetchLimit = limit

        do {
            return try viewContext.fetch(request)
        } catch {
            Logger.coreData("Error fetching frequently used: \(error)")
            return []
        }
    }

    /// Fetch compound by ID
    func fetchCompound(by id: UUID) -> Compound? {
        let request: NSFetchRequest<Compound> = Compound.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try viewContext.fetch(request).first
        } catch {
            Logger.coreData("Error fetching compound by ID: \(error)")
            return nil
        }
    }

    /// Create a new compound
    @discardableResult
    func createCompound(
        name: String,
        category: CompoundCategory,
        supportedUnits: [DosageUnit],
        defaultUnit: DosageUnit,
        requiresInjection: Bool = false,
        recommendedSites: [String] = [],
        isCustom: Bool = false
    ) -> Compound {
        let compound = Compound(
            context: viewContext,
            name: name,
            category: category,
            supportedUnits: supportedUnits,
            defaultUnit: defaultUnit,
            requiresInjection: requiresInjection,
            recommendedSites: recommendedSites,
            isCustom: isCustom
        )
        saveContext()
        return compound
    }

    /// Toggle favorite status
    func toggleFavorite(compound: Compound) {
        compound.isFavorited.toggle()
        saveContext()
    }

    /// Delete compound
    func deleteCompound(_ compound: Compound) {
        viewContext.delete(compound)
        saveContext()
    }

    // MARK: - TRACKED COMPOUND OPERATIONS

    /// Fetch all tracked compounds
    func fetchTrackedCompounds(activeOnly: Bool = true) -> [TrackedCompound] {
        let request: NSFetchRequest<TrackedCompound> = TrackedCompound.fetchRequest()

        if activeOnly {
            request.predicate = NSPredicate(format: "isActive == YES")
        }

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TrackedCompound.notificationTime, ascending: true)
        ]

        do {
            let tracked = try viewContext.fetch(request)
            self.trackedCompounds = tracked
            return tracked
        } catch {
            Logger.coreData("Error fetching tracked compounds: \(error)")
            return []
        }
    }

    /// Fetch today's scheduled doses
    func fetchTodaysScheduledDoses() -> [TrackedCompound] {
        let tracked = fetchTrackedCompounds(activeOnly: true)
        return tracked.filter { $0.isDueToday }
    }

    /// Start tracking a compound
    @discardableResult
    func startTracking(
        compound: Compound,
        dosageAmount: Double,
        dosageUnit: DosageUnit,
        scheduleType: ScheduleType,
        scheduleInterval: Int16? = nil,
        scheduleDays: [Int]? = nil,
        notificationEnabled: Bool = true,
        notificationTime: Date? = nil
    ) -> TrackedCompound {
        // Remove existing tracking if any
        if let existing = compound.trackedCompound {
            viewContext.delete(existing)
        }

        let tracked = TrackedCompound(
            context: viewContext,
            compound: compound,
            dosageAmount: dosageAmount,
            dosageUnit: dosageUnit,
            scheduleType: scheduleType,
            scheduleInterval: scheduleInterval,
            scheduleDays: scheduleDays,
            notificationEnabled: notificationEnabled,
            notificationTime: notificationTime
        )

        saveContext()
        return tracked
    }

    /// Stop tracking a compound
    func stopTracking(compound: Compound) {
        if let tracked = compound.trackedCompound {
            tracked.isActive = false
            saveContext()
        }
    }

    /// Delete tracking
    func deleteTracking(_ tracked: TrackedCompound) {
        viewContext.delete(tracked)
        saveContext()
    }

    // MARK: - DOSE LOG OPERATIONS

    /// Log a dose
    @discardableResult
    func logDose(
        compound: Compound,
        dosageAmount: Double,
        dosageUnit: DosageUnit,
        timestamp: Date = Date(),
        injectionSite: String? = nil,
        notes: String? = nil
    ) -> DoseLog {
        let log = DoseLog(
            context: viewContext,
            compound: compound,
            dosageAmount: dosageAmount,
            dosageUnit: dosageUnit,
            timestamp: timestamp,
            injectionSite: injectionSite,
            notes: notes
        )

        // Update compound use count
        compound.incrementUseCount()

        // Update tracked compound last dose date
        if let tracked = compound.trackedCompound {
            tracked.lastDoseDate = timestamp
        }

        // Auto-decrement inventory if applicable (1:1 relationship)
        if let inventory = compound.inventory {
            inventory.decrementByDose(dosageAmount)
        }

        saveContext()
        return log
    }

    /// Fetch dose logs for a compound
    func fetchDoseLogs(for compound: Compound, limit: Int? = nil) -> [DoseLog] {
        let request: NSFetchRequest<DoseLog> = DoseLog.fetchRequest()
        request.predicate = NSPredicate(format: "compound == %@", compound)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DoseLog.timestamp, ascending: false)]

        if let limit = limit {
            request.fetchLimit = limit
        }

        do {
            return try viewContext.fetch(request)
        } catch {
            Logger.coreData("Error fetching dose logs: \(error)")
            return []
        }
    }

    /// Fetch dose logs within date range
    func fetchDoseLogs(from startDate: Date, to endDate: Date) -> [DoseLog] {
        let request: NSFetchRequest<DoseLog> = DoseLog.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startDate as CVarArg, endDate as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DoseLog.timestamp, ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            Logger.coreData("Error fetching dose logs by date range: \(error)")
            return []
        }
    }

    /// Fetch injection site history for a category (separate PED vs Peptide)
    func fetchInjectionHistory(for category: CompoundCategory, limit: Int = 10) -> [DoseLog] {
        let request: NSFetchRequest<DoseLog> = DoseLog.fetchRequest()
        request.predicate = NSPredicate(
            format: "compound.categoryRaw == %@ AND injectionSiteRaw != nil",
            category.rawValue
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DoseLog.timestamp, ascending: false)]
        request.fetchLimit = limit

        do {
            return try viewContext.fetch(request)
        } catch {
            Logger.coreData("Error fetching injection history: \(error)")
            return []
        }
    }

    /// Delete dose log
    func deleteDoseLog(_ log: DoseLog) {
        viewContext.delete(log)
        saveContext()
    }

    // MARK: - INVENTORY OPERATIONS

    /// Create or update inventory for a compound
    @discardableResult
    func setInventory(
        for compound: Compound,
        vialCount: Int16,
        vialSizeMg: Double,
        lowStockThreshold: Int16 = AppConstants.Inventory.defaultLowStockThreshold
    ) -> Inventory {
        // Check if inventory already exists (1:1 relationship)
        if let existing = compound.inventory {
            existing.vialCount = vialCount
            existing.vialSizeMg = vialSizeMg
            existing.lowStockThreshold = lowStockThreshold
            existing.lastUpdated = Date()
            saveContext()
            return existing
        }

        // Create new inventory
        let inventory = Inventory(
            context: viewContext,
            compound: compound,
            vialCount: vialCount,
            vialSizeMg: vialSizeMg,
            lowStockThreshold: lowStockThreshold
        )
        saveContext()
        return inventory
    }

    /// Fetch all low stock items
    func fetchLowStockItems() -> [Inventory] {
        let request: NSFetchRequest<Inventory> = Inventory.fetchRequest()
        request.predicate = NSPredicate(format: "vialCount <= lowStockThreshold")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Inventory.vialCount, ascending: true)]

        do {
            return try viewContext.fetch(request)
        } catch {
            Logger.coreData("Error fetching low stock items: \(error)")
            return []
        }
    }

    // MARK: - WEIGHT ENTRY OPERATIONS

    /// Log a weight entry
    @discardableResult
    func logWeight(
        weight: Double,
        unit: WeightUnit,
        date: Date = Date(),
        compound: Compound? = nil,
        notes: String? = nil
    ) -> WeightEntry {
        let entry = WeightEntry(
            context: viewContext,
            weight: weight,
            unit: unit,
            date: date,
            compound: compound,
            notes: notes
        )
        saveContext()
        return entry
    }

    /// Fetch weight entries
    func fetchWeightEntries(for compound: Compound? = nil, limit: Int? = nil) -> [WeightEntry] {
        let request: NSFetchRequest<WeightEntry> = WeightEntry.fetchRequest()

        if let compound = compound {
            request.predicate = NSPredicate(format: "compound == %@", compound)
        }

        request.sortDescriptors = [NSSortDescriptor(keyPath: \WeightEntry.date, ascending: false)]

        if let limit = limit {
            request.fetchLimit = limit
        }

        do {
            return try viewContext.fetch(request)
        } catch {
            Logger.coreData("Error fetching weight entries: \(error)")
            return []
        }
    }

    /// Fetch weight entries within date range
    func fetchWeightEntries(from startDate: Date, to endDate: Date, compound: Compound? = nil) -> [WeightEntry] {
        let request: NSFetchRequest<WeightEntry> = WeightEntry.fetchRequest()

        var predicates: [NSPredicate] = [
            NSPredicate(format: "date >= %@ AND date <= %@", startDate as CVarArg, endDate as CVarArg)
        ]

        if let compound = compound {
            predicates.append(NSPredicate(format: "compound == %@", compound))
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WeightEntry.date, ascending: true)]

        do {
            return try viewContext.fetch(request)
        } catch {
            Logger.coreData("Error fetching weight entries by date range: \(error)")
            return []
        }
    }

    // MARK: - ANALYTICS HELPERS

    /// Get dose count for time period
    func doseCount(from startDate: Date, to endDate: Date) -> Int {
        let request: NSFetchRequest<DoseLog> = DoseLog.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startDate as CVarArg, endDate as CVarArg)

        do {
            return try viewContext.count(for: request)
        } catch {
            Logger.coreData("Error counting doses: \(error)")
            return 0
        }
    }

    /// Get unique compounds used in time period
    func uniqueCompoundsUsed(from startDate: Date, to endDate: Date) -> [Compound] {
        let logs = fetchDoseLogs(from: startDate, to: endDate)
        let compounds = Set(logs.compactMap { $0.compound })
        return Array(compounds)
    }

    // MARK: - DATA RESET (for testing)

    /// Delete all data (use with caution!)
    func resetAllData() {
        let entityNames = ["DoseLog", "TrackedCompound", "Inventory", "WeightEntry", "Compound"]

        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try viewContext.execute(deleteRequest)
            } catch {
                Logger.coreData("Error deleting \(entityName): \(error)")
            }
        }

        saveContext()
    }
}
