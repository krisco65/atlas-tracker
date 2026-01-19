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

    @State private var showingSubOptions = false
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

            // Body diagram with overlay buttons
            GeometryReader { geometry in
                // Make body fill most of screen height (2-3x larger than before)
                let availableHeight = geometry.size.height * 0.95
                let bodyHeight = availableHeight
                let bodyWidth = bodyHeight / 2.2  // Maintain aspect ratio

                ZStack {
                    // Professional body silhouette shape
                    BodySilhouetteView(
                        fillColor: Color(white: 0.22),
                        strokeColor: Color(white: 0.35),
                        showGlow: true
                    )
                    .frame(width: bodyWidth, height: bodyHeight)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                    // Injection site buttons with labels
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
                            showingSubOptions: $showingSubOptions,
                            selectedRegion: $selectedRegion,
                            bodyWidth: bodyWidth,
                            bodyHeight: bodyHeight,
                            containerSize: geometry.size
                        )
                    }
                }
            }
            .frame(minHeight: 550, maxHeight: 700)
            .background(Color.black) // Match body image background

            // Selected site display
            if let selected = selectedSite {
                SelectedSiteLabel(
                    displayName: getDisplayName(for: selected),
                    injectionType: injectionType
                )
            }
        }
        .padding(.horizontal, 4)
        .sheet(isPresented: $showingSubOptions) {
            if let region = selectedRegion {
                SubOptionSheet(
                    region: region,
                    selectedSite: $selectedSite,
                    lastUsedSite: lastUsedSite,
                    recommendedSite: recommendedSite,
                    isPresented: $showingSubOptions
                )
                .presentationDetents([.height(region == .belly ? 280 : 200)])
                .presentationDragIndicator(.visible)
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

// MARK: - Injection Region (for two-step selection)
enum InjectionRegion: String, CaseIterable {
    case belly = "belly"              // Single belly region - drills down to 4-zone grid
    case loveHandleLeft = "love_handle_left"
    case loveHandleRight = "love_handle_right"
    case gluteLeft = "glute_left"
    case gluteRight = "glute_right"
    case thighLeft = "thigh_left"
    case thighRight = "thigh_right"

    var displayName: String {
        switch self {
        case .belly: return "Belly"
        case .loveHandleLeft: return "Left Side"
        case .loveHandleRight: return "Right Side"
        case .gluteLeft: return "Left Glute"
        case .gluteRight: return "Right Glute"
        case .thighLeft: return "Left Thigh"
        case .thighRight: return "Right Thigh"
        }
    }

    var shortLabel: String {
        switch self {
        case .belly: return "Belly"
        case .loveHandleLeft: return "Side"
        case .loveHandleRight: return "Side"
        case .gluteLeft: return "Glute"
        case .gluteRight: return "Glute"
        case .thighLeft: return "Thigh"
        case .thighRight: return "Thigh"
        }
    }

    var hasSubOptions: Bool {
        switch self {
        case .thighLeft, .thighRight: return false
        default: return true
        }
    }

    var subOptions: [(PeptideInjectionSite, String)] {
        switch self {
        case .belly: return [
            (.leftBellyUpper, "Upper Left"),
            (.rightBellyUpper, "Upper Right"),
            (.leftBellyLower, "Lower Left"),
            (.rightBellyLower, "Lower Right")
        ]
        case .loveHandleLeft: return [(.leftLoveHandleUpper, "Upper"), (.leftLoveHandleLower, "Lower")]
        case .loveHandleRight: return [(.rightLoveHandleUpper, "Upper"), (.rightLoveHandleLower, "Lower")]
        case .gluteLeft: return [(.gluteLeftUpper, "Upper"), (.gluteLeftLower, "Lower")]
        case .gluteRight: return [(.gluteRightUpper, "Upper"), (.gluteRightLower, "Lower")]
        case .thighLeft: return [(.thighLeft, "Left Thigh")]
        case .thighRight: return [(.thighRight, "Right Thigh")]
        }
    }

    var directSite: PeptideInjectionSite? {
        switch self {
        case .thighLeft: return .thighLeft
        case .thighRight: return .thighRight
        default: return nil
        }
    }

    // Position on body (calibrated for Body.png image)
    var position: (x: CGFloat, y: CGFloat) {
        switch self {
        case .belly: return (0.50, 0.38)         // Center of belly
        case .loveHandleLeft: return (0.22, 0.38)
        case .loveHandleRight: return (0.78, 0.38)
        case .gluteLeft: return (0.35, 0.52)
        case .gluteRight: return (0.65, 0.52)
        case .thighLeft: return (0.38, 0.72)
        case .thighRight: return (0.62, 0.72)
        }
    }

    // Check if any sub-site is selected/recommended/lastUsed
    func containsSite(_ site: String?) -> Bool {
        guard let site = site else { return false }
        return subOptions.contains { $0.0.rawValue == site }
    }
}

// MARK: - Peptide Site Overlays (Two-Step)
struct PeptideSiteOverlays: View {
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?
    @Binding var showingSubOptions: Bool
    @Binding var selectedRegion: InjectionRegion?
    let bodyWidth: CGFloat
    let bodyHeight: CGFloat
    let containerSize: CGSize

    private var offsetX: CGFloat { (containerSize.width - bodyWidth) / 2 }
    private var offsetY: CGFloat { (containerSize.height - bodyHeight) / 2 }

    var body: some View {
        ForEach(InjectionRegion.allCases, id: \.self) { region in
            RegionButton(
                region: region,
                isSelected: region.containsSite(selectedSite),
                isRecommended: region.containsSite(recommendedSite),
                isLastUsed: region.containsSite(lastUsedSite)
            ) {
                if region.hasSubOptions {
                    selectedRegion = region
                    showingSubOptions = true
                } else if let site = region.directSite {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selectedSite = site.rawValue
                    }
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            .position(
                x: offsetX + bodyWidth * region.position.x,
                y: offsetY + bodyHeight * region.position.y
            )
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
            PEDSiteButton(
                site: site,
                isSelected: selectedSite == site.rawValue,
                isRecommended: recommendedSite == site.rawValue,
                isLastUsed: lastUsedSite == site.rawValue
            ) {
                withAnimation(.easeOut(duration: 0.15)) {
                    selectedSite = site.rawValue
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            .position(
                x: offsetX + bodyWidth * site.bodyMapPosition.x,
                y: offsetY + bodyHeight * site.bodyMapPosition.y
            )
        }
    }
}

// MARK: - Region Button (with label)
struct RegionButton: View {
    let region: InjectionRegion
    let isSelected: Bool
    let isRecommended: Bool
    let isLastUsed: Bool
    let onTap: () -> Void

    private let buttonSize: CGFloat = 54  // Larger for bigger body

    private var backgroundColor: Color {
        if isSelected { return .accentPrimary }
        return Color.black.opacity(0.7)
    }

    private var borderColor: Color {
        if isSelected { return .accentPrimary }
        if isRecommended { return .statusSuccess }
        if isLastUsed { return .statusWarning }
        return Color.white.opacity(0.4)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                ZStack {
                    // Glow for recommended
                    if isRecommended && !isSelected {
                        Circle()
                            .fill(Color.statusSuccess.opacity(0.4))
                            .frame(width: buttonSize + 14, height: buttonSize + 14)
                            .blur(radius: 8)
                    }

                    // Main circle
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: buttonSize, height: buttonSize)
                        .overlay(
                            Circle()
                                .stroke(borderColor, lineWidth: 2)
                        )
                        .shadow(color: isSelected ? .accentPrimary.opacity(0.5) : .clear, radius: 4)

                    // Star for recommended
                    if isRecommended && !isSelected {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.statusSuccess)
                    }
                }

                // Label
                Text(region.shortLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - PED Site Button (with label)
struct PEDSiteButton: View {
    let site: PEDInjectionSite
    let isSelected: Bool
    let isRecommended: Bool
    let isLastUsed: Bool
    let onTap: () -> Void

    private let buttonSize: CGFloat = 50  // Larger for bigger body

    private var backgroundColor: Color {
        if isSelected { return .accentPrimary }
        return Color.black.opacity(0.7)
    }

    private var borderColor: Color {
        if isSelected { return .accentPrimary }
        if isRecommended { return .statusSuccess }
        if isLastUsed { return .statusWarning }
        return Color.white.opacity(0.4)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                ZStack {
                    // Glow for recommended
                    if isRecommended && !isSelected {
                        Circle()
                            .fill(Color.statusSuccess.opacity(0.4))
                            .frame(width: buttonSize + 12, height: buttonSize + 12)
                            .blur(radius: 6)
                    }

                    // Main circle
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: buttonSize, height: buttonSize)
                        .overlay(
                            Circle()
                                .stroke(borderColor, lineWidth: 2)
                        )
                        .shadow(color: isSelected ? .accentPrimary.opacity(0.5) : .clear, radius: 4)

                    // Star for recommended
                    if isRecommended && !isSelected {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.statusSuccess)
                    }
                }

                // Label
                Text(site.shortName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Sub-Option Sheet
struct SubOptionSheet: View {
    let region: InjectionRegion
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Select \(region.displayName) Zone")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.textTertiary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Options - Grid for belly (4 zones), Row for others (2 zones)
            if region == .belly {
                // 2x2 Grid for belly zones
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ForEach(region.subOptions.prefix(2), id: \.0) { site, label in
                            SubOptionButton(
                                label: label,
                                isSelected: selectedSite == site.rawValue,
                                isRecommended: recommendedSite == site.rawValue,
                                isLastUsed: lastUsedSite == site.rawValue
                            ) {
                                selectSite(site)
                            }
                        }
                    }
                    HStack(spacing: 12) {
                        ForEach(region.subOptions.suffix(2), id: \.0) { site, label in
                            SubOptionButton(
                                label: label,
                                isSelected: selectedSite == site.rawValue,
                                isRecommended: recommendedSite == site.rawValue,
                                isLastUsed: lastUsedSite == site.rawValue
                            ) {
                                selectSite(site)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                // Row for 2-zone regions
                HStack(spacing: 16) {
                    ForEach(region.subOptions, id: \.0) { site, label in
                        SubOptionButton(
                            label: label,
                            isSelected: selectedSite == site.rawValue,
                            isRecommended: recommendedSite == site.rawValue,
                            isLastUsed: lastUsedSite == site.rawValue
                        ) {
                            selectSite(site)
                        }
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .background(Color.backgroundPrimary)
    }

    private func selectSite(_ site: PeptideInjectionSite) {
        withAnimation(.easeOut(duration: 0.15)) {
            selectedSite = site.rawValue
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Dismiss after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Sub-Option Button
struct SubOptionButton: View {
    let label: String
    let isSelected: Bool
    let isRecommended: Bool
    let isLastUsed: Bool
    let onTap: () -> Void

    private var backgroundColor: Color {
        if isSelected { return .accentPrimary }
        if isRecommended { return .statusSuccess.opacity(0.2) }
        if isLastUsed { return .statusWarning.opacity(0.2) }
        return .backgroundSecondary
    }

    private var borderColor: Color {
        if isSelected { return .accentPrimary }
        if isRecommended { return .statusSuccess }
        if isLastUsed { return .statusWarning }
        return .clear
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if isRecommended && !isSelected {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.statusSuccess)
                }
                Text(label)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
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
                recommendedSite: "left_love_handle_upper"
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
