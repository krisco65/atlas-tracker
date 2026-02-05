import SwiftUI

// MARK: - Body Silhouette View
/// Professional body silhouette using image asset
struct BodySilhouetteView: View {
    var fillColor: Color = Color(white: 0.25)
    var strokeColor: Color = Color(white: 0.4)
    var showGlow: Bool = true

    var body: some View {
        Image("Body")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

// MARK: - Visual Body Silhouette
/// Body image with tappable injection site overlays and two-step selection
struct VisualBodySilhouette: View {
    let injectionType: BodyDiagramView.InjectionType
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?

    @State private var selectedRegion: InjectionRegion?

    var body: some View {
        VStack(spacing: 12) {
            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .accentPrimary, label: "Selected")
                LegendItem(color: .statusSuccess, label: "Recommended")
                LegendItem(color: .statusWarning, label: "Last Used")
            }
            .font(.caption2)

            // Body diagram with overlay regions
            GeometryReader { geometry in
                // Scale up silhouette to fill more screen space (125% of container)
                let scaleFactor: CGFloat = 1.25
                let baseHeight = geometry.size.height
                let bodyHeight = baseHeight * scaleFactor
                let bodyWidth = bodyHeight / 2.2

                ZStack {
                    // Professional body silhouette shape
                    BodySilhouetteView(
                        fillColor: Color(white: 0.22),
                        strokeColor: Color(white: 0.35),
                        showGlow: true
                    )
                    .frame(width: bodyWidth, height: bodyHeight)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                    // Injection site highlighted regions
                    if injectionType == .intramuscular {
                        PEDSiteOverlays(
                            selectedSite: $selectedSite,
                            lastUsedSite: lastUsedSite,
                            recommendedSite: recommendedSite,
                            bodyWidth: bodyWidth,
                            bodyHeight: bodyHeight,
                            containerSize: geometry.size
                        )
                    } else {
                        PeptideSiteOverlays(
                            selectedSite: $selectedSite,
                            lastUsedSite: lastUsedSite,
                            recommendedSite: recommendedSite,
                            selectedRegion: $selectedRegion,
                            bodyWidth: bodyWidth,
                            bodyHeight: bodyHeight,
                            containerSize: geometry.size
                        )
                    }
                }
            }
            .frame(minHeight: 580, maxHeight: 750)
            .background(Color.black)

            // Selected site display
            if let selected = selectedSite {
                SelectedSiteLabel(
                    displayName: getDisplayName(for: selected),
                    injectionType: injectionType
                )
            }
        }
        .padding(.horizontal, 4)
        .sheet(item: $selectedRegion) { region in
            SubOptionSheet(
                region: region,
                selectedSite: $selectedSite,
                lastUsedSite: lastUsedSite,
                recommendedSite: recommendedSite,
                onDismiss: { selectedRegion = nil }
            )
            .presentationDetents([.height(region == .belly ? 380 : 240)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(white: 0.12))
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

// MARK: - Injection Region (for two-step selection)
enum InjectionRegion: String, CaseIterable, Identifiable {
    case belly = "belly"
    case gluteLeft = "glute_left"
    case gluteRight = "glute_right"
    case thighLeft = "thigh_left"
    case thighRight = "thigh_right"
    case deltLeft = "delt_left"
    case deltRight = "delt_right"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .belly: return "Belly"
        case .gluteLeft: return "Left Glute"
        case .gluteRight: return "Right Glute"
        case .thighLeft: return "Left Thigh"
        case .thighRight: return "Right Thigh"
        case .deltLeft: return "Left Deltoid"
        case .deltRight: return "Right Deltoid"
        }
    }

    var shortLabel: String {
        switch self {
        case .belly: return "Belly"
        case .gluteLeft: return "L Glute"
        case .gluteRight: return "R Glute"
        case .thighLeft: return "L Thigh"
        case .thighRight: return "R Thigh"
        case .deltLeft: return "L Delt"
        case .deltRight: return "R Delt"
        }
    }

    var hasSubOptions: Bool {
        switch self {
        case .deltLeft, .deltRight: return false
        default: return true
        }
    }

    var subOptions: [(PeptideInjectionSite, String)] {
        switch self {
        case .belly: return [
            (.leftBellyUpper, "Upper Left"),
            (.centerBellyUpper, "Upper Middle"),
            (.rightBellyUpper, "Upper Right"),
            (.leftBellyLower, "Lower Left"),
            (.centerBellyLower, "Lower Middle"),
            (.rightBellyLower, "Lower Right")
        ]
        case .gluteLeft: return [(.gluteLeftUpper, "Upper"), (.gluteLeftLower, "Lower")]
        case .gluteRight: return [(.gluteRightUpper, "Upper"), (.gluteRightLower, "Lower")]
        case .thighLeft: return [(.thighLeftUpper, "Upper"), (.thighLeftMiddle, "Middle"), (.thighLeftLower, "Lower")]
        case .thighRight: return [(.thighRightUpper, "Upper"), (.thighRightMiddle, "Middle"), (.thighRightLower, "Lower")]
        case .deltLeft, .deltRight: return []
        }
    }

    var directSite: PeptideInjectionSite? {
        switch self {
        case .deltLeft: return .deltLeft
        case .deltRight: return .deltRight
        default: return nil
        }
    }

    // Position on body - calibrated for larger silhouette
    var position: (x: CGFloat, y: CGFloat) {
        switch self {
        case .belly: return (0.50, 0.42)      // Moved down to actual belly (was 0.38)
        case .gluteLeft: return (0.32, 0.52)
        case .gluteRight: return (0.68, 0.52)
        case .thighLeft: return (0.36, 0.64)
        case .thighRight: return (0.64, 0.64)
        case .deltLeft: return (0.24, 0.26)   // Symmetric with right (moved in from 0.22)
        case .deltRight: return (0.76, 0.26)  // Symmetric with left (moved in from 0.78)
        }
    }

    // Size of the highlight region
    var regionSize: CGSize {
        switch self {
        case .belly: return CGSize(width: 80, height: 60)
        case .gluteLeft, .gluteRight: return CGSize(width: 55, height: 50)
        case .thighLeft, .thighRight: return CGSize(width: 45, height: 70)
        case .deltLeft, .deltRight: return CGSize(width: 45, height: 45)
        }
    }

    func containsSite(_ site: String?) -> Bool {
        guard let site = site else { return false }
        if let direct = directSite, direct.rawValue == site { return true }
        return subOptions.contains { $0.0.rawValue == site }
    }
}

// MARK: - Peptide Site Overlays (Two-Step with Highlighted Regions)
struct PeptideSiteOverlays: View {
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?
    @Binding var selectedRegion: InjectionRegion?
    let bodyWidth: CGFloat
    let bodyHeight: CGFloat
    let containerSize: CGSize

    private var offsetX: CGFloat { (containerSize.width - bodyWidth) / 2 }
    private var offsetY: CGFloat { (containerSize.height - bodyHeight) / 2 }

    var body: some View {
        ForEach(InjectionRegion.allCases, id: \.self) { region in
            HighlightedRegionButton(
                region: region,
                isSelected: region.containsSite(selectedSite),
                isRecommended: region.containsSite(recommendedSite),
                isLastUsed: region.containsSite(lastUsedSite)
            ) {
                handleRegionTap(region)
            }
            .position(
                x: offsetX + bodyWidth * region.position.x,
                y: offsetY + bodyHeight * region.position.y
            )
        }
    }

    private func handleRegionTap(_ region: InjectionRegion) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if region.hasSubOptions {
            selectedRegion = region
        } else if let site = region.directSite {
            withAnimation(.easeOut(duration: 0.15)) {
                selectedSite = site.rawValue
            }
        }
    }
}

// MARK: - PED Site Overlays
struct PEDSiteOverlays: View {
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?
    let bodyWidth: CGFloat
    let bodyHeight: CGFloat
    let containerSize: CGSize

    private var offsetX: CGFloat { (containerSize.width - bodyWidth) / 2 }
    private var offsetY: CGFloat { (containerSize.height - bodyHeight) / 2 }

    var body: some View {
        ForEach(PEDInjectionSite.allCases, id: \.self) { site in
            PEDHighlightedButton(
                site: site,
                isSelected: selectedSite == site.rawValue,
                isRecommended: recommendedSite == site.rawValue,
                isLastUsed: lastUsedSite == site.rawValue
            ) {
                withAnimation(.easeOut(duration: 0.15)) {
                    selectedSite = site.rawValue
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            .position(
                x: offsetX + bodyWidth * site.bodyMapPosition.x,
                y: offsetY + bodyHeight * site.bodyMapPosition.y
            )
        }
    }
}

// MARK: - Highlighted Region Button (Replaces Circles)
struct HighlightedRegionButton: View {
    let region: InjectionRegion
    let isSelected: Bool
    let isRecommended: Bool
    let isLastUsed: Bool
    let onTap: () -> Void

    private var fillColor: Color {
        if isSelected {
            return Color.accentPrimary.opacity(0.5)
        } else if isRecommended {
            return Color.statusSuccess.opacity(0.35)
        } else if isLastUsed {
            return Color.statusWarning.opacity(0.3)
        }
        return Color.white.opacity(0.08)
    }

    private var borderColor: Color {
        if isSelected {
            return Color.accentPrimary
        } else if isRecommended {
            return Color.statusSuccess
        } else if isLastUsed {
            return Color.statusWarning
        }
        return Color.white.opacity(0.25)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    // Glow effect for recommended
                    if isRecommended && !isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.statusSuccess.opacity(0.3))
                            .frame(width: region.regionSize.width + 16, height: region.regionSize.height + 16)
                            .blur(radius: 10)
                    }

                    // Main highlighted region
                    RoundedRectangle(cornerRadius: 10)
                        .fill(fillColor)
                        .frame(width: region.regionSize.width, height: region.regionSize.height)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(borderColor, lineWidth: isSelected ? 3 : 2)
                        )
                        .shadow(color: isSelected ? .accentPrimary.opacity(0.6) : .clear, radius: 8)

                    // Icons
                    VStack(spacing: 2) {
                        if isRecommended && !isSelected {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.statusSuccess)
                        }

                        if region.hasSubOptions {
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }

                // Label
                Text(region.shortLabel)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isSelected)
        .accessibilityIdentifier("region_button_\(region.rawValue)")
    }
}

// MARK: - PED Highlighted Button
struct PEDHighlightedButton: View {
    let site: PEDInjectionSite
    let isSelected: Bool
    let isRecommended: Bool
    let isLastUsed: Bool
    let onTap: () -> Void

    private let buttonSize = CGSize(width: 50, height: 50)

    private var fillColor: Color {
        if isSelected {
            return Color.accentPrimary.opacity(0.5)
        } else if isRecommended {
            return Color.statusSuccess.opacity(0.35)
        } else if isLastUsed {
            return Color.statusWarning.opacity(0.3)
        }
        return Color.white.opacity(0.08)
    }

    private var borderColor: Color {
        if isSelected {
            return Color.accentPrimary
        } else if isRecommended {
            return Color.statusSuccess
        } else if isLastUsed {
            return Color.statusWarning
        }
        return Color.white.opacity(0.25)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    if isRecommended && !isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.statusSuccess.opacity(0.3))
                            .frame(width: buttonSize.width + 12, height: buttonSize.height + 12)
                            .blur(radius: 8)
                    }

                    RoundedRectangle(cornerRadius: 10)
                        .fill(fillColor)
                        .frame(width: buttonSize.width, height: buttonSize.height)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(borderColor, lineWidth: isSelected ? 3 : 2)
                        )
                        .shadow(color: isSelected ? .accentPrimary.opacity(0.6) : .clear, radius: 6)

                    if isRecommended && !isSelected {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.statusSuccess)
                    }
                }

                Text(site.shortName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isSelected)
        .accessibilityIdentifier("ped_site_button_\(site.rawValue)")
    }
}

// MARK: - Sub-Option Sheet (Fixed Navigation)
struct SubOptionSheet: View {
    let region: InjectionRegion
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Header with close button
            HStack {
                Text("Select \(region.displayName) Zone")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.gray)
                }
                .accessibilityIdentifier("sub_option_sheet_close")
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            // Zone buttons based on region
            VStack(spacing: 12) {
                switch region {
                case .belly:
                    bellyZoneGrid
                case .thighLeft, .thighRight:
                    thighZoneButtons
                default:
                    twoZoneButtons
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Belly: 3x2 Grid (3 columns × 2 rows)
    @ViewBuilder
    private var bellyZoneGrid: some View {
        VStack(spacing: 12) {
            // Upper row: Left, Middle, Right
            HStack(spacing: 8) {
                zoneButton(site: .leftBellyUpper, label: "Upper Left")
                zoneButton(site: .centerBellyUpper, label: "Upper Mid")
                zoneButton(site: .rightBellyUpper, label: "Upper Right")
            }
            // Lower row: Left, Middle, Right
            HStack(spacing: 8) {
                zoneButton(site: .leftBellyLower, label: "Lower Left")
                zoneButton(site: .centerBellyLower, label: "Lower Mid")
                zoneButton(site: .rightBellyLower, label: "Lower Right")
            }
        }
    }

    // MARK: - Thigh: 3 zones
    @ViewBuilder
    private var thighZoneButtons: some View {
        let sites: [(PeptideInjectionSite, String)] = region == .thighLeft
            ? [(.thighLeftUpper, "Upper"), (.thighLeftMiddle, "Middle"), (.thighLeftLower, "Lower")]
            : [(.thighRightUpper, "Upper"), (.thighRightMiddle, "Middle"), (.thighRightLower, "Lower")]

        HStack(spacing: 12) {
            ForEach(sites, id: \.0.rawValue) { site, label in
                zoneButton(site: site, label: label)
            }
        }
    }

    // MARK: - Other: 2 zones
    @ViewBuilder
    private var twoZoneButtons: some View {
        let sites: [(PeptideInjectionSite, String)] = {
            switch region {
            case .gluteLeft: return [(.gluteLeftUpper, "Upper"), (.gluteLeftLower, "Lower")]
            case .gluteRight: return [(.gluteRightUpper, "Upper"), (.gluteRightLower, "Lower")]
            default: return []
            }
        }()

        HStack(spacing: 12) {
            ForEach(sites, id: \.0.rawValue) { site, label in
                zoneButton(site: site, label: label)
            }
        }
    }

    // MARK: - Zone Button
    @ViewBuilder
    private func zoneButton(site: PeptideInjectionSite, label: String) -> some View {
        let isSelected = selectedSite == site.rawValue
        let isRecommended = recommendedSite == site.rawValue
        let isLastUsed = lastUsedSite == site.rawValue

        Button {
            selectedSite = site.rawValue
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onDismiss()
            }
        } label: {
            HStack(spacing: 8) {
                if isRecommended && !isSelected {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                Text(label)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                isSelected ? Color.accentPrimary :
                isRecommended ? Color.statusSuccess.opacity(0.25) :
                isLastUsed ? Color.statusWarning.opacity(0.25) :
                Color(white: 0.18)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color.accentPrimary :
                        isRecommended ? Color.statusSuccess :
                        isLastUsed ? Color.statusWarning :
                        Color.gray.opacity(0.3),
                        lineWidth: isSelected ? 3 : 2
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("zone_\(site.rawValue)")
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
                recommendedSite: "delt_left"
            )
        }
        .padding()
    }
    .background(Color.black)
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
    .background(Color.black)
    .preferredColorScheme(.dark)
}
