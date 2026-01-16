import SwiftUI

// MARK: - Peptide Body Diagram View
/// Interactive body diagram for subcutaneous (SubQ) injection sites
/// Used for Peptides: belly quadrants, love handles, glutes, thighs
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

            // Glutes View
            VStack(spacing: 8) {
                Text("GLUTES")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)

                glutesView
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
            // Left love handle (upper/lower)
            VStack(spacing: 4) {
                siteButton(
                    site: .leftLoveHandleUpper,
                    label: "L Side U",
                    width: 50,
                    height: 38
                )
                siteButton(
                    site: .leftLoveHandleLower,
                    label: "L Side L",
                    width: 50,
                    height: 38
                )
            }

            // Belly grid (2x2)
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    siteButton(
                        site: .leftBellyUpper,
                        label: "UL",
                        width: 55,
                        height: 38
                    )

                    // Navel indicator
                    Circle()
                        .stroke(Color.textTertiary, lineWidth: 1)
                        .frame(width: 12, height: 12)

                    siteButton(
                        site: .rightBellyUpper,
                        label: "UR",
                        width: 55,
                        height: 38
                    )
                }

                HStack(spacing: 8) {
                    siteButton(
                        site: .leftBellyLower,
                        label: "LL",
                        width: 55,
                        height: 38
                    )

                    Spacer()
                        .frame(width: 12)

                    siteButton(
                        site: .rightBellyLower,
                        label: "LR",
                        width: 55,
                        height: 38
                    )
                }
            }

            // Right love handle (upper/lower)
            VStack(spacing: 4) {
                siteButton(
                    site: .rightLoveHandleUpper,
                    label: "R Side U",
                    width: 50,
                    height: 38
                )
                siteButton(
                    site: .rightLoveHandleLower,
                    label: "R Side L",
                    width: 50,
                    height: 38
                )
            }
        }
    }

    // MARK: - Glutes View
    private var glutesView: some View {
        HStack(spacing: 20) {
            // Left glute (upper/lower)
            VStack(spacing: 4) {
                siteButton(
                    site: .gluteLeftUpper,
                    label: "L Upper",
                    width: 70,
                    height: 35
                )
                siteButton(
                    site: .gluteLeftLower,
                    label: "L Lower",
                    width: 70,
                    height: 35
                )
            }

            // Right glute (upper/lower)
            VStack(spacing: 4) {
                siteButton(
                    site: .gluteRightUpper,
                    label: "R Upper",
                    width: 70,
                    height: 35
                )
                siteButton(
                    site: .gluteRightLower,
                    label: "R Lower",
                    width: 70,
                    height: 35
                )
            }
        }
    }

    // MARK: - Thighs View
    private var thighsView: some View {
        HStack(spacing: 40) {
            siteButton(
                site: .thighLeft,
                label: "L Thigh",
                width: 80,
                height: 50
            )

            siteButton(
                site: .thighRight,
                label: "R Thigh",
                width: 80,
                height: 50
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
                    .font(.caption2)
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
        selectedSite: .constant("left_belly_upper"),
        lastUsedSite: "right_belly_lower",
        recommendedSite: "left_love_handle_upper"
    )
    .padding()
    .background(Color.backgroundPrimary)
    .preferredColorScheme(.dark)
}
