import SwiftUI
import UIKit

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

extension View {
    // MARK: - Card Style Modifier
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
    }

    // MARK: - Elevated Card Style
    func elevatedCardStyle() -> some View {
        self
            .padding()
            .background(Color.backgroundTertiary)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }

    // MARK: - Primary Button Style
    func primaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentPrimary)
            .cornerRadius(12)
    }

    // MARK: - Secondary Button Style
    func secondaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.accentPrimary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.backgroundTertiary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentPrimary, lineWidth: 1)
            )
    }

    // MARK: - Hide Keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Keyboard Done Toolbar
    func keyboardDoneButton() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
                .foregroundColor(.accentPrimary)
            }
        }
    }

    // MARK: - Tap to Dismiss Keyboard
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            hideKeyboard()
        }
    }

    // MARK: - Scrollable with Tap to Dismiss
    func scrollDismissesKeyboard() -> some View {
        self.scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Conditional Modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Custom View Modifiers
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

extension View {
    func shake(trigger: Bool) -> some View {
        self.modifier(ShakeEffect(animatableData: trigger ? 1 : 0))
    }
}
