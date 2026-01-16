import SwiftUI

// MARK: - Visual Body Silhouette
/// Clean, modern regional injection site picker
/// Uses card-based layout instead of body drawing for professional appearance
struct VisualBodySilhouette: View {
    let injectionType: BodyDiagramView.InjectionType
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?

    var body: some View {
        VStack(spacing: 16) {
            // Legend
            HStack(spacing: 16) {
                LegendIndicator(color: .accentPrimary, label: "Selected")
                LegendIndicator(color: .statusSuccess, label: "Recommended")
                LegendIndicator(color: .statusWarning, label: "Last Used")
            }
            .font(.caption2)
            .padding(.horizontal)

            // Regional site picker
            if injectionType == .intramuscular {
                PEDSitesPicker(
                    selectedSite: $selectedSite,
                    lastUsedSite: lastUsedSite,
                    recommendedSite: recommendedSite
                )
            } else {
                PeptideSitesPicker(
                    selectedSite: $selectedSite,
                    lastUsedSite: lastUsedSite,
                    recommendedSite: recommendedSite
                )
            }

            // Selected site confirmation
            if let selected = selectedSite {
                let displayName = getDisplayName(for: selected)
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentPrimary)
                    Text(displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.accentPrimary.opacity(0.15))
                .cornerRadius(20)
            }
        }
    }

    private func getDisplayName(for site: String) -> String {
        if injectionType == .intramuscular {
            return PEDInjectionSite(rawValue: site)?.displayName ?? site
        } else {
            return PeptideInjectionSite(rawValue: site)?.displayName ?? site
        }
    }
}

// MARK: - PED Sites Picker (Intramuscular)
struct PEDSitesPicker: View {
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?

    var body: some View {
        VStack(spacing: 12) {
            // Shoulders (Delts)
            RegionCard(
                title: "Shoulders",
                icon: "figure.arms.open",
                sites: [
                    (.deltLeft, "Left Deltoid"),
                    (.deltRight, "Right Deltoid")
                ],
                selectedSite: $selectedSite,
                lastUsedSite: lastUsedSite,
                recommendedSite: recommendedSite
            )

            // Glutes
            RegionCard(
                title: "Glutes",
                icon: "figure.stand",
                sites: [
                    (.gluteLeft, "Left Glute"),
                    (.gluteRight, "Right Glute")
                ],
                selectedSite: $selectedSite,
                lastUsedSite: lastUsedSite,
                recommendedSite: recommendedSite
            )

            // Ventrogluteal
            RegionCard(
                title: "Ventrogluteal",
                icon: "figure.walk",
                sites: [
                    (.vgLeft, "Left VG"),
                    (.vgRight, "Right VG")
                ],
                selectedSite: $selectedSite,
                lastUsedSite: lastUsedSite,
                recommendedSite: recommendedSite
            )

            // Quads
            RegionCard(
                title: "Quadriceps",
                icon: "figure.run",
                sites: [
                    (.quadLeft, "Left Quad"),
                    (.quadRight, "Right Quad")
                ],
                selectedSite: $selectedSite,
                lastUsedSite: lastUsedSite,
                recommendedSite: recommendedSite
            )
        }
    }
}

// MARK: - Peptide Sites Picker (Subcutaneous)
struct PeptideSitesPicker: View {
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?

    var body: some View {
        VStack(spacing: 12) {
            // Abdomen - Left of Navel
            RegionCardPeptide(
                title: "Left Abdomen",
                icon: "square.lefthalf.filled",
                sites: [
                    (.leftBellyUpper, "Upper"),
                    (.leftBellyLower, "Lower")
                ],
                selectedSite: $selectedSite,
                lastUsedSite: lastUsedSite,
                recommendedSite: recommendedSite
            )

            // Abdomen - Right of Navel
            RegionCardPeptide(
                title: "Right Abdomen",
                icon: "square.righthalf.filled",
                sites: [
                    (.rightBellyUpper, "Upper"),
                    (.rightBellyLower, "Lower")
                ],
                selectedSite: $selectedSite,
                lastUsedSite: lastUsedSite,
                recommendedSite: recommendedSite
            )

            // Love Handles
            HStack(spacing: 12) {
                RegionCardPeptide(
                    title: "Left Side",
                    icon: "arrow.left.square",
                    sites: [
                        (.leftLoveHandleUpper, "Upper"),
                        (.leftLoveHandleLower, "Lower")
                    ],
                    selectedSite: $selectedSite,
                    lastUsedSite: lastUsedSite,
                    recommendedSite: recommendedSite,
                    compact: true
                )

                RegionCardPeptide(
                    title: "Right Side",
                    icon: "arrow.right.square",
                    sites: [
                        (.rightLoveHandleUpper, "Upper"),
                        (.rightLoveHandleLower, "Lower")
                    ],
                    selectedSite: $selectedSite,
                    lastUsedSite: lastUsedSite,
                    recommendedSite: recommendedSite,
                    compact: true
                )
            }

            // Glutes (SubQ)
            HStack(spacing: 12) {
                RegionCardPeptide(
                    title: "Left Glute",
                    icon: "circle.lefthalf.filled",
                    sites: [
                        (.gluteLeftUpper, "Upper"),
                        (.gluteLeftLower, "Lower")
                    ],
                    selectedSite: $selectedSite,
                    lastUsedSite: lastUsedSite,
                    recommendedSite: recommendedSite,
                    compact: true
                )

                RegionCardPeptide(
                    title: "Right Glute",
                    icon: "circle.righthalf.filled",
                    sites: [
                        (.gluteRightUpper, "Upper"),
                        (.gluteRightLower, "Lower")
                    ],
                    selectedSite: $selectedSite,
                    lastUsedSite: lastUsedSite,
                    recommendedSite: recommendedSite,
                    compact: true
                )
            }

            // Thighs
            RegionCardPeptide(
                title: "Thighs",
                icon: "figure.stand",
                sites: [
                    (.thighLeft, "Left Thigh"),
                    (.thighRight, "Right Thigh")
                ],
                selectedSite: $selectedSite,
                lastUsedSite: lastUsedSite,
                recommendedSite: recommendedSite
            )
        }
    }
}

// MARK: - Region Card (PED)
struct RegionCard: View {
    let title: String
    let icon: String
    let sites: [(PEDInjectionSite, String)]
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(.accentPrimary)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                Spacer()
            }

            // Site buttons
            HStack(spacing: 10) {
                ForEach(sites, id: \.0) { site, label in
                    SiteButton(
                        label: label,
                        isSelected: selectedSite == site.rawValue,
                        isLastUsed: lastUsedSite == site.rawValue,
                        isRecommended: recommendedSite == site.rawValue
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSite = site.rawValue
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }
        }
        .padding(14)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

// MARK: - Region Card (Peptide)
struct RegionCardPeptide: View {
    let title: String
    let icon: String
    let sites: [(PeptideInjectionSite, String)]
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.categoryPeptide)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                Spacer()
            }

            // Site buttons
            if compact {
                VStack(spacing: 6) {
                    ForEach(sites, id: \.0) { site, label in
                        SiteButton(
                            label: label,
                            isSelected: selectedSite == site.rawValue,
                            isLastUsed: lastUsedSite == site.rawValue,
                            isRecommended: recommendedSite == site.rawValue,
                            compact: true
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedSite = site.rawValue
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            } else {
                HStack(spacing: 8) {
                    ForEach(sites, id: \.0) { site, label in
                        SiteButton(
                            label: label,
                            isSelected: selectedSite == site.rawValue,
                            isLastUsed: lastUsedSite == site.rawValue,
                            isRecommended: recommendedSite == site.rawValue
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedSite = site.rawValue
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            }
        }
        .padding(compact ? 10 : 14)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

// MARK: - Site Button
struct SiteButton: View {
    let label: String
    let isSelected: Bool
    let isLastUsed: Bool
    let isRecommended: Bool
    var compact: Bool = false
    let onTap: () -> Void

    private var backgroundColor: Color {
        if isSelected { return .accentPrimary }
        if isRecommended { return .statusSuccess.opacity(0.2) }
        if isLastUsed { return .statusWarning.opacity(0.2) }
        return .backgroundTertiary
    }

    private var borderColor: Color {
        if isSelected { return .accentPrimary }
        if isRecommended { return .statusSuccess }
        if isLastUsed { return .statusWarning }
        return .clear
    }

    private var textColor: Color {
        if isSelected { return .white }
        return .textPrimary
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if isRecommended && !isSelected {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.statusSuccess)
                }
                Text(label)
                    .font(compact ? .caption : .subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 8 : 10)
            .padding(.horizontal, 8)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isSelected ? 0 : 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Legend Indicator
struct LegendIndicator: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .foregroundColor(.textSecondary)
        }
    }
}

// Keep LegendDot for backward compatibility
struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.textSecondary)
        }
    }
}

#Preview("Peptide Sites") {
    ScrollView {
        VStack {
            Text("Peptide Injection Sites")
                .font(.headline)
            VisualBodySilhouette(
                injectionType: .subcutaneous,
                selectedSite: .constant("left_belly_upper"),
                lastUsedSite: "right_belly_lower",
                recommendedSite: "left_love_handle_upper"
            )
        }
        .padding()
    }
    .background(Color.backgroundPrimary)
    .preferredColorScheme(.dark)
}

#Preview("PED Sites") {
    ScrollView {
        VStack {
            Text("PED Injection Sites")
                .font(.headline)
            VisualBodySilhouette(
                injectionType: .intramuscular,
                selectedSite: .constant("glute_left"),
                lastUsedSite: "delt_right",
                recommendedSite: "glute_right"
            )
        }
        .padding()
    }
    .background(Color.backgroundPrimary)
    .preferredColorScheme(.dark)
}
