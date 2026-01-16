import Foundation
import CoreData

@objc(Inventory)
public class Inventory: NSManagedObject {

    // MARK: - Convenience Initializer
    convenience init(context: NSManagedObjectContext,
                     compound: Compound,
                     vialCount: Int16,
                     vialSizeMg: Double,
                     lowStockThreshold: Int16 = AppConstants.Inventory.defaultLowStockThreshold) {

        let entity = NSEntityDescription.entity(forEntityName: "Inventory", in: context)!
        self.init(entity: entity, insertInto: context)

        self.id = UUID()
        self.compound = compound
        self.vialCount = vialCount
        self.vialSizeMg = vialSizeMg
        self.remainingInCurrentVial = vialSizeMg // Start with full vial
        self.lowStockThreshold = lowStockThreshold
        self.autoDecrement = true
        self.lastUpdated = Date()
    }

    // MARK: - Computed Properties

    /// Total mg remaining across all vials
    var totalRemainingMg: Double {
        let fullVials = max(0, vialCount - 1) // Exclude current vial being used
        let fullVialsTotal = Double(fullVials) * vialSizeMg
        return fullVialsTotal + (remainingInCurrentVial > 0 ? remainingInCurrentVial : 0)
    }

    /// Check if stock is low
    var isLowStock: Bool {
        return vialCount <= lowStockThreshold
    }

    /// Calculate remaining doses based on compound's tracked dosage
    func remainingDoses(atDosage dosageAmount: Double) -> Int {
        guard dosageAmount > 0 else { return 0 }
        return Int(totalRemainingMg / dosageAmount)
    }

    /// Calculate days of supply remaining
    func daysOfSupplyRemaining(atDosage dosageAmount: Double, scheduleInterval: Int) -> Int {
        let doses = remainingDoses(atDosage: dosageAmount)
        return doses * scheduleInterval
    }

    // MARK: - Inventory Operations

    /// Decrement inventory when a dose is logged
    /// Returns true if successful, false if insufficient stock
    @discardableResult
    func decrementByDose(_ dosageAmount: Double) -> Bool {
        guard autoDecrement else { return true }

        if remainingInCurrentVial >= dosageAmount {
            // Have enough in current vial
            remainingInCurrentVial -= dosageAmount
            lastUpdated = Date()
            return true
        } else if vialCount > 1 {
            // Need to open new vial
            let remainingNeeded = dosageAmount - remainingInCurrentVial
            vialCount -= 1
            remainingInCurrentVial = vialSizeMg - remainingNeeded
            lastUpdated = Date()
            return true
        } else if remainingInCurrentVial > 0 {
            // Use whatever is left
            remainingInCurrentVial = 0
            lastUpdated = Date()
            return true
        }

        return false // Insufficient stock
    }

    /// Add vials to inventory
    func addVials(_ count: Int16) {
        vialCount += count
        lastUpdated = Date()
    }

    /// Start a new vial (discard remaining in current)
    func startNewVial() {
        if vialCount > 0 {
            remainingInCurrentVial = vialSizeMg
            lastUpdated = Date()
        }
    }

    /// Manually set remaining amount in current vial
    func setRemainingInCurrentVial(_ amount: Double) {
        remainingInCurrentVial = min(amount, vialSizeMg)
        lastUpdated = Date()
    }

    // MARK: - Display Strings

    var stockStatusString: String {
        if vialCount == 0 && remainingInCurrentVial <= 0 {
            return "Out of stock"
        } else if isLowStock {
            return "Low stock (\(vialCount) vial\(vialCount == 1 ? "" : "s"))"
        } else {
            return "\(vialCount) vial\(vialCount == 1 ? "" : "s")"
        }
    }

    var remainingString: String {
        let totalMg = totalRemainingMg
        if totalMg >= 1000 {
            return String(format: "%.1fg remaining", totalMg / 1000)
        } else {
            return String(format: "%.0fmg remaining", totalMg)
        }
    }
}
