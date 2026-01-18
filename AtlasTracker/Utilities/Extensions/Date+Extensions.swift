import Foundation

// MARK: - Cached Date Formatters

enum DateFormat {
    case time           // "2:30 PM"
    case shortDate      // "Jan 15"
    case mediumDate     // "Jan 15, 2026"
    case fullDate       // "Wednesday, January 15, 2026"
    case compact        // "1/15/26"
    case dateTime       // "Jan 15, 2:30 PM"
    case iso8601        // "2026-01-15T14:30:00Z"

    fileprivate var formatter: DateFormatter {
        DateFormatters.shared.formatter(for: self)
    }
}

private final class DateFormatters {
    static let shared = DateFormatters()

    private var formatters: [DateFormat: DateFormatter] = [:]
    private let lock = NSLock()

    private init() {}

    func formatter(for format: DateFormat) -> DateFormatter {
        lock.lock()
        defer { lock.unlock() }

        if let cached = formatters[format] {
            return cached
        }

        let formatter = DateFormatter()

        switch format {
        case .time:
            formatter.dateFormat = "h:mm a"
        case .shortDate:
            formatter.dateFormat = "MMM d"
        case .mediumDate:
            formatter.dateFormat = "MMM d, yyyy"
        case .fullDate:
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
        case .compact:
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        case .dateTime:
            formatter.dateFormat = "MMM d, h:mm a"
        case .iso8601:
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            formatter.timeZone = TimeZone(identifier: "UTC")
        }

        formatters[format] = formatter
        return formatter
    }
}

extension Date {
    // MARK: - Consistent Formatting

    func format(_ format: DateFormat) -> String {
        format.formatter.string(from: self)
    }

    // MARK: - Start of Day
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    // MARK: - End of Day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    // MARK: - Start of Week
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    // MARK: - Start of Month
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    // MARK: - End of Month
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }

    // MARK: - Days Ago
    func daysAgo(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }

    // MARK: - Days From Now
    func daysFromNow(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    // MARK: - Is Today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }

    // MARK: - Is This Week
    var isThisWeek: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    // MARK: - Is This Month
    var isThisMonth: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    // MARK: - Days Between Dates
    func daysBetween(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self.startOfDay, to: date.startOfDay)
        return abs(components.day ?? 0)
    }

    // MARK: - Weekday
    var weekday: Int {
        return Calendar.current.component(.weekday, from: self) - 1 // 0-indexed (Sunday = 0)
    }

    // MARK: - Relative Date String
    var relativeDateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    // MARK: - Format with Style
    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }

    func formatted(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }

    // MARK: - Time Only String
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }

    // MARK: - Short Date String
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    // MARK: - Full Date String
    var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: self)
    }
}
