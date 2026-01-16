import SwiftUI

struct CategoryBadge: View {
    let category: CompoundCategory

    var body: some View {
        Text(category.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(category.color)
            .cornerRadius(4)
    }
}

struct CategoryBadgeLarge: View {
    let category: CompoundCategory

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption)
            Text(category.displayName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(category.color)
        .cornerRadius(6)
    }
}

struct CategoryFilterChip: View {
    let category: CompoundCategory?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.caption)
                }
                Text(category?.displayName ?? "All")
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : .textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? (category?.color ?? Color.accentPrimary) : Color.backgroundTertiary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack {
            CategoryBadge(category: .supplement)
            CategoryBadge(category: .ped)
            CategoryBadge(category: .peptide)
            CategoryBadge(category: .medicine)
        }

        HStack {
            CategoryBadgeLarge(category: .supplement)
            CategoryBadgeLarge(category: .ped)
        }

        HStack {
            CategoryFilterChip(category: nil, isSelected: true, action: {})
            CategoryFilterChip(category: .supplement, isSelected: false, action: {})
            CategoryFilterChip(category: .ped, isSelected: false, action: {})
        }
    }
    .padding()
    .background(Color.backgroundPrimary)
}
