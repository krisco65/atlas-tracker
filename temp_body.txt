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
        // Head = 1/8, Torso = 3/8, Legs = 4/8
        let headHeight = h * 0.10
        let headWidth = w * 0.14
        let neckWidth = w * 0.08
        let shoulderWidth = w * 0.42
        let chestWidth = w * 0.36
        let waistWidth = w * 0.28
        let hipWidth = w * 0.34
        let thighWidth = w * 0.14
        let calfWidth = w * 0.10
        let footWidth = w * 0.10

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
        let headCenterY = headTop + headHeight / 2
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

        // Shoulder to elbow (outer arm)
        bodyPath.addQuadCurve(
            to: CGPoint(x: leftArmOuterX - w * 0.02, y: elbowY),
            control: CGPoint(x: leftArmOuterX, y: (armPitY + elbowY) / 2)
        )

        // Elbow to wrist (forearm)
        bodyPath.addQuadCurve(
            to: CGPoint(x: leftArmOuterX + w * 0.01, y: wristY),
            control: CGPoint(x: leftArmOuterX - w * 0.01, y: (elbowY + wristY) / 2)
        )

        // Hand
        bodyPath.addQuadCurve(
            to: CGPoint(x: leftArmOuterX + w * 0.03, y: handY),
            control: CGPoint(x: leftArmOuterX - w * 0.01, y: handY - h * 0.01)
        )

        // Hand bottom curve
        bodyPath.addQuadCurve(
            to: CGPoint(x: leftArmOuterX + w * 0.08, y: handY - h * 0.01),
            control: CGPoint(x: leftArmOuterX + w * 0.06, y: handY + h * 0.015)
        )

        // Inner wrist back up
        bodyPath.addQuadCurve(
            to: CGPoint(x: leftArmInnerX + w * 0.04, y: wristY - h * 0.02),
            control: CGPoint(x: leftArmOuterX + w * 0.08, y: wristY)
        )

        // Forearm inner to elbow
        bodyPath.addQuadCurve(
            to: CGPoint(x: leftArmInnerX + w * 0.02, y: elbowY + h * 0.01),
            control: CGPoint(x: leftArmInnerX + w * 0.05, y: (wristY + elbowY) / 2)
        )

        // Elbow to armpit (inner arm)
        bodyPath.addQuadCurve(
            to: CGPoint(x: leftArmInnerX, y: armPitY + h * 0.02),
            control: CGPoint(x: leftArmInnerX, y: (armPitY + elbowY) / 2)
        )

        // === LEFT SIDE OF TORSO ===
        // Armpit to waist
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX - waistWidth / 2, y: waistY),
            control: CGPoint(x: centerX - chestWidth / 2, y: (armPitY + waistY) / 2)
        )

        // Waist to hip
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX - hipWidth / 2, y: hipY),
            control: CGPoint(x: centerX - waistWidth / 2 - w * 0.02, y: (waistY + hipY) / 2)
        )

        // === LEFT LEG ===
        // Hip to inner thigh (crotch area)
        bodyPath.addLine(to: CGPoint(x: centerX - w * 0.06, y: crotchY))

        // Inner left thigh down to knee
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX - w * 0.07, y: kneeY),
            control: CGPoint(x: centerX - w * 0.05, y: (crotchY + kneeY) / 2)
        )

        // Inner calf to ankle
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX - w * 0.06, y: ankleY),
            control: CGPoint(x: centerX - w * 0.055, y: (kneeY + ankleY) / 2)
        )

        // Left foot
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX - w * 0.10, y: footBottom),
            control: CGPoint(x: centerX - w * 0.08, y: ankleY + h * 0.03)
        )

        bodyPath.addLine(to: CGPoint(x: centerX - w * 0.18, y: footBottom))

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX - thighWidth / 2 - w * 0.04, y: ankleY),
            control: CGPoint(x: centerX - w * 0.20, y: footBottom - h * 0.02)
        )

        // Outer calf up to knee
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX - thighWidth / 2 - w * 0.03, y: kneeY),
            control: CGPoint(x: centerX - calfWidth / 2 - w * 0.08, y: (ankleY + kneeY) / 2)
        )

        // Outer thigh up to hip
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX - hipWidth / 2, y: hipY),
            control: CGPoint(x: centerX - thighWidth / 2 - w * 0.06, y: (hipY + kneeY) / 2)
        )

        // === CROSS TO RIGHT LEG ===
        // Right hip
        bodyPath.addLine(to: CGPoint(x: centerX + hipWidth / 2, y: hipY))

        // Outer right thigh to knee
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + thighWidth / 2 + w * 0.03, y: kneeY),
            control: CGPoint(x: centerX + thighWidth / 2 + w * 0.06, y: (hipY + kneeY) / 2)
        )

        // Outer calf to ankle
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + thighWidth / 2 + w * 0.04, y: ankleY),
            control: CGPoint(x: centerX + calfWidth / 2 + w * 0.08, y: (kneeY + ankleY) / 2)
        )

        // Right foot
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + w * 0.18, y: footBottom),
            control: CGPoint(x: centerX + w * 0.20, y: footBottom - h * 0.02)
        )

        bodyPath.addLine(to: CGPoint(x: centerX + w * 0.10, y: footBottom))

        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + w * 0.06, y: ankleY),
            control: CGPoint(x: centerX + w * 0.08, y: ankleY + h * 0.03)
        )

        // Inner calf up
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + w * 0.07, y: kneeY),
            control: CGPoint(x: centerX + w * 0.055, y: (ankleY + kneeY) / 2)
        )

        // Inner thigh up to crotch
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + w * 0.06, y: crotchY),
            control: CGPoint(x: centerX + w * 0.05, y: (kneeY + crotchY) / 2)
        )

        // === RIGHT SIDE OF TORSO ===
        // Hip up
        bodyPath.addLine(to: CGPoint(x: centerX + hipWidth / 2, y: hipY))

        // Hip to waist
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + waistWidth / 2, y: waistY),
            control: CGPoint(x: centerX + waistWidth / 2 + w * 0.02, y: (waistY + hipY) / 2)
        )

        // Waist to armpit
        let rightArmInnerX = centerX + chestWidth / 2 + w * 0.02
        bodyPath.addQuadCurve(
            to: CGPoint(x: rightArmInnerX, y: armPitY + h * 0.02),
            control: CGPoint(x: centerX + chestWidth / 2, y: (armPitY + waistY) / 2)
        )

        // === RIGHT ARM ===
        let rightArmOuterX = centerX + shoulderWidth / 2 + w * 0.06

        // Inner arm: armpit to elbow
        bodyPath.addQuadCurve(
            to: CGPoint(x: rightArmInnerX - w * 0.02, y: elbowY + h * 0.01),
            control: CGPoint(x: rightArmInnerX, y: (armPitY + elbowY) / 2)
        )

        // Inner forearm to wrist
        bodyPath.addQuadCurve(
            to: CGPoint(x: rightArmInnerX - w * 0.04, y: wristY - h * 0.02),
            control: CGPoint(x: rightArmInnerX - w * 0.05, y: (wristY + elbowY) / 2)
        )

        // Hand inner
        bodyPath.addQuadCurve(
            to: CGPoint(x: rightArmOuterX - w * 0.08, y: handY - h * 0.01),
            control: CGPoint(x: rightArmOuterX - w * 0.08, y: wristY)
        )

        // Hand bottom
        bodyPath.addQuadCurve(
            to: CGPoint(x: rightArmOuterX - w * 0.03, y: handY),
            control: CGPoint(x: rightArmOuterX - w * 0.06, y: handY + h * 0.015)
        )

        // Hand outer to wrist
        bodyPath.addQuadCurve(
            to: CGPoint(x: rightArmOuterX - w * 0.01, y: wristY),
            control: CGPoint(x: rightArmOuterX + w * 0.01, y: handY - h * 0.01)
        )

        // Forearm outer to elbow
        bodyPath.addQuadCurve(
            to: CGPoint(x: rightArmOuterX + w * 0.02, y: elbowY),
            control: CGPoint(x: rightArmOuterX + w * 0.01, y: (elbowY + wristY) / 2)
        )

        // Upper arm outer to shoulder
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + chestWidth / 2 + w * 0.02, y: armPitY),
            control: CGPoint(x: rightArmOuterX, y: (armPitY + elbowY) / 2)
        )

        // Armpit to shoulder
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + shoulderWidth / 2, y: shoulderY),
            control: CGPoint(x: centerX + shoulderWidth / 2, y: armPitY - h * 0.02)
        )

        // Right shoulder to neck
        bodyPath.addQuadCurve(
            to: CGPoint(x: centerX + neckWidth / 2, y: headBottom),
            control: CGPoint(x: centerX + shoulderWidth / 3, y: neckBottom)
        )

        // Close neck
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
            // Subtle outer glow
            if showGlow {
                ProfessionalBodyShape()
                    .fill(Color.accentPrimary.opacity(0.08))
                    .blur(radius: 20)
            }

            // Main body fill with gradient
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

            // Subtle outline
            ProfessionalBodyShape()
                .stroke(strokeColor, lineWidth: 1.5)
        }
    }
}

// MARK: - Preview
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

#Preview("With Injection Sites") {
    ZStack {
        Color.black.ignoresSafeArea()

        GeometryReader { geo in
            let width: CGFloat = 200
            let height: CGFloat = 440
            let offsetX = (geo.size.width - width) / 2
            let offsetY = (geo.size.height - height) / 2

            ZStack {
                BodySilhouetteView()
                    .frame(width: width, height: height)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                // Sample injection site markers
                let sites: [(String, CGFloat, CGFloat)] = [
                    ("Belly", 0.38, 0.38),
                    ("Belly", 0.62, 0.38),
                    ("Side", 0.22, 0.38),
                    ("Side", 0.78, 0.38),
                    ("Glute", 0.32, 0.50),
                    ("Glute", 0.68, 0.50),
                    ("Thigh", 0.36, 0.68),
                    ("Thigh", 0.64, 0.68),
                ]

                ForEach(sites.indices, id: \.self) { i in
                    let site = sites[i]
                    VStack(spacing: 2) {
                        Circle()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                            )
                        Text(site.0)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .position(
                        x: offsetX + width * site.1,
                        y: offsetY + height * site.2
                    )
                }
            }
        }
    }
    .preferredColorScheme(.dark)
}
