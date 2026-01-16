import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String = "Search"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)

            TextField(placeholder, text: $text)
                .foregroundColor(.textPrimary)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(12)
        .background(Color.backgroundSecondary)
        .cornerRadius(10)
    }
}

#Preview {
    VStack {
        SearchBarView(text: .constant(""), placeholder: "Search compounds...")
        SearchBarView(text: .constant("Vitamin"), placeholder: "Search compounds...")
    }
    .padding()
    .background(Color.backgroundPrimary)
}
