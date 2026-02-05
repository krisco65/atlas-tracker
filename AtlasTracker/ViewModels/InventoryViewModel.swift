import Foundation
import Observation
import SwiftUI
import CoreData

// MARK: - Inventory View Model
@Observable
final class InventoryViewModel {

    // MARK: - Observable Properties
    var inventoryItems: [Inventory] = []
    var lowStockItems: [Inventory] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Add/Edit Sheet Properties
    var showAddSheet = false
    var editingInventory: Inventory?

    // Form fields for add/edit
    var selectedCompound: Compound?
    var vialCountString = ""
    var vialSizeString = ""
    var lowStockThresholdString = "2"
    var autoDecrementEnabled = true

    // MARK: - Initialization

    init() {
        loadInventory()
    }

    // MARK: - Load Data

    func loadInventory() {
        isLoading = true

        // Fetch all inventory items from compounds that have inventory
        let request: NSFetchRequest<Inventory> = Inventory.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Inventory.lastUpdated, ascending: false)]

        do {
            inventoryItems = try CoreDataManager.shared.viewContext.fetch(request)
            lowStockItems = inventoryItems.filter { $0.isLowStock }
        } catch {
            errorMessage = "Failed to load inventory: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Eligible Compounds

    /// Returns compounds that can have inventory (PEDs and Peptides that are tracked)
    var eligibleCompounds: [Compound] {
        let tracked = CoreDataManager.shared.fetchTrackedCompounds(activeOnly: true)
        return tracked.compactMap { $0.compound }.filter {
            $0.category == .ped || $0.category == .peptide
        }
    }

    /// Returns compounds that don't already have inventory (1:1 relationship)
    var compoundsWithoutInventory: [Compound] {
        return eligibleCompounds.filter { compound in
            compound.inventory == nil
        }
    }

    // MARK: - Form Validation

    var canSaveInventory: Bool {
        guard selectedCompound != nil,
              let vialCount = Int16(vialCountString), vialCount >= 0,
              let vialSize = Double(vialSizeString), vialSize > 0 else {
            return false
        }
        return true
    }

    // MARK: - Add/Edit Operations

    func prepareForAdd() {
        editingInventory = nil
        selectedCompound = compoundsWithoutInventory.first
        vialCountString = "1"
        vialSizeString = ""
        lowStockThresholdString = "2"
        autoDecrementEnabled = true
        showAddSheet = true
    }

    func prepareForEdit(_ inventory: Inventory) {
        editingInventory = inventory
        selectedCompound = inventory.compound
        vialCountString = String(inventory.vialCount)
        vialSizeString = String(format: "%.0f", inventory.vialSizeMg)
        lowStockThresholdString = String(inventory.lowStockThreshold)
        autoDecrementEnabled = inventory.autoDecrement
        showAddSheet = true
    }

    func saveInventory() {
        guard let compound = selectedCompound,
              let vialCount = Int16(vialCountString), vialCount >= 0,
              let vialSize = Double(vialSizeString), vialSize > 0,
              let threshold = Int16(lowStockThresholdString) else {
            errorMessage = "Please fill in all fields correctly"
            return
        }

        if let existing = editingInventory {
            // Update existing
            existing.vialCount = vialCount
            existing.vialSizeMg = vialSize
            existing.lowStockThreshold = threshold
            existing.autoDecrement = autoDecrementEnabled
            existing.lastUpdated = Date()
        } else {
            // Create new
            let inventory = Inventory(
                context: CoreDataManager.shared.viewContext,
                compound: compound,
                vialCount: vialCount,
                vialSizeMg: vialSize,
                lowStockThreshold: threshold
            )
            inventory.autoDecrement = autoDecrementEnabled
        }

        CoreDataManager.shared.saveContext()
        loadInventory()

        // Haptic feedback
        HapticManager.success()

        showAddSheet = false
    }

    // MARK: - Inventory Operations

    func addVials(to inventory: Inventory, count: Int16) {
        inventory.addVials(count)
        CoreDataManager.shared.saveContext()
        loadInventory()

        HapticManager.mediumImpact()
    }

    func startNewVial(for inventory: Inventory) {
        inventory.startNewVial()
        CoreDataManager.shared.saveContext()
        loadInventory()

        HapticManager.mediumImpact()
    }

    func setRemainingAmount(for inventory: Inventory, amount: Double) {
        inventory.setRemainingInCurrentVial(amount)
        CoreDataManager.shared.saveContext()
        loadInventory()
    }

    func toggleAutoDecrement(for inventory: Inventory) {
        inventory.autoDecrement.toggle()
        CoreDataManager.shared.saveContext()
        loadInventory()

        HapticManager.lightImpact()
    }

    func deleteInventory(_ inventory: Inventory) {
        CoreDataManager.shared.viewContext.delete(inventory)
        CoreDataManager.shared.saveContext()
        loadInventory()

        HapticManager.warning()
    }

    // MARK: - Utility

    func remainingDoses(for inventory: Inventory) -> Int {
        guard let tracked = inventory.compound?.trackedCompound else { return 0 }
        return inventory.remainingDoses(atDosage: tracked.dosageAmount)
    }

    func daysRemaining(for inventory: Inventory) -> Int {
        guard let tracked = inventory.compound?.trackedCompound else { return 0 }
        return inventory.daysOfSupplyRemaining(
            atDosage: tracked.dosageAmount,
            scheduleInterval: Int(tracked.scheduleInterval)
        )
    }
}
