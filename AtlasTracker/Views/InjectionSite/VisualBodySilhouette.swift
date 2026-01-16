import SwiftUI

// MARK: - Visual Body Silhouette
/// Interactive body silhouette for injection site selection
struct VisualBodySilhouette: View {
    let injectionType: BodyDiagramView.InjectionType
    @Binding var selectedSite: String?
    let lastUsedSite: String?
    let recommendedSite: String?

    var body: some View {
        VStack(spacing: 16) {
            // Legend
            HStack(spacing: 16) {
                LegendDot(color: .accentPrimary, label: "Selected")
                LegendDot(color: .statusWarning, label: "Last Used")
                LegendDot(color: .statusSuccess, label: "Recommended")
            }
            .font(.caption)
            .padding(.horizontal)

            // Body Silhouette with tappable zones
            GeometryReader { geometry in
                ZStack {
                    // Body outline
                    BodyOutlineShape()
                        .stroke(Color.textTertiary.opacity(0.5), lineWidth: 2)
                        .background(
                            BodyOutlineShape()
                                .fill(Color.backgroundSecondary.opacity(0.3))
                        )

                    // Injection site buttons
                    if injectionType == .intramuscular {
                        ForEach(PEDInjectionSite.allCases, id: \.self) { site in
                            injectionSiteButton(
                                site: site.rawValue,
                                displayName: site.shortName,
                                position: site.bodyMapPosition,
                                geometry: geometry
                            )
                        }
                    } else {
                        ForEach(PeptideInjectionSite.allCases, id: \.self) { site in
                            injectionSiteButton(
                                site: site.rawValue,
                                displayName: site.shortName,
                                position: site.bodyMapPosition,
                                geometry: geometry
                            )
                        }
                    }

                    // Belly button indicator (for peptide view)
                    if injectionType == .subcutaneous {
                        Circle()
                            .fill(Color.textTertiary.opacity(0.5))
                            .frame(width: 8, height: 8)
                            .position(
                                x: geometry.size.width * 0.5,
                                y: geometry.size.height * 0.45
                            )
                    }
                }
            }
            .aspectRatio(0.45, contentMode: .fit)
            .frame(maxHeight: 400)

            // Selected site display
            if let selected = selectedSite {
                let displayName = getDisplayName(for: selected)
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentPrimary)
                    Text("Selected: \(displayName)")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                }
                .padding()
                .background(Color.accentPrimary.opacity(0.2))
                .cornerRadius(10)
            }
        }
        .padding()
    }

    // MARK: - Injection Site Button
    private func injectionSiteButton(
        site: String,
        displayName: String,
        position: (x: CGFloat, y: CGFloat),
        geometry: GeometryProxy
    ) -> some View {
        let isSelected = selectedSite == site
        let isLastUsed = lastUsedSite == site
        let isRecommended = recommendedSite == site

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectedSite = site
            }
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } label: {
            ZStack {
                // Glow effect for recommended
                if isRecommended && !isSelected {
                    Circle()
                        .fill(Color.statusSuccess.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .blur(radius: 8)
                }

                // Main button
                Circle()
                    .fill(buttonColor(isSelected: isSelected, isLastUsed: isLastUsed, isRecommended: isRecommended))
                    .frame(width: buttonSize(isSelected: isSelected), height: buttonSize(isSelected: isSelected))
                    .overlay(
                        Circle()
                            .stroke(borderColor(isSelected: isSelected, isLastUsed: isLastUsed, isRecommended: isRecommended), lineWidth: 2)
                    )
                    .shadow(color: isSelected ? .accentPrimary.opacity(0.5) : .clear, radius: 8)

                // Label
                Text(displayName)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(isSelected ? .white : .textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 40)
            }
        }
        .position(
            x: geometry.size.width * position.x,
            y: geometry.size.height * position.y
        )
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }

    private func buttonSize(isSelected: Bool) -> CGFloat {
        isSelected ? 44 : 36
    }

    private func buttonColor(isSelected: Bool, isLastUsed: Bool, isRecommended: Bool) -> Color {
        if isSelected {
            return .accentPrimary
        } else if isRecommended {
            return .statusSuccess.opacity(0.3)
        } else if isLastUsed {
            return .statusWarning.opacity(0.3)
        }
        return .backgroundTertiary
    }

    private func borderColor(isSelected: Bool, isLastUsed: Bool, isRecommended: Bool) -> Color {
        if isSelected {
            return .accentPrimary
        } else if isRecommended {
            return .statusSuccess
        } else if isLastUsed {
            return .statusWarning
        }
        return .textTertiary.opacity(0.3)
    }

    private func getDisplayName(for site: String) -> String {
        if injectionType == .intramuscular {
            return PEDInjectionSite(rawValue: site)?.displayName ?? site
        } else {
            return PeptideInjectionSite(rawValue: site)?.displayName ?? site
        }
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
                .frame(width: 10, height: 10)
            Text(label)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Body Outline Shape
struct BodyOutlineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Head
        let headCenterX = width * 0.5
        let headCenterY = height * 0.08
        let headRadius = width * 0.08
        path.addEllipse(in: CGRect(
            x: headCenterX - headRadius,
            y: headCenterY - headRadius,
            width: headRadius * 2,
            height: headRadius * 2.2
        ))

        // Neck
        path.move(to: CGPoint(x: width * 0.45, y: height * 0.12))
        path.addLine(to: CGPoint(x: width * 0.45, y: height * 0.15))
        path.move(to: CGPoint(x: width * 0.55, y: height * 0.12))
        path.addLine(to: CGPoint(x: width * 0.55, y: height * 0.15))

        // Torso outline
        path.move(to: CGPoint(x: width * 0.45, y: height * 0.15))

        // Left shoulder
        path.addQuadCurve(
            to: CGPoint(x: width * 0.1, y: height * 0.20),
            control: CGPoint(x: width * 0.3, y: height * 0.15)
        )

        // Left arm
        path.addLine(to: CGPoint(x: width * 0.05, y: height * 0.38))
        path.addQuadCurve(
            to: CGPoint(x: width * 0.12, y: height * 0.40),
            control: CGPoint(x: width * 0.03, y: height * 0.40)
        )
        path.addLine(to: CGPoint(x: width * 0.18, y: height * 0.25))

        // Left side of torso
        path.addQuadCurve(
            to: CGPoint(x: width * 0.22, y: height * 0.50),
            control: CGPoint(x: width * 0.18, y: height * 0.38)
        )

        // Left hip
        path.addQuadCurve(
            to: CGPoint(x: width * 0.28, y: height * 0.58),
            control: CGPoint(x: width * 0.22, y: height * 0.55)
        )

        // Left leg
        path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.85))
        path.addQuadCurve(
            to: CGPoint(x: width * 0.30, y: height * 0.95),
            control: CGPoint(x: width * 0.24, y: height * 0.92)
        )
        path.addQuadCurve(
            to: CGPoint(x: width * 0.38, y: height * 0.85),
            control: CGPoint(x: width * 0.36, y: height * 0.92)
        )
        path.addLine(to: CGPoint(x: width * 0.42, y: height * 0.58))

        // Crotch
        path.addQuadCurve(
            to: CGPoint(x: width * 0.58, y: height * 0.58),
            control: CGPoint(x: width * 0.50, y: height * 0.65)
        )

        // Right leg
        path.addLine(to: CGPoint(x: width * 0.62, y: height * 0.85))
        path.addQuadCurve(
            to: CGPoint(x: width * 0.70, y: height * 0.95),
            control: CGPoint(x: width * 0.64, y: height * 0.92)
        )
        path.addQuadCurve(
            to: CGPoint(x: width * 0.75, y: height * 0.85),
            control: CGPoint(x: width * 0.76, y: height * 0.92)
        )
        path.addLine(to: CGPoint(x: width * 0.72, y: height * 0.58))

        // Right hip
        path.addQuadCurve(
            to: CGPoint(x: width * 0.78, y: height * 0.50),
            control: CGPoint(x: width * 0.78, y: height * 0.55)
        )

        // Right side of torso
        path.addQuadCurve(
            to: CGPoint(x: width * 0.82, y: height * 0.25),
            control: CGPoint(x: width * 0.82, y: height * 0.38)
        )

        // Right arm
        path.addLine(to: CGPoint(x: width * 0.88, y: height * 0.40))
        path.addQuadCurve(
            to: CGPoint(x: width * 0.95, y: height * 0.38),
            control: CGPoint(x: width * 0.97, y: height * 0.40)
        )
        path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.20))

        // Right shoulder
        path.addQuadCurve(
            to: CGPoint(x: width * 0.55, y: height * 0.15),
            control: CGPoint(x: width * 0.7, y: height * 0.15)
        )

        path.closeSubpath()

        return path
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Peptide Sites (SubQ)")
            .font(.headline)
        VisualBodySilhouette(
            injectionType: .subcutaneous,
            selectedSite: .constant("left_belly_upper"),
            lastUsedSite: "right_belly_lower",
            recommendedSite: "left_love_handle_upper"
        )
        .frame(height: 450)
    }
    .background(Color.backgroundPrimary)
    .preferredColorScheme(.dark)
}
