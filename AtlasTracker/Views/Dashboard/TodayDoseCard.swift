import SwiftUI

struct TodayDoseCard: View {
    let tracked: TrackedCompound
    let isCompleted: Bool
    let recommendedSite: String?
    let onLogTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(isCompleted ? Color.statusSuccess : Color.accentPrimary)
                .frame(width: 12, height: 12)

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

            // Time
            if let time = tracked.notificationTime {
                Text(time.timeString)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }

            // Log button
            if !isCompleted {
                Button(action: onLogTap) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentPrimary)
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.statusSuccess)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}
