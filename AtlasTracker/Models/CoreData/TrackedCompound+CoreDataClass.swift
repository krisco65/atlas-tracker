import Foundation
import CoreData

@objc(TrackedCompound)
public class TrackedCompound: NSManagedObject {

    // MARK: - Convenience Initializer
    convenience init(context: NSManagedObjectContext,
                     compound: Compound,
                     dosageAmount: Double,
                     dosageUnit: DosageUnit,
                     scheduleType: ScheduleType,
                     scheduleInterval: Int16? = nil,
                     scheduleDays: [Int]? = nil,
                     notificationEnabled: Bool = true,
                     notificationTime: Date? = nil) {

        let entity = NSEntityDescription.entity(forEntityName: "TrackedCompound", in: context)!
        self.init(entity: entity, insertInto: context)

        self.id = UUID()
        self.compound = compound
        self.dosageAmount = dosageAmount
        self.dosageUnitRaw = dosageUnit.rawValue
        self.scheduleTypeRaw = scheduleType.rawValue
        self.scheduleInterval = scheduleInterval ?? 1
        self.scheduleDaysRaw = scheduleDays?.map { Int16($0) }
        self.notificationEnabled = notificationEnabled
        self.notificationTime = notificationTime ?? Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())
        self.isActive = true
        self.startDate = Date()
    }

    // MARK: - Computed Properties
    var dosageUnit: DosageUnit {
        get { DosageUnit(rawValue: dosageUnitRaw ?? "mg") ?? .mg }
        set { dosageUnitRaw = newValue.rawValue }
    }

    var scheduleType: ScheduleType {
        get { ScheduleType(rawValue: scheduleTypeRaw ?? "daily") ?? .daily }
        set { scheduleTypeRaw = newValue.rawValue }
    }

    var scheduleDays: [Int] {
        get { (scheduleDaysRaw ?? []).map { Int($0) } }
        set { scheduleDaysRaw = newValue.map { Int16($0) } }
    }

    // MARK: - Dosage String
    var dosageString: String {
        let amount = dosageAmount.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", dosageAmount)
            : String(format: "%.2f", dosageAmount)
        return "\(amount) \(dosageUnit.displayName)"
    }

    // MARK: - Schedule Description
    var scheduleDescription: String {
        switch scheduleType {
        case .daily:
            return "Daily"
        case .everyXDays:
            if scheduleInterval == 1 {
                return "Daily"
            } else {
                // Handle E3.5D format
                let interval = Double(scheduleInterval)
                if interval == 3 || interval == 4 {
                    return "Every 3.5 days"
                }
                return "Every \(scheduleInterval) days"
            }
        case .specificDays:
            let dayNames = scheduleDays.compactMap { Weekday(rawValue: $0)?.shortName }
            return dayNames.joined(separator: ", ")
        case .asNeeded:
            return "As needed"
        }
    }

    // MARK: - Next Dose Date Calculation
    func nextDoseDate(from referenceDate: Date = Date()) -> Date? {
        guard isActive else { return nil }

        switch scheduleType {
        case .daily:
            return nextDailyDose(from: referenceDate)

        case .everyXDays:
            return nextEveryXDaysDose(from: referenceDate)

        case .specificDays:
            return nextSpecificDayDose(from: referenceDate)

        case .asNeeded:
            return nil
        }
    }

    private func nextDailyDose(from date: Date) -> Date {
        guard let notificationTime = notificationTime else {
            return date.startOfDay
        }

        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: notificationTime)

        var nextDate = calendar.date(bySettingHour: timeComponents.hour ?? 8,
                                     minute: timeComponents.minute ?? 0,
                                     second: 0,
                                     of: date)!

        if nextDate <= date {
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
        }

        return nextDate
    }

    private func nextEveryXDaysDose(from date: Date) -> Date {
        let calendar = Calendar.current
        let interval = Int(scheduleInterval)

        // Get last dose date or start date
        let baseDate = lastDoseDate ?? startDate ?? date

        // Calculate days since last dose
        let daysSinceLast = calendar.dateComponents([.day], from: baseDate.startOfDay, to: date.startOfDay).day ?? 0

        // For E3.5D (interval 3 or 4), alternate between 3 and 4 days
        var daysUntilNext: Int
        if scheduleInterval == 3 {
            // Alternating 3/4 day pattern
            let cyclePosition = (daysSinceLast % 7)
            if cyclePosition < 3 {
                daysUntilNext = 3 - cyclePosition
            } else {
                daysUntilNext = 7 - cyclePosition
            }
        } else {
            // Standard every X days
            daysUntilNext = interval - (daysSinceLast % interval)
            if daysUntilNext == interval && daysSinceLast > 0 {
                daysUntilNext = 0
            }
        }

        var nextDate = calendar.date(byAdding: .day, value: daysUntilNext, to: date.startOfDay)!

        // Apply notification time
        if let notificationTime = notificationTime {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: notificationTime)
            nextDate = calendar.date(bySettingHour: timeComponents.hour ?? 8,
                                     minute: timeComponents.minute ?? 0,
                                     second: 0,
                                     of: nextDate)!
        }

        if nextDate <= date && daysUntilNext == 0 {
            nextDate = calendar.date(byAdding: .day, value: interval, to: nextDate)!
        }

        return nextDate
    }

    private func nextSpecificDayDose(from date: Date) -> Date {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date) - 1 // 0-indexed

        // Sort schedule days
        let sortedDays = scheduleDays.sorted()

        // Find next scheduled day
        var daysUntilNext = 7
        for day in sortedDays {
            let diff = (day - currentWeekday + 7) % 7
            if diff == 0 {
                // Today is a scheduled day, check if time has passed
                if let notificationTime = notificationTime {
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: notificationTime)
                    let scheduledTime = calendar.date(bySettingHour: timeComponents.hour ?? 8,
                                                      minute: timeComponents.minute ?? 0,
                                                      second: 0,
                                                      of: date)!
                    if scheduledTime > date {
                        daysUntilNext = 0
                        break
                    }
                }
            } else if diff < daysUntilNext {
                daysUntilNext = diff
            }
        }

        // If we didn't find a day this week, use first day next week
        if daysUntilNext == 7 {
            if let firstDay = sortedDays.first {
                daysUntilNext = (firstDay - currentWeekday + 7) % 7
                if daysUntilNext == 0 { daysUntilNext = 7 }
            }
        }

        var nextDate = calendar.date(byAdding: .day, value: daysUntilNext, to: date.startOfDay)!

        // Apply notification time
        if let notificationTime = notificationTime {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: notificationTime)
            nextDate = calendar.date(bySettingHour: timeComponents.hour ?? 8,
                                     minute: timeComponents.minute ?? 0,
                                     second: 0,
                                     of: nextDate)!
        }

        return nextDate
    }

    // MARK: - Is Due Today
    var isDueToday: Bool {
        guard let nextDose = nextDoseDate() else { return false }
        return Calendar.current.isDateInToday(nextDose)
    }

    // MARK: - Is Overdue
    var isOverdue: Bool {
        guard let nextDose = nextDoseDate() else { return false }
        return nextDose < Date()
    }

    // MARK: - Schedule Display String
    var scheduleDisplayString: String {
        var result = scheduleDescription
        if let time = notificationTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            result += " at \(formatter.string(from: time))"
        }
        return result
    }
}
