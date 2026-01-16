import Foundation
import CoreData

// MARK: - Preview Data
/// Provides preview data for SwiftUI previews

extension Compound {
    /// A preview compound for SwiftUI previews
    static var preview: Compound {
        let context = CoreDataManager.shared.viewContext
        let compound = Compound(context: context)
        compound.id = UUID()
        compound.name = "Testosterone Cypionate"
        compound.categoryRaw = CompoundCategory.ped.rawValue
        compound.supportedUnitsRaw = ["mg", "ml"]
        compound.defaultUnitRaw = "mg"
        compound.requiresInjection = true
        compound.recommendedSitesRaw = ["glute_left", "glute_right", "delt_left", "delt_right"]
        compound.isFavorited = false
        compound.useCount = 10
        compound.isCustom = false
        compound.createdAt = Date()
        return compound
    }

    /// A preview peptide compound
    static var previewPeptide: Compound {
        let context = CoreDataManager.shared.viewContext
        let compound = Compound(context: context)
        compound.id = UUID()
        compound.name = "Tirzepatide"
        compound.categoryRaw = CompoundCategory.peptide.rawValue
        compound.supportedUnitsRaw = ["mg", "mcg", "ml"]
        compound.defaultUnitRaw = "mg"
        compound.requiresInjection = true
        compound.recommendedSitesRaw = ["belly_upper_left", "belly_upper_right", "belly_lower_left", "belly_lower_right"]
        compound.isFavorited = true
        compound.useCount = 5
        compound.isCustom = false
        compound.createdAt = Date()
        return compound
    }

    /// A preview supplement compound (non-injectable)
    static var previewSupplement: Compound {
        let context = CoreDataManager.shared.viewContext
        let compound = Compound(context: context)
        compound.id = UUID()
        compound.name = "Creatine Monohydrate"
        compound.categoryRaw = CompoundCategory.supplement.rawValue
        compound.supportedUnitsRaw = ["g", "mg"]
        compound.defaultUnitRaw = "g"
        compound.requiresInjection = false
        compound.isFavorited = false
        compound.useCount = 20
        compound.isCustom = false
        compound.createdAt = Date()
        return compound
    }
}

extension TrackedCompound {
    /// A preview tracked compound
    static var preview: TrackedCompound {
        let context = CoreDataManager.shared.viewContext
        let tracked = TrackedCompound(context: context)
        tracked.id = UUID()
        tracked.compound = Compound.preview
        tracked.dosageAmount = 200
        tracked.dosageUnitRaw = "mg"
        tracked.scheduleTypeRaw = ScheduleType.everyXDays.rawValue
        tracked.scheduleInterval = 3
        tracked.notificationEnabled = true
        tracked.notificationTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())
        tracked.isActive = true
        tracked.startDate = Date().daysAgo(30)
        tracked.lastDoseDate = Date().daysAgo(3)
        return tracked
    }
}

extension DoseLog {
    /// A preview dose log
    static var preview: DoseLog {
        let context = CoreDataManager.shared.viewContext
        let log = DoseLog(context: context)
        log.id = UUID()
        log.compound = Compound.preview
        log.dosageAmount = 200
        log.dosageUnitRaw = "mg"
        log.timestamp = Date().daysAgo(1)
        log.injectionSiteRaw = "glute_left"
        log.notes = "Felt good"
        return log
    }
}

extension Inventory {
    /// A preview inventory item
    static var preview: Inventory {
        let context = CoreDataManager.shared.viewContext
        let inventory = Inventory(context: context)
        inventory.id = UUID()
        inventory.compound = Compound.preview
        inventory.vialCount = 3
        inventory.vialSizeMg = 250
        inventory.remainingInCurrentVial = 200
        inventory.lowStockThreshold = 2
        inventory.lastUpdated = Date()
        return inventory
    }
}
