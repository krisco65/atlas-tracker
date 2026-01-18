import XCTest
import CoreData
@testable import AtlasTracker

final class InventoryTests: XCTestCase {

    var context: NSManagedObjectContext!
    var compound: Compound!
    var inventory: Inventory!

    override func setUpWithError() throws {
        context = CoreDataManager.shared.viewContext

        // Get a test compound
        let compounds = CoreDataManager.shared.fetchAllCompounds()
        guard let testCompound = compounds.first else {
            XCTFail("Need at least one compound for testing")
            return
        }

        compound = testCompound
    }

    override func tearDownWithError() throws {
        // Cleanup inventory if created
        if let inv = inventory {
            context.delete(inv)
            try? context.save()
        }
        inventory = nil
        compound = nil
        context = nil
    }

    // MARK: - Creation Tests

    func testSetInventory_CreatesInventory() {
        inventory = CoreDataManager.shared.setInventory(
            for: compound,
            vialCount: 5,
            vialSizeMg: 10.0,
            lowStockThreshold: 2
        )

        XCTAssertNotNil(inventory)
        XCTAssertEqual(inventory.vialCount, 5)
        XCTAssertEqual(inventory.vialSizeMg, 10.0)
        XCTAssertEqual(inventory.lowStockThreshold, 2)
    }

    func testSetInventory_UpdatesExisting() {
        inventory = CoreDataManager.shared.setInventory(
            for: compound,
            vialCount: 5,
            vialSizeMg: 10.0
        )

        // Update with new values
        let updated = CoreDataManager.shared.setInventory(
            for: compound,
            vialCount: 10,
            vialSizeMg: 15.0
        )

        XCTAssertEqual(inventory.id, updated.id, "Should update existing inventory")
        XCTAssertEqual(inventory.vialCount, 10)
        XCTAssertEqual(inventory.vialSizeMg, 15.0)
    }

    // MARK: - Total Remaining Tests

    func testTotalRemainingMg_WithFullVials() {
        inventory = CoreDataManager.shared.setInventory(
            for: compound,
            vialCount: 3,
            vialSizeMg: 10.0
        )

        // Reset to full vials (no partial)
        inventory.remainingInCurrentVial = 10.0

        // 3 vials × 10mg + current vial at full
        let total = inventory.totalRemainingMg
        XCTAssertEqual(total, 40.0, accuracy: 0.1, "Should be 4 × 10mg = 40mg")
    }

    func testTotalRemainingMg_WithPartialVial() {
        inventory = CoreDataManager.shared.setInventory(
            for: compound,
            vialCount: 2,
            vialSizeMg: 10.0
        )

        inventory.remainingInCurrentVial = 3.0  // Only 3mg left in current vial

        // 2 full vials (20mg) + 3mg in current = 23mg
        let total = inventory.totalRemainingMg
        XCTAssertEqual(total, 23.0, accuracy: 0.1)
    }

    // MARK: - Low Stock Tests

    func testIsLowStock_WhenBelowThreshold_ReturnsTrue() {
        inventory = CoreDataManager.shared.setInventory(
            for: compound,
            vialCount: 1,
            vialSizeMg: 10.0,
            lowStockThreshold: 2
        )

        XCTAssertTrue(inventory.isLowStock, "1 vial < 2 threshold = low stock")
    }

    func testIsLowStock_WhenAboveThreshold_ReturnsFalse() {
        inventory = CoreDataManager.shared.setInventory(
            for: compound,
            vialCount: 5,
            vialSizeMg: 10.0,
            lowStockThreshold: 2
        )

        XCTAssertFalse(inventory.isLowStock, "5 vials > 2 threshold = not low stock")
    }

    func testIsLowStock_WhenAtThreshold_ReturnsTrue() {
        inventory = CoreDataManager.shared.setInventory(
            for: compound,
            vialCount: 2,
            vialSizeMg: 10.0,
            lowStockThreshold: 2
        )

        XCTAssertTrue(inventory.isLowStock, "2 vials <= 2 threshold = low stock")
    }

    // MARK: - Decrement By Dose Tests

    func testDecrementByDose_ReducesRemaining() {
        inventory = CoreDataManager.shared.setInventory(
            for: compound,
            vialCount: 1,
            vialSizeMg: 10.0
        )

        inventory.remainingInCurrentVial = 10.0  // Full vial
        inventory.decrementByDose(2.0)

        XCTAssertEqual(inventory.remainingInCurrentVial, 8.0, accuracy: 0.01)
    }

    func testDecrementByDose_WhenExceedsVial_StartsNewVial() {
        inventory = CoreDataManager.shared.setInventory(
            for: compound,
            vialCount: 2,
            vialSizeMg: 10.0
        )

        inventory.remainingInCurrentVial = 3.0  // Almost empty

        // Dose larger than remaining
        inventory.decrementByDose(5.0)

        // Should have started a new vial and deducted the remainder
        XCTAssertLessThan(inventory.vialCount, 2, "Should have used a vial")
    }

    // MARK: - Add Vials Tests

    func testAddVials_IncreasesCount() {
        inventory = CoreDataManager.shared.setInventory(
            for: compound,
            vialCount: 3,
            vialSizeMg: 10.0
        )

        inventory.addVials(5)

        XCTAssertEqual(inventory.vialCount, 8)
    }

    // MARK: - Start New Vial Tests

    func testStartNewVial_DecreasesVialCount() {
        inventory = CoreDataManager.shared.setInventory(
            for: compound,
            vialCount: 5,
            vialSizeMg: 10.0
        )

        inventory.startNewVial()

        XCTAssertEqual(inventory.vialCount, 4)
        XCTAssertEqual(inventory.remainingInCurrentVial, 10.0)
    }

    func testStartNewVial_WhenNoVials_DoesNotGoNegative() {
        inventory = CoreDataManager.shared.setInventory(
            for: compound,
            vialCount: 0,
            vialSizeMg: 10.0
        )

        inventory.startNewVial()

        XCTAssertGreaterThanOrEqual(inventory.vialCount, 0)
    }

    // MARK: - Remaining Doses Tests

    func testRemainingDoses_CalculatesCorrectly() {
        inventory = CoreDataManager.shared.setInventory(
            for: compound,
            vialCount: 2,
            vialSizeMg: 10.0
        )

        inventory.remainingInCurrentVial = 5.0  // 5mg left in current

        // Total: 25mg, dose: 1mg each = 25 doses
        let doses = inventory.remainingDoses(at: 1.0)
        XCTAssertEqual(doses, 25, "25mg / 1mg = 25 doses")
    }

    func testRemainingDoses_WithZeroDose_ReturnsZero() {
        inventory = CoreDataManager.shared.setInventory(
            for: compound,
            vialCount: 2,
            vialSizeMg: 10.0
        )

        let doses = inventory.remainingDoses(at: 0)
        XCTAssertEqual(doses, 0)
    }

    // MARK: - Days of Supply Tests

    func testDaysOfSupplyRemaining_Daily() {
        inventory = CoreDataManager.shared.setInventory(
            for: compound,
            vialCount: 1,
            vialSizeMg: 10.0
        )

        inventory.remainingInCurrentVial = 10.0  // Full vial

        // 20mg total, 1mg/day = 20 days
        let days = inventory.daysOfSupplyRemaining(dosePerDay: 1.0)
        XCTAssertEqual(days, 20)
    }

    func testDaysOfSupplyRemaining_WithLargeDose() {
        inventory = CoreDataManager.shared.setInventory(
            for: compound,
            vialCount: 0,
            vialSizeMg: 10.0
        )

        inventory.remainingInCurrentVial = 5.0  // 5mg remaining

        // 5mg total, 2.5mg/day = 2 days
        let days = inventory.daysOfSupplyRemaining(dosePerDay: 2.5)
        XCTAssertEqual(days, 2)
    }
}
