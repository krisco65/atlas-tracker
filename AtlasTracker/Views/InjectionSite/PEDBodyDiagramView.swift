import SwiftUI

// MARK: - PED Body Diagram View
/// Interactive body diagram for intramuscular (IM) injection sites
/// Used for PEDs: glutes, deltoids, quads, ventro-gluteal
struct PEDBodyDiagramView: View {
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?

    var body: some View {
        VStack(spacing: 20) {
            // Front View
            VStack(spacing: 8) {
                Text("FRONT")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)

                frontBodyView
            }

            Divider()
                .background(Color.backgroundTertiary)

            // Back View
            VStack(spacing: 8) {
                Text("BACK")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)

                backBodyView
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(16)
    }

    // MARK: - Front Body View
    private var frontBodyView: some View {
        VStack(spacing: 12) {
            // Deltoids Row
            HStack(spacing: 60) {
                siteButton(
                    site: .deltLeft,
                    label: "L Delt"
                )

                // Head placeholder
                Circle()
                    .fill(Color.backgroundTertiary)
                    .frame(width: 40, height: 40)

                siteButton(
                    site: .deltRight,
                    label: "R Delt"
                )
            }

            // Torso placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.backgroundTertiary)
                .frame(width: 80, height: 60)

            // Quads Row
            HStack(spacing: 20) {
                siteButton(
                    site: .quadLeft,
                    label: "L Quad"
                )

                siteButton(
                    site: .quadRight,
                    label: "R Quad"
                )
            }
        }
    }

    // MARK: - Back Body View
    private var backBodyView: some View {
        VStack(spacing: 12) {
            // Upper back placeholder
            HStack(spacing: 60) {
                // Shoulder placeholders
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.backgroundTertiary)
                    .frame(width: 30, height: 30)

                Circle()
                    .fill(Color.backgroundTertiary)
                    .frame(width: 40, height: 40)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.backgroundTertiary)
                    .frame(width: 30, height: 30)
            }

            // Mid back placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.backgroundTertiary)
                .frame(width: 80, height: 40)

            // Glutes and VG Row
            HStack(spacing: 8) {
                VStack(spacing: 4) {
                    siteButton(
                        site: .vgLeft,
                        label: "L VG"
                    )
                    siteButton(
                        site: .gluteLeft,
                        label: "L Glute"
                    )
                }

                VStack(spacing: 4) {
                    siteButton(
                        site: .vgRight,
                        label: "R VG"
                    )
                    siteButton(
                        site: .gluteRight,
                        label: "R Glute"
                    )
                }
            }
        }
    }

    // MARK: - Site Button
    private func siteButton(site: PEDInjectionSite, label: String) -> some View {
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
            .frame(width: 70, height: 50)
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
    PEDBodyDiagramView(
        selectedSite: .constant("glute_left"),
        lastUsedSite: "delt_right",
        recommendedSite: "glute_right"
    )
    .padding()
    .background(Color.backgroundPrimary)
    .preferredColorScheme(.dark)
}
