import SwiftUI

// MARK: - Professional Body Silhouette Shape
/// Anatomically proportioned human body silhouette using SwiftUI Paths
/// Based on classical 8-head proportion model for realistic human figure
struct ProfessionalBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.width
        let h = rect.height

        // Proportions based on 8-head model
        let headHeight = h * 0.10
        let headWidth = w * 0.14
        let neckWidth = w * 0.08
        let shoulderWidth = w * 0.42
        let chestWidth = w * 0.36
        let waistWidth = w * 0.28
        let hipWidth = w * 0.34
        let thighWidth = w * 0.14
        let calfWidth = w * 0.10

        let centerX = w * 0.5

        // Vertical positions
        let headTop = h * 0.02
        let headBottom = headTop + headHeight
        let neckBottom = headBottom + h * 0.025
        let shoulderY = neckBottom + h * 0.01
        let armPitY = shoulderY + h * 0.05
        let elbowY = h * 0.38
        let wristY = h * 0.48
        let handY = h * 0.52
        let waistY = h * 0.40
        let hipY = h * 0.48
        let crotchY = h * 0.52
        let kneeY = h * 0.72
        let ankleY = h * 0.93
        let footBottom = h * 0.98

        // ===== HEAD =====
        path.addEllipse(in: CGRect(
            x: centerX - headWidth / 2,
            y: headTop,
            width: headWidth,
            height: headHeight
        ))

        // ===== BODY (Torso + Legs - single continuous path) =====
        var bodyPath = Path()

        // Start at left side of neck
        bodyPath.move(to: CGPoint(x: centerX - neckWidth / 2, y: headBottom))

        // Neck to left shoulder
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX - shoulderWidth / 2, y: shoulderY),
            control: CGPoint(x: centerX - shoulderWidth / 3, y: neckBottom)
        )

        // Left shoulder to armpit
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX - chestWidth / 2 - w * 0.02, y: armPitY),
            control: CGPoint(x: centerX - shoulderWidth / 2, y: armPitY - h * 0.02)
        )

        // === LEFT ARM ===
        let leftArmOuterX = centerX - shoulderWidth / 2 - w * 0.06
        let leftArmInnerX = centerX - chestWidth / 2 - w * 0.02

        bodyPath.addQuadCurve(
            to: CGPoint(x: leftArmOuterX - w * 0.02, y: elbowY),
            control: CGPoint(x: leftArmOuterX, y: (armPitY + elbowY) / 2)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: leftArmOuterX + w * 0.01, y: wristY),
            control: CGPoint(x: leftArmOuterX - w * 0.01, y: (elbowY + wristY) / 2)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: leftArmOuterX + w * 0.03, y: handY),
            control: CGPoint(x: leftArmOuterX - w * 0.01, y: handY - h * 0.01)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: leftArmOuterX + w * 0.08, y: handY - h * 0.01),
            control: CGPoint(x: leftArmOuterX + w * 0.06, y: handY + h * 0.015)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: leftArmInnerX + w * 0.04, y: wristY - h * 0.02),
            control: CGPoint(x: leftArmOuterX + w * 0.08, y: wristY)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: leftArmInnerX + w * 0.02, y: elbowY + h * 0.01),
            control: CGPoint(x: leftArmInnerX + w * 0.05, y: (wristY + elbowY) / 2)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: leftArmInnerX, y: armPitY + h * 0.02),
            control: CGPoint(x: leftArmInnerX, y: (armPitY + elbowY) / 2)
        )

        // === LEFT SIDE OF TORSO ===
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX - waistWidth / 2, y: waistY),
            control: CGPoint(x: centerX - chestWidth / 2, y: (armPitY + waistY) / 2)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX - hipWidth / 2, y: hipY),
            control: CGPoint(x: centerX - waistWidth / 2 - w * 0.02, y: (waistY + hipY) / 2)
        )

        // === LEFT LEG ===
        bodyPath.addLine(to: CGPoint(x: centerX - w * 0.06, y: crotchY))

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX - w * 0.07, y: kneeY),
            control: CGPoint(x: centerX - w * 0.05, y: (crotchY + kneeY) / 2)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX - w * 0.06, y: ankleY),
            control: CGPoint(x: centerX - w * 0.055, y: (kneeY + ankleY) / 2)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX - w * 0.10, y: footBottom),
            control: CGPoint(x: centerX - w * 0.08, y: ankleY + h * 0.03)
        )

        bodyPath.addLine(to: CGPoint(x: centerX - w * 0.18, y: footBottom))

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX - thighWidth / 2 - w * 0.04, y: ankleY),
            control: CGPoint(x: centerX - w * 0.20, y: footBottom - h * 0.02)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX - thighWidth / 2 - w * 0.03, y: kneeY),
            control: CGPoint(x: centerX - calfWidth / 2 - w * 0.08, y: (ankleY + kneeY) / 2)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX - hipWidth / 2, y: hipY),
            control: CGPoint(x: centerX - thighWidth / 2 - w * 0.06, y: (hipY + kneeY) / 2)
        )

        // === CROSS TO RIGHT LEG ===
        bodyPath.addLine(to: CGPoint(x: centerX + hipWidth / 2, y: hipY))

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + thighWidth / 2 + w * 0.03, y: kneeY),
            control: CGPoint(x: centerX + thighWidth / 2 + w * 0.06, y: (hipY + kneeY) / 2)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + thighWidth / 2 + w * 0.04, y: ankleY),
            control: CGPoint(x: centerX + calfWidth / 2 + w * 0.08, y: (kneeY + ankleY) / 2)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + w * 0.18, y: footBottom),
            control: CGPoint(x: centerX + w * 0.20, y: footBottom - h * 0.02)
        )

        bodyPath.addLine(to: CGPoint(x: centerX + w * 0.10, y: footBottom))

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + w * 0.06, y: ankleY),
            control: CGPoint(x: centerX + w * 0.08, y: ankleY + h * 0.03)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + w * 0.07, y: kneeY),
            control: CGPoint(x: centerX + w * 0.055, y: (ankleY + kneeY) / 2)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + w * 0.06, y: crotchY),
            control: CGPoint(x: centerX + w * 0.05, y: (kneeY + crotchY) / 2)
        )

        // === RIGHT SIDE OF TORSO ===
        bodyPath.addLine(to: CGPoint(x: centerX + hipWidth / 2, y: hipY))

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + waistWidth / 2, y: waistY),
            control: CGPoint(x: centerX + waistWidth / 2 + w * 0.02, y: (waistY + hipY) / 2)
        )

        let rightArmInnerX = centerX + chestWidth / 2 + w * 0.02
        bodyPath.addQuadCurve(
            to: CGPoint(x: rightArmInnerX, y: armPitY + h * 0.02),
            control: CGPoint(x: centerX + chestWidth / 2, y: (armPitY + waistY) / 2)
        )

        // === RIGHT ARM ===
        let rightArmOuterX = centerX + shoulderWidth / 2 + w * 0.06

        bodyPath.addQuadCurve(
            to: CGPoint(x: rightArmInnerX - w * 0.02, y: elbowY + h * 0.01),
            control: CGPoint(x: rightArmInnerX, y: (armPitY + elbowY) / 2)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: rightArmInnerX - w * 0.04, y: wristY - h * 0.02),
            control: CGPoint(x: rightArmInnerX - w * 0.05, y: (wristY + elbowY) / 2)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: rightArmOuterX - w * 0.08, y: handY - h * 0.01),
            control: CGPoint(x: rightArmOuterX - w * 0.08, y: wristY)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: rightArmOuterX - w * 0.03, y: handY),
            control: CGPoint(x: rightArmOuterX - w * 0.06, y: handY + h * 0.015)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: rightArmOuterX - w * 0.01, y: wristY),
            control: CGPoint(x: rightArmOuterX + w * 0.01, y: handY - h * 0.01)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: rightArmOuterX + w * 0.02, y: elbowY),
            control: CGPoint(x: rightArmOuterX + w * 0.01, y: (elbowY + wristY) / 2)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + chestWidth / 2 + w * 0.02, y: armPitY),
            control: CGPoint(x: rightArmOuterX, y: (armPitY + elbowY) / 2)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + shoulderWidth / 2, y: shoulderY),
            control: CGPoint(x: centerX + shoulderWidth / 2, y: armPitY - h * 0.02)
        )

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + neckWidth / 2, y: headBottom),
            control: CGPoint(x: centerX + shoulderWidth / 3, y: neckBottom)
        )

        bodyPath.closeSubpath()

        path.addPath(bodyPath)

        return path
    }
}

// MARK: - Body Silhouette View
/// Professional body silhouette with gradient fill and subtle styling
struct BodySilhouetteView: View {
    var fillColor: Color = Color(white: 0.25)
    var strokeColor: Color = Color(white: 0.4)
    var showGlow: Bool = true

    var body: some View {
        ZStack {
            if showGlow {
                ProfessionalBodyShape()
                    .fill(Color.accentPrimary.opacity(0.08))
                    .blur(radius: 20)
            }

            ProfessionalBodyShape()
                .fill(
                    LinearGradient(
                        colors: [
                            fillColor.opacity(0.9),
                            fillColor.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            ProfessionalBodyShape()
                .stroke(strokeColor, lineWidth: 1.5)
        }
    }
}

#Preview("Body Shape") {
    VStack(spacing: 20) {
        Text("Professional Body Silhouette")
            .font(.headline)
            .foregroundColor(.white)

        BodySilhouetteView()
            .frame(width: 180, height: 400)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
