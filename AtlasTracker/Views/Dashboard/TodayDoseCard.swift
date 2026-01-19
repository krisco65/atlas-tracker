import SwiftUI

struct TodayDoseCard: View {
    let tracked: TrackedCompound
    let isCompleted: Bool
    let recommendedSite: String?
    let onLogTap: () -> Void
    let onSkipTap: (() -> Void)?

    // MARK: - Urgency Status
    enum UrgencyStatus {
        case notDue      // Green - more than 1 hour away
        case dueSoon     // Yellow - within 1 hour
        case dueNow      // Orange - within 15 minutes
        case overdue     // Red - past due time
        case completed   // Green checkmark

        var color: Color {
            switch self {
            case .notDue: return .statusSuccess
            case .dueSoon: return .statusWarning
            case .dueNow: return .orange
            case .overdue: return .statusError
            case .completed: return .statusSuccess
            }
        }

        var icon: String {
            switch self {
            case .notDue: return "clock"
            case .dueSoon: return "clock.badge.exclamationmark"
            case .dueNow: return "exclamationmark.circle"
            case .overdue: return "exclamationmark.triangle.fill"
            case .completed: return "checkmark.circle.fill"
            }
        }
    }

    init(tracked: TrackedCompound, isCompleted: Bool, recommendedSite: String?, onLogTap: @escaping () -> Void, onSkipTap: (() -> Void)? = nil) {
        self.tracked = tracked
        self.isCompleted = isCompleted
        self.recommendedSite = recommendedSite
        self.onLogTap = onLogTap
        self.onSkipTap = onSkipTap
    }

    // MARK: - Computed Properties
    private var urgencyStatus: UrgencyStatus {
        if isCompleted { return .completed }

        guard let notificationTime = tracked.notificationTime else {
            return .notDue
        }

        let now = Date()
        let calendar = Calendar.current

        // Get today's scheduled time
        var scheduledTime = calendar.date(bySettingHour: calendar.component(.hour, from: notificationTime),
                                          minute: calendar.component(.minute, from: notificationTime),
                                          second: 0,
                                          of: now) ?? notificationTime

        // If time already passed today, it's overdue
        let minutesUntilDue = calendar.dateComponents([.minute], from: now, to: scheduledTime).minute ?? 0

        if minutesUntilDue < -15 {
            return .overdue
        } else if minutesUntilDue < 0 {
            return .dueNow
        } else if minutesUntilDue <= 15 {
            return .dueNow
        } else if minutesUntilDue <= 60 {
            return .dueSoon
        } else {
            return .notDue
        }
    }

    private var timeUntilDueString: String {
        guard !isCompleted, let notificationTime = tracked.notificationTime else {
            return ""
        }

        let now = Date()
        let calendar = Calendar.current

        // Get today's scheduled time
        let scheduledTime = calendar.date(bySettingHour: calendar.component(.hour, from: notificationTime),
                                          minute: calendar.component(.minute, from: notificationTime),
                                          second: 0,
                                          of: now) ?? notificationTime

        let minutesUntilDue = calendar.dateComponents([.minute], from: now, to: scheduledTime).minute ?? 0

        if minutesUntilDue < -60 {
            let hoursOverdue = abs(minutesUntilDue) / 60
            return "\(hoursOverdue)h overdue"
        } else if minutesUntilDue < 0 {
            return "\(abs(minutesUntilDue))m overdue"
        } else if minutesUntilDue == 0 {
            return "Due now"
        } else if minutesUntilDue < 60 {
            return "in \(minutesUntilDue)m"
        } else {
            let hours = minutesUntilDue / 60
            let mins = minutesUntilDue % 60
            if mins == 0 {
                return "in \(hours)h"
            }
            return "in \(hours)h \(mins)m"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Status indicator with urgency color
                Image(systemName: urgencyStatus.icon)
                    .font(.system(size: 16))
                    .foregroundColor(urgencyStatus.color)
                    .frame(width: 24, height: 24)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(tracked.compound?.name ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(isCompleted ? .textSecondary : .textPrimary)
                        .strikethrough(isCompleted)

                    HStack(spacing: 8) {
                        Text(tracked.dosageString)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)

                        if let site = recommendedSite, tracked.compound?.requiresInjection == true {
                            Text("•")
                                .foregroundColor(.textTertiary)
                            Text(site)
                                .font(.caption)
                                .foregroundColor(.accentPrimary)
                        }
                    }
                }

                Spacer()

                // Time until due (or scheduled time)
                VStack(alignment: .trailing, spacing: 2) {
                    if let time = tracked.notificationTime {
                        Text(time.timeString)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }

                    if !isCompleted && !timeUntilDueString.isEmpty {
                        Text(timeUntilDueString)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(urgencyStatus.color)
                    }
                }

                // Action buttons
                if !isCompleted {
                    HStack(spacing: 8) {
                        // Skip button
                        if let skipAction = onSkipTap {
                            Button(action: skipAction) {
                                Text("Skip")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.backgroundTertiary)
                                    .cornerRadius(6)
                            }
                        }

                        // Log button
                        Button(action: onLogTap) {
                            Text("Log")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.accentPrimary)
                                .cornerRadius(6)
                        }
                    }
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.statusSuccess)
                }
            }
            .padding()
        }
        .background(urgencyStatus == .overdue ? Color.statusError.opacity(0.1) : Color.backgroundSecondary)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(urgencyStatus == .overdue ? Color.statusError.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}
