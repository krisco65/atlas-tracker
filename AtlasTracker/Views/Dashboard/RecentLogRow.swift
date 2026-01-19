import SwiftUI

struct RecentLogRow: View {
    let log: DoseLog

    var body: some View {
        HStack {
            Circle()
                .fill(log.compound?.category.color ?? .gray)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(log.compound?.name ?? "Unknown")
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                Text(log.dosageString)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Text(log.relativeDateString)
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .padding(.vertical, 4)
    }
}
