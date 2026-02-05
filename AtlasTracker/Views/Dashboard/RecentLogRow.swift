import SwiftUI

struct RecentLogRow: View {
    let log: DoseLog

    var body: some View {
        HStack(alignment: .top) {
            Circle()
                .fill(log.compound?.category.color ?? .gray)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 3) {
                // Compound name
                Text(log.compound?.name ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)

                // Dosage
                Text(log.dosageString)
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                // Injection site (only show if present)
                if let site = log.injectionSiteDisplayName {
                    Text(site)
                        .font(.caption)
                        .foregroundColor(.accentPrimary)
                }

                // Date
                Text(log.relativeDateString)
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    VStack {
        // Preview with injection site
        RecentLogRow(log: DoseLog.preview)

        Divider()

        // Would show without injection site for oral compounds
        RecentLogRow(log: DoseLog.preview)
    }
    .padding()
    .background(Color.backgroundSecondary)
    .preferredColorScheme(.dark)
}
