import SwiftUI

// MARK: - Body Diagram View
/// Container view that displays the appropriate body diagram based on injection type
struct BodyDiagramView: View {
    let injectionType: InjectionType
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?

    enum InjectionType {
        case intramuscular  // PEDs - larger muscle groups
        case subcutaneous   // Peptides - fatty tissue areas
    }

    var body: some View {
        VStack(spacing: 16) {
            // Legend
            HStack(spacing: 20) {
                LegendItem(color: .accentPrimary, label: "Selected")
                LegendItem(color: .statusWarning, label: "Last Used")
                LegendItem(color: .statusSuccess, label: "Recommended")
            }
            .font(.caption)

            // Body Diagram
            switch injectionType {
            case .intramuscular:
                PEDBodyDiagramView(
                    selectedSite: $selectedSite,
                    lastUsedSite: lastUsedSite,
                    recommendedSite: recommendedSite
                )
            case .subcutaneous:
                PeptideBodyDiagramView(
                    selectedSite: $selectedSite,
                    lastUsedSite: lastUsedSite,
                    recommendedSite: recommendedSite
                )
            }
        }
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Site Button Style
struct InjectionSiteButtonStyle: ViewModifier {
    let isSelected: Bool
    let isLastUsed: Bool
    let isRecommended: Bool

    var backgroundColor: Color {
        if isSelected {
            return .accentPrimary
        } else if isLastUsed {
            return .statusWarning.opacity(0.3)
        } else if isRecommended {
            return .statusSuccess.opacity(0.3)
        }
        return .backgroundTertiary
    }

    var borderColor: Color {
        if isSelected {
            return .accentPrimary
        } else if isRecommended {
            return .statusSuccess
        } else if isLastUsed {
            return .statusWarning
        }
        return .clear
    }

    var textColor: Color {
        if isSelected {
            return .white
        }
        return .textPrimary
    }

    func body(content: Content) -> some View {
        content
            .foregroundColor(textColor)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isRecommended || isLastUsed ? 2 : 0)
            )
            .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 40) {
        BodyDiagramView(
            injectionType: .intramuscular,
            selectedSite: .constant("glute_left"),
            lastUsedSite: "delt_right",
            recommendedSite: "glute_right"
        )

        BodyDiagramView(
            injectionType: .subcutaneous,
            selectedSite: .constant("belly_upper_left"),
            lastUsedSite: "belly_lower_right",
            recommendedSite: "love_handle_left"
        )
    }
    .padding()
    .background(Color.backgroundPrimary)
    .preferredColorScheme(.dark)
}
