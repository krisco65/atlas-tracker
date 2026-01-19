import CoreData

// MARK: - Core Data Model Definition
// This file defines the Core Data model programmatically
// In Xcode, this would be created via the .xcdatamodeld visual editor
// This serves as documentation and can be used for programmatic model creation

/*
 ENTITY: Compound
 ================
 Attributes:
 - id: UUID
 - name: String
 - categoryRaw: String (supplement/ped/peptide/medicine)
 - supportedUnitsRaw: Transformable ([String])
 - defaultUnitRaw: String
 - requiresInjection: Boolean
 - recommendedSitesRaw: Transformable ([String])
 - notes: String (optional)
 - isFavorited: Boolean (default: false)
 - useCount: Integer 64 (default: 0)
 - isCustom: Boolean (default: false)
 - createdAt: Date

 Relationships:
 - trackedCompound: TrackedCompound (optional, to-one, inverse: compound)
 - doseLogs: DoseLog (to-many, inverse: compound)
 - inventory: Inventory (optional, to-one, inverse: compound)
 - weightEntries: WeightEntry (to-many, inverse: compound)


 ENTITY: TrackedCompound
 =======================
 Attributes:
 - id: UUID
 - dosageAmount: Double
 - dosageUnitRaw: String
 - scheduleTypeRaw: String
 - scheduleInterval: Integer 16 (default: 1)
 - scheduleDaysRaw: Transformable ([Int16])
 - notificationEnabled: Boolean (default: true)
 - notificationTime: Date (optional)
 - isActive: Boolean (default: true)
 - startDate: Date
 - lastDoseDate: Date (optional)
 - reconstitutionBAC: Double (default: 0)
 - reconstitutionConcentration: Double (default: 0)

 Relationships:
 - compound: Compound (required, to-one, inverse: trackedCompound)


 ENTITY: DoseLog
 ===============
 Attributes:
 - id: UUID
 - dosageAmount: Double
 - dosageUnitRaw: String
 - timestamp: Date
 - injectionSiteRaw: String (optional)
 - sideEffectsRaw: Transformable ([String]) (optional)
 - notes: String (optional)

 Relationships:
 - compound: Compound (required, to-one, inverse: doseLogs)


 ENTITY: Inventory
 =================
 Attributes:
 - id: UUID
 - vialCount: Integer 16
 - vialSizeMg: Double
 - remainingInCurrentVial: Double
 - lowStockThreshold: Integer 16 (default: 2)
 - autoDecrement: Boolean (default: true)
 - lastUpdated: Date

 Relationships:
 - compound: Compound (required, to-one, inverse: inventory)


 ENTITY: WeightEntry
 ===================
 Attributes:
 - id: UUID
 - weight: Double
 - unitRaw: String (lbs/kg)
 - date: Date
 - notes: String (optional)

 Relationships:
 - compound: Compound (optional, to-one, inverse: weightEntries)


 CONFIGURATIONS
 ==============
 - Default: All entities
 - Model Version: 1
 */

// MARK: - Programmatic Model Creation
class CoreDataModelCreator {

    static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Create entities
        let compoundEntity = createCompoundEntity()
        let trackedCompoundEntity = createTrackedCompoundEntity()
        let doseLogEntity = createDoseLogEntity()
        let inventoryEntity = createInventoryEntity()
        let weightEntryEntity = createWeightEntryEntity()

        // Set up relationships
        setupRelationships(
            compound: compoundEntity,
            trackedCompound: trackedCompoundEntity,
            doseLog: doseLogEntity,
            inventory: inventoryEntity,
            weightEntry: weightEntryEntity
        )

        model.entities = [
            compoundEntity,
            trackedCompoundEntity,
            doseLogEntity,
            inventoryEntity,
            weightEntryEntity
        ]

        return model
    }

    // MARK: - Entity Creation

    private static func createCompoundEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Compound"
        entity.managedObjectClassName = "Compound"

        var properties: [NSAttributeDescription] = []

        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .UUIDAttributeType
        properties.append(id)

        let name = NSAttributeDescription()
        name.name = "name"
        name.attributeType = .stringAttributeType
        properties.append(name)

        let categoryRaw = NSAttributeDescription()
        categoryRaw.name = "categoryRaw"
        categoryRaw.attributeType = .stringAttributeType
        properties.append(categoryRaw)

        let supportedUnitsRaw = NSAttributeDescription()
        supportedUnitsRaw.name = "supportedUnitsRaw"
        supportedUnitsRaw.attributeType = .transformableAttributeType
        supportedUnitsRaw.valueTransformerName = "NSSecureUnarchiveFromDataTransformer"
        properties.append(supportedUnitsRaw)

        let defaultUnitRaw = NSAttributeDescription()
        defaultUnitRaw.name = "defaultUnitRaw"
        defaultUnitRaw.attributeType = .stringAttributeType
        properties.append(defaultUnitRaw)

        let requiresInjection = NSAttributeDescription()
        requiresInjection.name = "requiresInjection"
        requiresInjection.attributeType = .booleanAttributeType
        requiresInjection.defaultValue = false
        properties.append(requiresInjection)

        let recommendedSitesRaw = NSAttributeDescription()
        recommendedSitesRaw.name = "recommendedSitesRaw"
        recommendedSitesRaw.attributeType = .transformableAttributeType
        recommendedSitesRaw.valueTransformerName = "NSSecureUnarchiveFromDataTransformer"
        properties.append(recommendedSitesRaw)

        let notes = NSAttributeDescription()
        notes.name = "notes"
        notes.attributeType = .stringAttributeType
        notes.isOptional = true
        properties.append(notes)

        let isFavorited = NSAttributeDescription()
        isFavorited.name = "isFavorited"
        isFavorited.attributeType = .booleanAttributeType
        isFavorited.defaultValue = false
        properties.append(isFavorited)

        let useCount = NSAttributeDescription()
        useCount.name = "useCount"
        useCount.attributeType = .integer64AttributeType
        useCount.defaultValue = 0
        properties.append(useCount)

        let isCustom = NSAttributeDescription()
        isCustom.name = "isCustom"
        isCustom.attributeType = .booleanAttributeType
        isCustom.defaultValue = false
        properties.append(isCustom)

        let createdAt = NSAttributeDescription()
        createdAt.name = "createdAt"
        createdAt.attributeType = .dateAttributeType
        properties.append(createdAt)

        entity.properties = properties

        // Add indexes AFTER properties are set (Core Data requires properties to exist first)
        entity.indexes = [
            NSFetchIndexDescription(name: "byName", elements: [
                NSFetchIndexElementDescription(property: name, collationType: .binary)
            ]),
            NSFetchIndexDescription(name: "byCategory", elements: [
                NSFetchIndexElementDescription(property: categoryRaw, collationType: .binary)
            ])
        ]

        // Add unique constraint on name to prevent duplicates
        entity.uniquenessConstraints = [[name]]

        return entity
    }

    private static func createTrackedCompoundEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "TrackedCompound"
        entity.managedObjectClassName = "TrackedCompound"

        var properties: [NSAttributeDescription] = []

        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .UUIDAttributeType
        properties.append(id)

        let dosageAmount = NSAttributeDescription()
        dosageAmount.name = "dosageAmount"
        dosageAmount.attributeType = .doubleAttributeType
        properties.append(dosageAmount)

        let dosageUnitRaw = NSAttributeDescription()
        dosageUnitRaw.name = "dosageUnitRaw"
        dosageUnitRaw.attributeType = .stringAttributeType
        properties.append(dosageUnitRaw)

        let scheduleTypeRaw = NSAttributeDescription()
        scheduleTypeRaw.name = "scheduleTypeRaw"
        scheduleTypeRaw.attributeType = .stringAttributeType
        properties.append(scheduleTypeRaw)

        let scheduleInterval = NSAttributeDescription()
        scheduleInterval.name = "scheduleInterval"
        scheduleInterval.attributeType = .integer16AttributeType
        scheduleInterval.defaultValue = 1
        properties.append(scheduleInterval)

        let scheduleDaysRaw = NSAttributeDescription()
        scheduleDaysRaw.name = "scheduleDaysRaw"
        scheduleDaysRaw.attributeType = .transformableAttributeType
        scheduleDaysRaw.valueTransformerName = "NSSecureUnarchiveFromDataTransformer"
        scheduleDaysRaw.isOptional = true
        properties.append(scheduleDaysRaw)

        let notificationEnabled = NSAttributeDescription()
        notificationEnabled.name = "notificationEnabled"
        notificationEnabled.attributeType = .booleanAttributeType
        notificationEnabled.defaultValue = true
        properties.append(notificationEnabled)

        let notificationTime = NSAttributeDescription()
        notificationTime.name = "notificationTime"
        notificationTime.attributeType = .dateAttributeType
        notificationTime.isOptional = true
        properties.append(notificationTime)

        let isActive = NSAttributeDescription()
        isActive.name = "isActive"
        isActive.attributeType = .booleanAttributeType
        isActive.defaultValue = true
        properties.append(isActive)

        let startDate = NSAttributeDescription()
        startDate.name = "startDate"
        startDate.attributeType = .dateAttributeType
        properties.append(startDate)

        let lastDoseDate = NSAttributeDescription()
        lastDoseDate.name = "lastDoseDate"
        lastDoseDate.attributeType = .dateAttributeType
        lastDoseDate.isOptional = true
        properties.append(lastDoseDate)

        let reconstitutionBAC = NSAttributeDescription()
        reconstitutionBAC.name = "reconstitutionBAC"
        reconstitutionBAC.attributeType = .doubleAttributeType
        reconstitutionBAC.defaultValue = 0
        properties.append(reconstitutionBAC)

        let reconstitutionConcentration = NSAttributeDescription()
        reconstitutionConcentration.name = "reconstitutionConcentration"
        reconstitutionConcentration.attributeType = .doubleAttributeType
        reconstitutionConcentration.defaultValue = 0
        properties.append(reconstitutionConcentration)

        entity.properties = properties

        // Add index AFTER properties are set
        entity.indexes = [
            NSFetchIndexDescription(name: "byIsActive", elements: [
                NSFetchIndexElementDescription(property: isActive, collationType: .binary)
            ])
        ]

        return entity
    }

    private static func createDoseLogEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "DoseLog"
        entity.managedObjectClassName = "DoseLog"

        var properties: [NSAttributeDescription] = []

        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .UUIDAttributeType
        properties.append(id)

        let dosageAmount = NSAttributeDescription()
        dosageAmount.name = "dosageAmount"
        dosageAmount.attributeType = .doubleAttributeType
        properties.append(dosageAmount)

        let dosageUnitRaw = NSAttributeDescription()
        dosageUnitRaw.name = "dosageUnitRaw"
        dosageUnitRaw.attributeType = .stringAttributeType
        properties.append(dosageUnitRaw)

        let timestamp = NSAttributeDescription()
        timestamp.name = "timestamp"
        timestamp.attributeType = .dateAttributeType
        properties.append(timestamp)

        let injectionSiteRaw = NSAttributeDescription()
        injectionSiteRaw.name = "injectionSiteRaw"
        injectionSiteRaw.attributeType = .stringAttributeType
        injectionSiteRaw.isOptional = true
        properties.append(injectionSiteRaw)

        let sideEffectsRaw = NSAttributeDescription()
        sideEffectsRaw.name = "sideEffectsRaw"
        sideEffectsRaw.attributeType = .transformableAttributeType
        sideEffectsRaw.valueTransformerName = "NSSecureUnarchiveFromDataTransformer"
        sideEffectsRaw.isOptional = true
        properties.append(sideEffectsRaw)

        let notes = NSAttributeDescription()
        notes.name = "notes"
        notes.attributeType = .stringAttributeType
        notes.isOptional = true
        properties.append(notes)

        entity.properties = properties

        // Add index AFTER properties are set
        entity.indexes = [
            NSFetchIndexDescription(name: "byTimestamp", elements: [
                NSFetchIndexElementDescription(property: timestamp, collationType: .binary)
            ])
        ]

        return entity
    }

    private static func createInventoryEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Inventory"
        entity.managedObjectClassName = "Inventory"

        var properties: [NSAttributeDescription] = []

        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .UUIDAttributeType
        properties.append(id)

        let vialCount = NSAttributeDescription()
        vialCount.name = "vialCount"
        vialCount.attributeType = .integer16AttributeType
        properties.append(vialCount)

        let vialSizeMg = NSAttributeDescription()
        vialSizeMg.name = "vialSizeMg"
        vialSizeMg.attributeType = .doubleAttributeType
        properties.append(vialSizeMg)

        let remainingInCurrentVial = NSAttributeDescription()
        remainingInCurrentVial.name = "remainingInCurrentVial"
        remainingInCurrentVial.attributeType = .doubleAttributeType
        properties.append(remainingInCurrentVial)

        let lowStockThreshold = NSAttributeDescription()
        lowStockThreshold.name = "lowStockThreshold"
        lowStockThreshold.attributeType = .integer16AttributeType
        lowStockThreshold.defaultValue = 2
        properties.append(lowStockThreshold)

        let autoDecrement = NSAttributeDescription()
        autoDecrement.name = "autoDecrement"
        autoDecrement.attributeType = .booleanAttributeType
        autoDecrement.defaultValue = true
        properties.append(autoDecrement)

        let lastUpdated = NSAttributeDescription()
        lastUpdated.name = "lastUpdated"
        lastUpdated.attributeType = .dateAttributeType
        properties.append(lastUpdated)

        entity.properties = properties
        return entity
    }

    private static func createWeightEntryEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "WeightEntry"
        entity.managedObjectClassName = "WeightEntry"

        var properties: [NSAttributeDescription] = []

        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .UUIDAttributeType
        properties.append(id)

        let weight = NSAttributeDescription()
        weight.name = "weight"
        weight.attributeType = .doubleAttributeType
        properties.append(weight)

        let unitRaw = NSAttributeDescription()
        unitRaw.name = "unitRaw"
        unitRaw.attributeType = .stringAttributeType
        properties.append(unitRaw)

        let date = NSAttributeDescription()
        date.name = "date"
        date.attributeType = .dateAttributeType
        properties.append(date)

        let notes = NSAttributeDescription()
        notes.name = "notes"
        notes.attributeType = .stringAttributeType
        notes.isOptional = true
        properties.append(notes)

        entity.properties = properties
        return entity
    }

    // MARK: - Relationship Setup

    private static func setupRelationships(
        compound: NSEntityDescription,
        trackedCompound: NSEntityDescription,
        doseLog: NSEntityDescription,
        inventory: NSEntityDescription,
        weightEntry: NSEntityDescription
    ) {
        // Compound <-> TrackedCompound (1:1)
        let compoundToTracked = NSRelationshipDescription()
        compoundToTracked.name = "trackedCompound"
        compoundToTracked.destinationEntity = trackedCompound
        compoundToTracked.minCount = 0
        compoundToTracked.maxCount = 1
        compoundToTracked.deleteRule = .cascadeDeleteRule

        let trackedToCompound = NSRelationshipDescription()
        trackedToCompound.name = "compound"
        trackedToCompound.destinationEntity = compound
        trackedToCompound.minCount = 1
        trackedToCompound.maxCount = 1
        trackedToCompound.deleteRule = .nullifyDeleteRule

        compoundToTracked.inverseRelationship = trackedToCompound
        trackedToCompound.inverseRelationship = compoundToTracked

        // Compound <-> DoseLog (1:many)
        let compoundToDoseLogs = NSRelationshipDescription()
        compoundToDoseLogs.name = "doseLogs"
        compoundToDoseLogs.destinationEntity = doseLog
        compoundToDoseLogs.minCount = 0
        compoundToDoseLogs.maxCount = 0 // 0 = unlimited (to-many)
        compoundToDoseLogs.deleteRule = .cascadeDeleteRule

        let doseLogToCompound = NSRelationshipDescription()
        doseLogToCompound.name = "compound"
        doseLogToCompound.destinationEntity = compound
        doseLogToCompound.minCount = 1
        doseLogToCompound.maxCount = 1
        doseLogToCompound.deleteRule = .nullifyDeleteRule

        compoundToDoseLogs.inverseRelationship = doseLogToCompound
        doseLogToCompound.inverseRelationship = compoundToDoseLogs

        // Compound <-> Inventory (1:1 - one inventory per compound)
        let compoundToInventory = NSRelationshipDescription()
        compoundToInventory.name = "inventory"
        compoundToInventory.destinationEntity = inventory
        compoundToInventory.minCount = 0
        compoundToInventory.maxCount = 1  // Changed from 0 (many) to 1 (one)
        compoundToInventory.deleteRule = .cascadeDeleteRule

        let inventoryToCompound = NSRelationshipDescription()
        inventoryToCompound.name = "compound"
        inventoryToCompound.destinationEntity = compound
        inventoryToCompound.minCount = 1
        inventoryToCompound.maxCount = 1
        inventoryToCompound.deleteRule = .nullifyDeleteRule

        compoundToInventory.inverseRelationship = inventoryToCompound
        inventoryToCompound.inverseRelationship = compoundToInventory

        // Compound <-> WeightEntry (1:many, optional)
        let compoundToWeight = NSRelationshipDescription()
        compoundToWeight.name = "weightEntries"
        compoundToWeight.destinationEntity = weightEntry
        compoundToWeight.minCount = 0
        compoundToWeight.maxCount = 0
        compoundToWeight.deleteRule = .nullifyDeleteRule
        compoundToWeight.isOptional = true

        let weightToCompound = NSRelationshipDescription()
        weightToCompound.name = "compound"
        weightToCompound.destinationEntity = compound
        weightToCompound.minCount = 0
        weightToCompound.maxCount = 1
        weightToCompound.deleteRule = .nullifyDeleteRule
        weightToCompound.isOptional = true

        compoundToWeight.inverseRelationship = weightToCompound
        weightToCompound.inverseRelationship = compoundToWeight

        // Add relationships to entities
        compound.properties.append(contentsOf: [compoundToTracked, compoundToDoseLogs, compoundToInventory, compoundToWeight])
        trackedCompound.properties.append(trackedToCompound)
        doseLog.properties.append(doseLogToCompound)
        inventory.properties.append(inventoryToCompound)
        weightEntry.properties.append(weightToCompound)
    }
}
