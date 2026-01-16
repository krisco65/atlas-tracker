import SwiftUI

struct CompoundListRow: View {
    let compound: Compound
    var showTrackingStatus: Bool = true
    var onFavoriteTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Category indicator
            Circle()
                .fill(compound.category.color)
                .frame(width: 8, height: 8)

            // Compound info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(compound.name ?? "Unknown")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)

                    if compound.isCustom {
                        Text("Custom")
                            .font(.caption2)
                            .foregroundColor(.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.backgroundTertiary)
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 8) {
                    CategoryBadge(category: compound.category)

                    if compound.requiresInjection {
                        Image(systemName: "syringe")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    if showTrackingStatus && compound.isTracked {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                            Text("Tracking")
                                .font(.caption)
                        }
                        .foregroundColor(.statusSuccess)
                    }
                }
            }

            Spacer()

            // Favorite button
            if let onFavoriteTap = onFavoriteTap {
                Button(action: onFavoriteTap) {
                    Image(systemName: compound.isFavorited ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundColor(compound.isFavorited ? .yellow : .textTertiary)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: compound.isFavorited ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundColor(compound.isFavorited ? .yellow : .textTertiary)
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

struct CompoundListRowCompact: View {
    let compound: Compound

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(compound.category.color)
                .frame(width: 6, height: 6)

            Text(compound.name ?? "Unknown")
                .font(.subheadline)
                .foregroundColor(.textPrimary)

            Spacer()

            if compound.isFavorited {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
        .padding(.vertical, 8)
    }
}
