import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}
