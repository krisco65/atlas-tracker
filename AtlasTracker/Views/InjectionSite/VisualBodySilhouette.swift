import SwiftUI

// MARK: - Body Silhouette View
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
struct VisualBodySilhouette: View {
    let injectionType: BodyDiagramView.InjectionType
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?

    @State private var selectedRegion: InjectionRegion?
    @State private var selectedPEDRegion: PEDInjectionRegion?

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
                let scaleFactor: CGFloat = 1.25
                let baseHeight = geometry.size.height
                let bodyHeight = baseHeight * scaleFactor
                let bodyWidth = bodyHeight / 2.2

                ZStack {
                    BodySilhouetteView(
                        fillColor: Color(white: 0.22),
                        strokeColor: Color(white: 0.35),
                        showGlow: true
                    )
                    .frame(width: bodyWidth, height: bodyHeight)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                    if injectionType == .intramuscular {
                        PEDSiteOverlays(
                            selectedSite: $selectedSite,
                            lastUsedSite: lastUsedSite,
                            recommendedSite: recommendedSite,
                            selectedRegion: $selectedPEDRegion,
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

            if let selected = selectedSite {
                SelectedSiteLabel(
                    displayName: getDisplayName(for: selected),
                    injectionType: injectionType
                )
            }
        }
        .padding(.horizontal, 4)
        // Peptide sub-options sheet
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
        // PED sub-options sheet
        .sheet(item: $selectedPEDRegion) { region in
            PEDSubOptionSheet(
                region: region,
                selectedSite: $selectedSite,
                lastUsedSite: lastUsedSite,
                recommendedSite: recommendedSite,
                onDismiss: { selectedPEDRegion = nil }
            )
            .presentationDetents([.height(240)])
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

// MARK: - PED Injection Region (for two-step selection)
enum PEDInjectionRegion: String, CaseIterable, Identifiable {
    case gluteLeft = "glute_left"
    case gluteRight = "glute_right"
    case deltLeft = "delt_left"
    case deltRight = "delt_right"
    case quadLeft = "quad_left"
    case quadRight = "quad_right"
    case vgLeft = "vg_left"
    case vgRight = "vg_right"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gluteLeft: return "Left Glute"
        case .gluteRight: return "Right Glute"
        case .deltLeft: return "Left Deltoid"
        case .deltRight: return "Right Deltoid"
        case .quadLeft: return "Left Quad"
        case .quadRight: return "Right Quad"
        case .vgLeft: return "Left VG"
        case .vgRight: return "Right VG"
        }
    }

    var shortLabel: String {
        switch self {
        case .gluteLeft: return "L Glute"
        case .gluteRight: return "R Glute"
        case .deltLeft: return "L Delt"
        case .deltRight: return "R Delt"
        case .quadLeft: return "L Quad"
        case .quadRight: return "R Quad"
        case .vgLeft: return "L VG"
        case .vgRight: return "R VG"
        }
    }

    var hasSubOptions: Bool {
        switch self {
        case .deltLeft, .deltRight, .quadLeft, .quadRight:
            return false
        case .gluteLeft, .gluteRight, .vgLeft, .vgRight:
            return true
        }
    }

    var subOptions: [(PEDInjectionSite, String)] {
        switch self {
        case .gluteLeft: return [(.gluteLeftUpper, "Upper"), (.gluteLeftLower, "Lower")]
        case .gluteRight: return [(.gluteRightUpper, "Upper"), (.gluteRightLower, "Lower")]
        case .vgLeft: return [(.vgLeftUpper, "Upper"), (.vgLeftLower, "Lower")]
        case .vgRight: return [(.vgRightUpper, "Upper"), (.vgRightLower, "Lower")]
        case .deltLeft, .deltRight, .quadLeft, .quadRight: return []
        }
    }

    var directSite: PEDInjectionSite? {
        switch self {
        case .deltLeft: return .deltLeft
        case .deltRight: return .deltRight
        case .quadLeft: return .quadLeft
        case .quadRight: return .quadRight
        default: return nil
        }
    }

    // Positions - posterior (back) view: patient's left is on screen-right
    // Glutes stacked above VG with clear vertical separation
    var position: (x: CGFloat, y: CGFloat) {
        switch self {
        case .deltLeft: return (0.80, 0.24)      // Patient's left = screen-right
        case .deltRight: return (0.20, 0.24)     // Patient's right = screen-left
        case .gluteLeft: return (0.68, 0.45)     // Upper butt area
        case .gluteRight: return (0.32, 0.45)
        case .vgLeft: return (0.76, 0.56)        // Hip area, below glutes
        case .vgRight: return (0.24, 0.56)
        case .quadLeft: return (0.62, 0.66)      // Mid-thigh
        case .quadRight: return (0.38, 0.66)
        }
    }

    var regionSize: CGSize {
        switch self {
        case .deltLeft, .deltRight: return CGSize(width: 36, height: 36)
        case .gluteLeft, .gluteRight: return CGSize(width: 34, height: 34)
        case .vgLeft, .vgRight: return CGSize(width: 30, height: 30)
        case .quadLeft, .quadRight: return CGSize(width: 36, height: 42)
        }
    }

    func containsSite(_ site: String?) -> Bool {
        guard let site = site else { return false }
        if let direct = directSite, direct.rawValue == site { return true }
        return subOptions.contains { $0.0.rawValue == site }
    }
}

// MARK: - Peptide Injection Region (for SubQ)
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

    var position: (x: CGFloat, y: CGFloat) {
        switch self {
        case .belly: return (0.52, 0.42)
        case .gluteLeft: return (0.32, 0.52)
        case .gluteRight: return (0.68, 0.52)
        case .thighLeft: return (0.36, 0.64)
        case .thighRight: return (0.64, 0.64)
        case .deltLeft: return (0.18, 0.26)
        case .deltRight: return (0.82, 0.26)
        }
    }

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

// MARK: - PED Site Overlays (with region selection)
struct PEDSiteOverlays: View {
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?
    @Binding var selectedRegion: PEDInjectionRegion?
    let bodyWidth: CGFloat
    let bodyHeight: CGFloat
    let containerSize: CGSize

    private var offsetX: CGFloat { (containerSize.width - bodyWidth) / 2 }
    private var offsetY: CGFloat { (containerSize.height - bodyHeight) / 2 }

    var body: some View {
        ForEach(PEDInjectionRegion.allCases, id: \.self) { region in
            PEDRegionButton(
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

    private func handleRegionTap(_ region: PEDInjectionRegion) {
        HapticManager.mediumImpact()

        if region.hasSubOptions {
            selectedRegion = region
        } else if let site = region.directSite {
            withAnimation(.easeOut(duration: 0.15)) {
                selectedSite = site.rawValue
            }
        }
    }
}

// MARK: - Peptide Site Overlays
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
        HapticManager.mediumImpact()

        if region.hasSubOptions {
            selectedRegion = region
        } else if let site = region.directSite {
            withAnimation(.easeOut(duration: 0.15)) {
                selectedSite = site.rawValue
            }
        }
    }
}

// MARK: - PED Region Button
struct PEDRegionButton: View {
    let region: PEDInjectionRegion
    let isSelected: Bool
    let isRecommended: Bool
    let isLastUsed: Bool
    let onTap: () -> Void

    private var fillColor: Color {
        if isSelected { return Color.accentPrimary.opacity(0.5) }
        if isRecommended { return Color.statusSuccess.opacity(0.35) }
        if isLastUsed { return Color.statusWarning.opacity(0.3) }
        return Color.white.opacity(0.08)
    }

    private var borderColor: Color {
        if isSelected { return Color.accentPrimary }
        if isRecommended { return Color.statusSuccess }
        if isLastUsed { return Color.statusWarning }
        return Color.white.opacity(0.25)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    if isRecommended && !isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.statusSuccess.opacity(0.3))
                            .frame(width: region.regionSize.width + 12, height: region.regionSize.height + 12)
                            .blur(radius: 8)
                    }

                    RoundedRectangle(cornerRadius: 8)
                        .fill(fillColor)
                        .frame(width: region.regionSize.width, height: region.regionSize.height)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(borderColor, lineWidth: isSelected ? 3 : 2)
                        )
                        .shadow(color: isSelected ? .accentPrimary.opacity(0.6) : .clear, radius: 6)

                    VStack(spacing: 2) {
                        if isRecommended && !isSelected {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.statusSuccess)
                        }
                        if region.hasSubOptions {
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }

                Text(region.shortLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Highlighted Region Button (Peptides)
struct HighlightedRegionButton: View {
    let region: InjectionRegion
    let isSelected: Bool
    let isRecommended: Bool
    let isLastUsed: Bool
    let onTap: () -> Void

    private var fillColor: Color {
        if isSelected { return Color.accentPrimary.opacity(0.5) }
        if isRecommended { return Color.statusSuccess.opacity(0.35) }
        if isLastUsed { return Color.statusWarning.opacity(0.3) }
        return Color.white.opacity(0.08)
    }

    private var borderColor: Color {
        if isSelected { return Color.accentPrimary }
        if isRecommended { return Color.statusSuccess }
        if isLastUsed { return Color.statusWarning }
        return Color.white.opacity(0.25)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    if isRecommended && !isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.statusSuccess.opacity(0.3))
                            .frame(width: region.regionSize.width + 16, height: region.regionSize.height + 16)
                            .blur(radius: 10)
                    }

                    RoundedRectangle(cornerRadius: 10)
                        .fill(fillColor)
                        .frame(width: region.regionSize.width, height: region.regionSize.height)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(borderColor, lineWidth: isSelected ? 3 : 2)
                        )
                        .shadow(color: isSelected ? .accentPrimary.opacity(0.6) : .clear, radius: 8)

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

                Text(region.shortLabel)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - PED Sub-Option Sheet
struct PEDSubOptionSheet: View {
    let region: PEDInjectionRegion
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
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
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            HStack(spacing: 12) {
                ForEach(region.subOptions, id: \.0.rawValue) { site, label in
                    pedZoneButton(site: site, label: label)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    @ViewBuilder
    private func pedZoneButton(site: PEDInjectionSite, label: String) -> some View {
        let isSelected = selectedSite == site.rawValue
        let isRecommended = recommendedSite == site.rawValue
        let isLastUsed = lastUsedSite == site.rawValue

        Button {
            selectedSite = site.rawValue
            HapticManager.mediumImpact()
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
    }
}

// MARK: - Peptide Sub-Option Sheet
struct SubOptionSheet: View {
    let region: InjectionRegion
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
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
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

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

    @ViewBuilder
    private var bellyZoneGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                zoneButton(site: .leftBellyUpper, label: "Upper Left")
                zoneButton(site: .centerBellyUpper, label: "Upper Mid")
                zoneButton(site: .rightBellyUpper, label: "Upper Right")
            }
            HStack(spacing: 8) {
                zoneButton(site: .leftBellyLower, label: "Lower Left")
                zoneButton(site: .centerBellyLower, label: "Lower Mid")
                zoneButton(site: .rightBellyLower, label: "Lower Right")
            }
        }
    }

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

    @ViewBuilder
    private func zoneButton(site: PeptideInjectionSite, label: String) -> some View {
        let isSelected = selectedSite == site.rawValue
        let isRecommended = recommendedSite == site.rawValue
        let isLastUsed = lastUsedSite == site.rawValue

        Button {
            selectedSite = site.rawValue
            HapticManager.mediumImpact()
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
        VisualBodySilhouette(
            injectionType: .subcutaneous,
            selectedSite: .constant("left_belly_upper"),
            lastUsedSite: "right_belly_lower",
            recommendedSite: "delt_left"
        )
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("PED Sites") {
    ScrollView {
        VisualBodySilhouette(
            injectionType: .intramuscular,
            selectedSite: .constant("glute_left_upper"),
            lastUsedSite: "delt_right",
            recommendedSite: "glute_right_upper"
        )
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
}
