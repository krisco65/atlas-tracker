import XCTest
@testable import AtlasTracker

final class DateExtensionsTests: XCTestCase {

    var calendar: Calendar!

    override func setUpWithError() throws {
        calendar = Calendar.current
    }

    override func tearDownWithError() throws {
        calendar = nil
    }

    // MARK: - Start of Day

    func testStartOfDay_ReturnsCorrectTime() {
        let date = Date()
        let startOfDay = date.startOfDay

        let components = calendar.dateComponents([.hour, .minute, .second], from: startOfDay)

        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    // MARK: - End of Day

    func testEndOfDay_ReturnsCorrectTime() {
        let date = Date()
        let endOfDay = date.endOfDay

        let components = calendar.dateComponents([.hour, .minute, .second], from: endOfDay)

        XCTAssertEqual(components.hour, 23)
        XCTAssertEqual(components.minute, 59)
        XCTAssertEqual(components.second, 59)
    }

    // MARK: - Start of Week

    func testStartOfWeek_ReturnsFirstDayOfWeek() {
        let date = Date()
        let startOfWeek = date.startOfWeek

        let weekday = calendar.component(.weekday, from: startOfWeek)
        XCTAssertEqual(weekday, calendar.firstWeekday)
    }

    // MARK: - Start of Month

    func testStartOfMonth_ReturnsFirstDayOfMonth() {
        let date = Date()
        let startOfMonth = date.startOfMonth

        let day = calendar.component(.day, from: startOfMonth)
        XCTAssertEqual(day, 1)
    }

    // MARK: - End of Month

    func testEndOfMonth_ReturnsLastDayOfMonth() {
        let date = Date()
        let endOfMonth = date.endOfMonth

        // Next day should be in the next month
        let nextDay = calendar.date(byAdding: .day, value: 1, to: endOfMonth)!
        let endMonth = calendar.component(.month, from: endOfMonth)
        let nextMonth = calendar.component(.month, from: nextDay)

        XCTAssertNotEqual(endMonth, nextMonth, "End of month should be last day")
    }

    // MARK: - Days Ago

    func testDaysAgo_ReturnsCorrectDate() {
        let now = Date()
        let fiveDaysAgo = now.daysAgo(5)

        let difference = calendar.dateComponents([.day], from: fiveDaysAgo, to: now)
        XCTAssertEqual(difference.day, 5)
    }

    func testDaysAgo_WithZero_ReturnsSameDay() {
        let now = Date()
        let zeroDaysAgo = now.daysAgo(0)

        XCTAssertTrue(calendar.isDate(zeroDaysAgo, inSameDayAs: now))
    }

    // MARK: - Days From Now

    func testDaysFromNow_ReturnsCorrectDate() {
        let now = Date()
        let fiveDaysFromNow = now.daysFromNow(5)

        let difference = calendar.dateComponents([.day], from: now, to: fiveDaysFromNow)
        XCTAssertEqual(difference.day, 5)
    }

    // MARK: - Days Between

    func testDaysBetween_ReturnsCorrectCount() {
        let date1 = Date()
        let date2 = calendar.date(byAdding: .day, value: 10, to: date1)!

        let daysBetween = date1.daysBetween(date2)
        XCTAssertEqual(daysBetween, 10)
    }

    func testDaysBetween_WithNegative_ReturnsPositive() {
        let date1 = Date()
        let date2 = calendar.date(byAdding: .day, value: -10, to: date1)!

        let daysBetween = date1.daysBetween(date2)
        XCTAssertEqual(daysBetween, 10)
    }

    // MARK: - Weekday

    func testWeekday_ReturnsValidWeekday() {
        let date = Date()
        let weekday = date.weekday

        XCTAssertGreaterThanOrEqual(weekday, 1)
        XCTAssertLessThanOrEqual(weekday, 7)
    }

    // MARK: - Is Today

    func testIsToday_WithToday_ReturnsTrue() {
        let now = Date()
        XCTAssertTrue(now.isToday)
    }

    func testIsToday_WithYesterday_ReturnsFalse() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertFalse(yesterday.isToday)
    }

    // MARK: - Is Tomorrow

    func testIsTomorrow_WithTomorrow_ReturnsTrue() {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertTrue(tomorrow.isTomorrow)
    }

    func testIsTomorrow_WithToday_ReturnsFalse() {
        let now = Date()
        XCTAssertFalse(now.isTomorrow)
    }

    // MARK: - Is Yesterday

    func testIsYesterday_WithYesterday_ReturnsTrue() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertTrue(yesterday.isYesterday)
    }

    // MARK: - Is This Week

    func testIsThisWeek_WithDateInThisWeek_ReturnsTrue() {
        let now = Date()
        XCTAssertTrue(now.isThisWeek)
    }

    // MARK: - Relative Date String

    func testRelativeDateString_Today_ReturnsToday() {
        let now = Date()
        let relativeString = now.relativeDateString

        XCTAssertTrue(relativeString.lowercased().contains("today") ||
                      relativeString.contains("hour") ||
                      relativeString.contains("minute") ||
                      relativeString.contains("second") ||
                      relativeString.contains("just now"),
                      "Should contain relative time indicator")
    }

    func testRelativeDateString_Yesterday_ReturnsYesterday() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let relativeString = yesterday.relativeDateString

        XCTAssertTrue(relativeString.lowercased().contains("yesterday") ||
                      relativeString.contains("day"),
                      "Should contain yesterday indicator")
    }

    // MARK: - Formatted Date String

    func testFormattedDateString_ReturnsNonEmpty() {
        let date = Date()
        let formatted = date.formattedDateString

        XCTAssertFalse(formatted.isEmpty, "Formatted date should not be empty")
    }

    // MARK: - Formatted Time String

    func testFormattedTimeString_ReturnsNonEmpty() {
        let date = Date()
        let formatted = date.formattedTimeString

        XCTAssertFalse(formatted.isEmpty, "Formatted time should not be empty")
    }
}
