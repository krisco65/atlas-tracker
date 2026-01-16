import SwiftUI

// MARK: - Visual Body Silhouette
/// Professional body silhouette for injection site selection
/// Uses anatomically correct 8-head proportion system
struct VisualBodySilhouette: View {
    let injectionType: BodyDiagramView.InjectionType
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?

    var body: some View {
        VStack(spacing: 12) {
            // Legend - compact horizontal layout
            HStack(spacing: 20) {
                LegendDot(color: .accentPrimary, label: "Selected")
                LegendDot(color: .statusSuccess, label: "Recommended")
                LegendDot(color: .statusWarning, label: "Last Used")
            }
            .font(.caption2)

            // Body diagram with injection sites
            GeometryReader { geometry in
                let bodyWidth = min(geometry.size.width * 0.85, 280)
                let bodyHeight = bodyWidth * 2.4 // Proper human proportion ratio
                let offsetX = (geometry.size.width - bodyWidth) / 2
                let offsetY = (geometry.size.height - bodyHeight) / 2

                ZStack {
                    // Professional body silhouette
                    ProfessionalBodyShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.backgroundSecondary.opacity(0.8),
                                    Color.backgroundSecondary.opacity(0.4)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: bodyWidth, height: bodyHeight)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                    // Body outline
                    ProfessionalBodyShape()
                        .stroke(
                            LinearGradient(
                                colors: [Color.textTertiary.opacity(0.6), Color.textTertiary.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: bodyWidth, height: bodyHeight)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                    // Injection site markers
                    if injectionType == .intramuscular {
                        ForEach(PEDInjectionSite.allCases, id: \.self) { site in
                            InjectionSiteMarker(
                                site: site.rawValue,
                                label: site.shortName,
                                position: calculatePosition(
                                    for: site.bodyMapPosition,
                                    bodyWidth: bodyWidth,
                                    bodyHeight: bodyHeight,
                                    offsetX: offsetX,
                                    offsetY: offsetY
                                ),
                                isSelected: selectedSite == site.rawValue,
                                isLastUsed: lastUsedSite == site.rawValue,
                                isRecommended: recommendedSite == site.rawValue
                            ) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    selectedSite = site.rawValue
                                }
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                        }
                    } else {
                        ForEach(PeptideInjectionSite.allCases, id: \.self) { site in
                            InjectionSiteMarker(
                                site: site.rawValue,
                                label: site.shortName,
                                position: calculatePosition(
                                    for: site.bodyMapPosition,
                                    bodyWidth: bodyWidth,
                                    bodyHeight: bodyHeight,
                                    offsetX: offsetX,
                                    offsetY: offsetY
                                ),
                                isSelected: selectedSite == site.rawValue,
                                isLastUsed: lastUsedSite == site.rawValue,
                                isRecommended: recommendedSite == site.rawValue
                            ) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    selectedSite = site.rawValue
                                }
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                        }
                    }
                }
            }
            .frame(height: 380)

            // Selected site display
            if let selected = selectedSite {
                let displayName = getDisplayName(for: selected)
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentPrimary)
                    Text(displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.accentPrimary.opacity(0.15))
                .cornerRadius(20)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }

    private func calculatePosition(
        for relativePos: (x: CGFloat, y: CGFloat),
        bodyWidth: CGFloat,
        bodyHeight: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat
    ) -> CGPoint {
        CGPoint(
            x: offsetX + bodyWidth * relativePos.x,
            y: offsetY + bodyHeight * relativePos.y
        )
    }

    private func getDisplayName(for site: String) -> String {
        if injectionType == .intramuscular {
            return PEDInjectionSite(rawValue: site)?.displayName ?? site
        } else {
            return PeptideInjectionSite(rawValue: site)?.displayName ?? site
        }
    }
}

// MARK: - Injection Site Marker
struct InjectionSiteMarker: View {
    let site: String
    let label: String
    let position: CGPoint
    let isSelected: Bool
    let isLastUsed: Bool
    let isRecommended: Bool
    let onTap: () -> Void

    private var markerColor: Color {
        if isSelected { return .accentPrimary }
        if isRecommended { return .statusSuccess }
        if isLastUsed { return .statusWarning }
        return .textTertiary.opacity(0.6)
    }

    private var backgroundColor: Color {
        if isSelected { return .accentPrimary }
        if isRecommended { return .statusSuccess.opacity(0.25) }
        if isLastUsed { return .statusWarning.opacity(0.25) }
        return .backgroundTertiary.opacity(0.8)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Glow effect for recommended
                if isRecommended && !isSelected {
                    Circle()
                        .fill(Color.statusSuccess.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .blur(radius: 6)
                }

                // Main marker
                Circle()
                    .fill(backgroundColor)
                    .frame(width: isSelected ? 36 : 32, height: isSelected ? 36 : 32)
                    .overlay(
                        Circle()
                            .stroke(markerColor, lineWidth: isSelected ? 2.5 : 1.5)
                    )
                    .shadow(color: isSelected ? .accentPrimary.opacity(0.4) : .clear, radius: 6)

                // Label
                Text(label)
                    .font(.system(size: 7, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 30)
            }
        }
        .buttonStyle(.plain)
        .position(position)
        .scaleEffect(isSelected ? 1.15 : 1.0)
    }
}

// MARK: - Legend Dot
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

// MARK: - Professional Body Shape
/// Anatomically proportioned human silhouette using the classical 8-head system
struct ProfessionalBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Proportions based on classical 8-head figure
        // Head unit = h / 8
        let headUnit = h / 8

        // Key measurements
        let centerX = w / 2
        let shoulderWidth = w * 0.46
        let waistWidth = w * 0.30
        let hipWidth = w * 0.38
        let neckWidth = w * 0.12

        // Vertical positions (from top)
        let headTop: CGFloat = 0
        let headBottom = headUnit * 1.0
        let neckBottom = headUnit * 1.25
        let shoulderY = headUnit * 1.5
        let chestY = headUnit * 2.2
        let waistY = headUnit * 3.2
        let hipY = headUnit * 4.0
        let crotchY = headUnit * 4.3
        let kneeY = headUnit * 6.0
        let ankleY = headUnit * 7.6
        let footY = h

        // HEAD - Oval shape
        let headCenterY = headUnit * 0.5
        let headRadiusX = w * 0.11
        let headRadiusY = headUnit * 0.48

        path.addEllipse(in: CGRect(
            x: centerX - headRadiusX,
            y: headTop + headUnit * 0.04,
            width: headRadiusX * 2,
            height: headRadiusY * 2
        ))

        // BODY - Start from left neck
        path.move(to: CGPoint(x: centerX - neckWidth / 2, y: headBottom))

        // Left side of neck
        path.addLine(to: CGPoint(x: centerX - neckWidth / 2, y: neckBottom))

        // Left shoulder curve
        path.addQuadCurve(
            to: CGPoint(x: centerX - shoulderWidth / 2, y: shoulderY),
            control: CGPoint(x: centerX - shoulderWidth / 2.5, y: neckBottom)
        )

        // Left arm - upper
        path.addQuadCurve(
            to: CGPoint(x: centerX - shoulderWidth / 2 - w * 0.06, y: chestY + headUnit * 0.3),
            control: CGPoint(x: centerX - shoulderWidth / 2 - w * 0.02, y: shoulderY + headUnit * 0.4)
        )

        // Left arm - forearm
        path.addQuadCurve(
            to: CGPoint(x: centerX - shoulderWidth / 2 - w * 0.08, y: waistY + headUnit * 0.2),
            control: CGPoint(x: centerX - shoulderWidth / 2 - w * 0.08, y: chestY + headUnit * 0.6)
        )

        // Left hand
        path.addQuadCurve(
            to: CGPoint(x: centerX - shoulderWidth / 2 - w * 0.04, y: waistY + headUnit * 0.5),
            control: CGPoint(x: centerX - shoulderWidth / 2 - w * 0.10, y: waistY + headUnit * 0.35)
        )

        // Inner left arm back to torso
        path.addQuadCurve(
            to: CGPoint(x: centerX - waistWidth / 2 - w * 0.04, y: chestY + headUnit * 0.2),
            control: CGPoint(x: centerX - shoulderWidth / 2 - w * 0.02, y: waistY)
        )

        // Left torso - chest to waist
        path.addQuadCurve(
            to: CGPoint(x: centerX - waistWidth / 2, y: waistY),
            control: CGPoint(x: centerX - waistWidth / 2 - w * 0.02, y: chestY + headUnit * 0.8)
        )

        // Left hip curve
        path.addQuadCurve(
            to: CGPoint(x: centerX - hipWidth / 2, y: hipY),
            control: CGPoint(x: centerX - hipWidth / 2, y: waistY + headUnit * 0.4)
        )

        // Left leg - outer thigh
        path.addQuadCurve(
            to: CGPoint(x: centerX - w * 0.14, y: kneeY),
            control: CGPoint(x: centerX - hipWidth / 2 + w * 0.02, y: crotchY + headUnit * 0.8)
        )

        // Left leg - outer calf
        path.addQuadCurve(
            to: CGPoint(x: centerX - w * 0.11, y: ankleY),
            control: CGPoint(x: centerX - w * 0.15, y: kneeY + headUnit * 0.8)
        )

        // Left foot
        path.addQuadCurve(
            to: CGPoint(x: centerX - w * 0.06, y: footY),
            control: CGPoint(x: centerX - w * 0.13, y: ankleY + headUnit * 0.2)
        )

        // Inner left leg - foot to crotch
        path.addLine(to: CGPoint(x: centerX - w * 0.02, y: footY))

        path.addQuadCurve(
            to: CGPoint(x: centerX - w * 0.06, y: ankleY),
            control: CGPoint(x: centerX - w * 0.04, y: ankleY + headUnit * 0.1)
        )

        path.addQuadCurve(
            to: CGPoint(x: centerX - w * 0.05, y: kneeY),
            control: CGPoint(x: centerX - w * 0.07, y: kneeY + headUnit * 0.6)
        )

        path.addQuadCurve(
            to: CGPoint(x: centerX - w * 0.02, y: crotchY),
            control: CGPoint(x: centerX - w * 0.06, y: crotchY + headUnit * 0.5)
        )

        // Crotch curve
        path.addQuadCurve(
            to: CGPoint(x: centerX + w * 0.02, y: crotchY),
            control: CGPoint(x: centerX, y: crotchY + headUnit * 0.15)
        )

        // Inner right leg - crotch to foot
        path.addQuadCurve(
            to: CGPoint(x: centerX + w * 0.05, y: kneeY),
            control: CGPoint(x: centerX + w * 0.06, y: crotchY + headUnit * 0.5)
        )

        path.addQuadCurve(
            to: CGPoint(x: centerX + w * 0.06, y: ankleY),
            control: CGPoint(x: centerX + w * 0.07, y: kneeY + headUnit * 0.6)
        )

        path.addQuadCurve(
            to: CGPoint(x: centerX + w * 0.02, y: footY),
            control: CGPoint(x: centerX + w * 0.04, y: ankleY + headUnit * 0.1)
        )

        // Right foot
        path.addLine(to: CGPoint(x: centerX + w * 0.06, y: footY))

        path.addQuadCurve(
            to: CGPoint(x: centerX + w * 0.11, y: ankleY),
            control: CGPoint(x: centerX + w * 0.13, y: ankleY + headUnit * 0.2)
        )

        // Right leg - outer calf
        path.addQuadCurve(
            to: CGPoint(x: centerX + w * 0.14, y: kneeY),
            control: CGPoint(x: centerX + w * 0.15, y: kneeY + headUnit * 0.8)
        )

        // Right leg - outer thigh
        path.addQuadCurve(
            to: CGPoint(x: centerX + hipWidth / 2, y: hipY),
            control: CGPoint(x: centerX + hipWidth / 2 - w * 0.02, y: crotchY + headUnit * 0.8)
        )

        // Right hip curve
        path.addQuadCurve(
            to: CGPoint(x: centerX + waistWidth / 2, y: waistY),
            control: CGPoint(x: centerX + hipWidth / 2, y: waistY + headUnit * 0.4)
        )

        // Right torso - waist to chest
        path.addQuadCurve(
            to: CGPoint(x: centerX + waistWidth / 2 + w * 0.04, y: chestY + headUnit * 0.2),
            control: CGPoint(x: centerX + waistWidth / 2 + w * 0.02, y: chestY + headUnit * 0.8)
        )

        // Inner right arm from torso
        path.addQuadCurve(
            to: CGPoint(x: centerX + shoulderWidth / 2 + w * 0.04, y: waistY + headUnit * 0.5),
            control: CGPoint(x: centerX + shoulderWidth / 2 + w * 0.02, y: waistY)
        )

        // Right hand
        path.addQuadCurve(
            to: CGPoint(x: centerX + shoulderWidth / 2 + w * 0.08, y: waistY + headUnit * 0.2),
            control: CGPoint(x: centerX + shoulderWidth / 2 + w * 0.10, y: waistY + headUnit * 0.35)
        )

        // Right arm - forearm
        path.addQuadCurve(
            to: CGPoint(x: centerX + shoulderWidth / 2 + w * 0.06, y: chestY + headUnit * 0.3),
            control: CGPoint(x: centerX + shoulderWidth / 2 + w * 0.08, y: chestY + headUnit * 0.6)
        )

        // Right arm - upper
        path.addQuadCurve(
            to: CGPoint(x: centerX + shoulderWidth / 2, y: shoulderY),
            control: CGPoint(x: centerX + shoulderWidth / 2 + w * 0.02, y: shoulderY + headUnit * 0.4)
        )

        // Right shoulder curve
        path.addQuadCurve(
            to: CGPoint(x: centerX + neckWidth / 2, y: neckBottom),
            control: CGPoint(x: centerX + shoulderWidth / 2.5, y: neckBottom)
        )

        // Right side of neck
        path.addLine(to: CGPoint(x: centerX + neckWidth / 2, y: headBottom))

        path.closeSubpath()

        return path
    }
}

#Preview("Peptide Sites") {
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
    .background(Color.backgroundPrimary)
    .preferredColorScheme(.dark)
}

#Preview("PED Sites") {
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
    .background(Color.backgroundPrimary)
    .preferredColorScheme(.dark)
}
