import SwiftUI

// MARK: - Visual Body Silhouette
/// Body image with tappable injection site overlays
struct VisualBodySilhouette: View {
    let injectionType: BodyDiagramView.InjectionType
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?

    var body: some View {
        VStack(spacing: 12) {
            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .accentPrimary, label: "Selected")
                LegendItem(color: .statusSuccess, label: "Recommended")
                LegendItem(color: .statusWarning, label: "Last Used")
            }
            .font(.caption2)

            // Body image with overlay buttons
            GeometryReader { geometry in
                let imageSize = calculateImageSize(in: geometry.size)
                let offsetX = (geometry.size.width - imageSize.width) / 2
                let offsetY = (geometry.size.height - imageSize.height) / 2

                ZStack {
                    // Body silhouette image
                    Image("Body")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: imageSize.width, height: imageSize.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                    // Injection site buttons
                    if injectionType == .intramuscular {
                        // PED sites
                        ForEach(PEDInjectionSite.allCases, id: \.self) { site in
                            InjectionButton(
                                isSelected: selectedSite == site.rawValue,
                                isRecommended: recommendedSite == site.rawValue,
                                isLastUsed: lastUsedSite == site.rawValue,
                                label: site.shortName
                            ) {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    selectedSite = site.rawValue
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            .position(
                                x: offsetX + imageSize.width * site.bodyMapPosition.x,
                                y: offsetY + imageSize.height * site.bodyMapPosition.y
                            )
                        }
                    } else {
                        // Peptide sites
                        ForEach(PeptideInjectionSite.allCases, id: \.self) { site in
                            InjectionButton(
                                isSelected: selectedSite == site.rawValue,
                                isRecommended: recommendedSite == site.rawValue,
                                isLastUsed: lastUsedSite == site.rawValue,
                                label: site.shortName
                            ) {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    selectedSite = site.rawValue
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            .position(
                                x: offsetX + imageSize.width * site.bodyMapPosition.x,
                                y: offsetY + imageSize.height * site.bodyMapPosition.y
                            )
                        }
                    }
                }
            }
            .frame(height: 420)

            // Selected site display
            if let selected = selectedSite {
                SelectedSiteLabel(
                    displayName: getDisplayName(for: selected),
                    injectionType: injectionType
                )
            }
        }
        .padding(.horizontal, 8)
    }

    private func calculateImageSize(in containerSize: CGSize) -> CGSize {
        // Maintain aspect ratio, fit within container
        let maxWidth = min(containerSize.width * 0.9, 300)
        let maxHeight = containerSize.height * 0.95

        // Assuming body image is roughly 1:2.2 aspect ratio (width:height)
        let aspectRatio: CGFloat = 0.45

        let widthBasedHeight = maxWidth / aspectRatio
        let heightBasedWidth = maxHeight * aspectRatio

        if widthBasedHeight <= maxHeight {
            return CGSize(width: maxWidth, height: widthBasedHeight)
        } else {
            return CGSize(width: heightBasedWidth, height: maxHeight)
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

// MARK: - Injection Button
struct InjectionButton: View {
    let isSelected: Bool
    let isRecommended: Bool
    let isLastUsed: Bool
    let label: String
    let onTap: () -> Void

    private let buttonSize: CGFloat = 28
    private let selectedSize: CGFloat = 32

    private var currentSize: CGFloat {
        isSelected ? selectedSize : buttonSize
    }

    private var backgroundColor: Color {
        if isSelected { return .accentPrimary }
        return Color.black.opacity(0.6)
    }

    private var borderColor: Color {
        if isSelected { return .accentPrimary }
        if isRecommended { return .statusSuccess }
        if isLastUsed { return .statusWarning }
        return Color.white.opacity(0.3)
    }

    private var borderWidth: CGFloat {
        if isSelected { return 0 }
        if isRecommended || isLastUsed { return 2 }
        return 1
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Glow effect for recommended
                if isRecommended && !isSelected {
                    Circle()
                        .fill(Color.statusSuccess.opacity(0.4))
                        .frame(width: currentSize + 12, height: currentSize + 12)
                        .blur(radius: 6)
                }

                // Main circle
                Circle()
                    .fill(backgroundColor)
                    .frame(width: currentSize, height: currentSize)
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .shadow(color: isSelected ? .accentPrimary.opacity(0.5) : .clear, radius: 4)

                // Star for recommended
                if isRecommended && !isSelected {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.statusSuccess)
                        .offset(x: currentSize / 2 - 2, y: -currentSize / 2 + 2)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Selected Site Label
struct SelectedSiteLabel: View {
    let displayName: String
    let injectionType: BodyDiagramView.InjectionType

    var body: some View {
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
                .foregroundColor(.white)
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
                .foregroundColor(.white)
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
