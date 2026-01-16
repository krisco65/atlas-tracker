import SwiftUI

// MARK: - Peptide Body Diagram View
/// Interactive body diagram for subcutaneous (SubQ) injection sites
/// Used for Peptides: belly quadrants, love handles, thighs
struct PeptideBodyDiagramView: View {
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?

    var body: some View {
        VStack(spacing: 20) {
            // Torso View - Belly and Love Handles
            VStack(spacing: 8) {
                Text("ABDOMEN")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)

                torsoView
            }

            Divider()
                .background(Color.backgroundTertiary)

            // Thighs View
            VStack(spacing: 8) {
                Text("THIGHS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)

                thighsView
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(16)
    }

    // MARK: - Torso View
    private var torsoView: some View {
        HStack(spacing: 8) {
            // Left love handle
            siteButton(
                site: .loveHandleLeft,
                label: "L Side",
                width: 50,
                height: 80
            )

            // Belly grid (2x2)
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    siteButton(
                        site: .bellyUpperLeft,
                        label: "UL",
                        width: 60,
                        height: 50
                    )

                    // Navel indicator
                    Circle()
                        .stroke(Color.textTertiary, lineWidth: 1)
                        .frame(width: 12, height: 12)

                    siteButton(
                        site: .bellyUpperRight,
                        label: "UR",
                        width: 60,
                        height: 50
                    )
                }

                HStack(spacing: 8) {
                    siteButton(
                        site: .bellyLowerLeft,
                        label: "LL",
                        width: 60,
                        height: 50
                    )

                    Spacer()
                        .frame(width: 12)

                    siteButton(
                        site: .bellyLowerRight,
                        label: "LR",
                        width: 60,
                        height: 50
                    )
                }
            }

            // Right love handle
            siteButton(
                site: .loveHandleRight,
                label: "R Side",
                width: 50,
                height: 80
            )
        }
    }

    // MARK: - Thighs View
    private var thighsView: some View {
        HStack(spacing: 40) {
            siteButton(
                site: .thighLeft,
                label: "L Thigh",
                width: 80,
                height: 60
            )

            siteButton(
                site: .thighRight,
                label: "R Thigh",
                width: 80,
                height: 60
            )
        }
    }

    // MARK: - Site Button
    private func siteButton(site: PeptideInjectionSite, label: String, width: CGFloat, height: CGFloat) -> some View {
        let isSelected = selectedSite == site.rawValue
        let isLastUsed = lastUsedSite == site.rawValue
        let isRecommended = recommendedSite == site.rawValue

        return Button {
            selectedSite = site.rawValue
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } label: {
            VStack(spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .medium)

                if isRecommended && !isSelected {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.statusSuccess)
                }
            }
            .frame(width: width, height: height)
            .modifier(InjectionSiteButtonStyle(
                isSelected: isSelected,
                isLastUsed: isLastUsed,
                isRecommended: isRecommended
            ))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PeptideBodyDiagramView(
        selectedSite: .constant("belly_upper_left"),
        lastUsedSite: "belly_lower_right",
        recommendedSite: "love_handle_left"
    )
    .padding()
    .background(Color.backgroundPrimary)
    .preferredColorScheme(.dark)
}
