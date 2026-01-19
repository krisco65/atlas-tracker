import SwiftUI

// MARK: - Professional Body Silhouette Shape
/// Clean, medical-app style human silhouette
/// Optimized for clarity at all sizes
struct ProfessionalBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.width
        let h = rect.height
        let centerX = w * 0.5

        // === HEAD ===
        let headWidth = w * 0.18
        let headHeight = h * 0.11
        let headTop = h * 0.01

        path.addEllipse(in: CGRect(
            x: centerX - headWidth / 2,
            y: headTop,
            width: headWidth,
            height: headHeight
        ))

        // === NECK ===
        let neckTop = headTop + headHeight - h * 0.01
        let neckWidth = w * 0.10

        path.addRect(CGRect(
            x: centerX - neckWidth / 2,
            y: neckTop,
            width: neckWidth,
            height: h * 0.04
        ))

        // === TORSO (shoulders to hips) ===
        var torso = Path()

        let shoulderY = neckTop + h * 0.03
        let shoulderWidth = w * 0.50
        let chestY = shoulderY + h * 0.08
        let waistY = h * 0.42
        let waistWidth = w * 0.32
        let hipY = h * 0.50
        let hipWidth = w * 0.38

        // Start at left shoulder
        torso.move(to: CGPoint(x: centerX - shoulderWidth / 2, y: shoulderY))

        // Left shoulder curve
        torso.addQuadCurve(
            to: CGPoint(x: centerX - shoulderWidth / 2 - w * 0.02, y: chestY),
            control: CGPoint(x: centerX - shoulderWidth / 2, y: shoulderY + h * 0.04)
        )

        // Left arm (simplified - slight outward bulge)
        torso.addQuadCurve(
            to: CGPoint(x: centerX - waistWidth / 2 - w * 0.04, y: waistY - h * 0.05),
            control: CGPoint(x: centerX - shoulderWidth / 2, y: (chestY + waistY) / 2)
        )

        // Left waist curve
        torso.addQuadCurve(
            to: CGPoint(x: centerX - waistWidth / 2, y: waistY),
            control: CGPoint(x: centerX - waistWidth / 2 - w * 0.02, y: waistY - h * 0.02)
        )

        // Left hip curve
        torso.addQuadCurve(
            to: CGPoint(x: centerX - hipWidth / 2, y: hipY),
            control: CGPoint(x: centerX - hipWidth / 2 - w * 0.02, y: (waistY + hipY) / 2)
        )

        // Bottom of torso (straight line across hips)
        torso.addLine(to: CGPoint(x: centerX + hipWidth / 2, y: hipY))

        // Right hip curve
        torso.addQuadCurve(
            to: CGPoint(x: centerX + waistWidth / 2, y: waistY),
            control: CGPoint(x: centerX + hipWidth / 2 + w * 0.02, y: (waistY + hipY) / 2)
        )

        // Right waist curve
        torso.addQuadCurve(
            to: CGPoint(x: centerX + waistWidth / 2 + w * 0.04, y: waistY - h * 0.05),
            control: CGPoint(x: centerX + waistWidth / 2 + w * 0.02, y: waistY - h * 0.02)
        )

        // Right arm (simplified)
        torso.addQuadCurve(
            to: CGPoint(x: centerX + shoulderWidth / 2 + w * 0.02, y: chestY),
            control: CGPoint(x: centerX + shoulderWidth / 2, y: (chestY + waistY) / 2)
        )

        // Right shoulder curve
        torso.addQuadCurve(
            to: CGPoint(x: centerX + shoulderWidth / 2, y: shoulderY),
            control: CGPoint(x: centerX + shoulderWidth / 2, y: shoulderY + h * 0.04)
        )

        torso.closeSubpath()
        path.addPath(torso)

        // === LEFT LEG ===
        let legTop = hipY - h * 0.01
        let legWidth = w * 0.14
        let legGap = w * 0.03
        let kneeY = h * 0.72
        let ankleY = h * 0.92
        let footY = h * 0.98

        var leftLeg = Path()
        leftLeg.move(to: CGPoint(x: centerX - legGap, y: legTop))

        // Outer thigh
        leftLeg.addQuadCurve(
            to: CGPoint(x: centerX - legGap - legWidth * 0.6, y: kneeY),
            control: CGPoint(x: centerX - legGap - legWidth * 0.7, y: (legTop + kneeY) / 2)
        )

        // Outer calf
        leftLeg.addQuadCurve(
            to: CGPoint(x: centerX - legGap - legWidth * 0.4, y: ankleY),
            control: CGPoint(x: centerX - legGap - legWidth * 0.5, y: (kneeY + ankleY) / 2)
        )

        // Foot
        leftLeg.addLine(to: CGPoint(x: centerX - legGap - legWidth * 0.6, y: footY))
        leftLeg.addLine(to: CGPoint(x: centerX - legGap + legWidth * 0.1, y: footY))

        // Inner ankle
        leftLeg.addLine(to: CGPoint(x: centerX - legGap + legWidth * 0.1, y: ankleY))

        // Inner calf
        leftLeg.addQuadCurve(
            to: CGPoint(x: centerX - legGap + legWidth * 0.15, y: kneeY),
            control: CGPoint(x: centerX - legGap + legWidth * 0.1, y: (kneeY + ankleY) / 2)
        )

        // Inner thigh
        leftLeg.addQuadCurve(
            to: CGPoint(x: centerX - legGap, y: legTop),
            control: CGPoint(x: centerX - legGap + legWidth * 0.2, y: (legTop + kneeY) / 2)
        )

        leftLeg.closeSubpath()
        path.addPath(leftLeg)

        // === RIGHT LEG ===
        var rightLeg = Path()
        rightLeg.move(to: CGPoint(x: centerX + legGap, y: legTop))

        // Inner thigh
        rightLeg.addQuadCurve(
            to: CGPoint(x: centerX + legGap - legWidth * 0.15, y: kneeY),
            control: CGPoint(x: centerX + legGap - legWidth * 0.2, y: (legTop + kneeY) / 2)
        )

        // Inner calf
        rightLeg.addQuadCurve(
            to: CGPoint(x: centerX + legGap - legWidth * 0.1, y: ankleY),
            control: CGPoint(x: centerX + legGap - legWidth * 0.1, y: (kneeY + ankleY) / 2)
        )

        // Foot
        rightLeg.addLine(to: CGPoint(x: centerX + legGap - legWidth * 0.1, y: footY))
        rightLeg.addLine(to: CGPoint(x: centerX + legGap + legWidth * 0.6, y: footY))

        // Outer ankle
        rightLeg.addLine(to: CGPoint(x: centerX + legGap + legWidth * 0.4, y: ankleY))

        // Outer calf
        rightLeg.addQuadCurve(
            to: CGPoint(x: centerX + legGap + legWidth * 0.6, y: kneeY),
            control: CGPoint(x: centerX + legGap + legWidth * 0.5, y: (kneeY + ankleY) / 2)
        )

        // Outer thigh
        rightLeg.addQuadCurve(
            to: CGPoint(x: centerX + legGap, y: legTop),
            control: CGPoint(x: centerX + legGap + legWidth * 0.7, y: (legTop + kneeY) / 2)
        )

        rightLeg.closeSubpath()
        path.addPath(rightLeg)

        return path
    }
}

#Preview("Body Shape") {
    VStack(spacing: 20) {
        Text("Professional Body Silhouette")
            .font(.headline)
            .foregroundColor(.white)

        ProfessionalBodyShape()
            .fill(Color(white: 0.25))
            .frame(width: 180, height: 400)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
