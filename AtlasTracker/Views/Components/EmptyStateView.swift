import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.textTertiary)

            Text(title)
                .font(.headline)
                .foregroundColor(.textPrimary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                Button(action: buttonAction) {
                    Text(buttonTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .padding(.top, 8)
            }
        }
        .padding(40)
    }
}

#Preview {
    VStack {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "Try adjusting your search or filters"
        )

        EmptyStateView(
            icon: "pills",
            title: "No Compounds Tracked",
            message: "Add compounds to start tracking your doses",
            buttonTitle: "Browse Library",
            buttonAction: {}
        )
    }
    .background(Color.backgroundPrimary)
}
