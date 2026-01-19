import SwiftUI

struct ActiveCompoundsSheet: View {
    let trackedCompounds: [TrackedCompound]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // PROMINENT CLOSE BUTTON HEADER
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                            Text("Close")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.accentPrimary)
                    }

                    Spacer()

                    Text("Active Compounds")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    // Invisible spacer for centering
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.clear)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color.backgroundSecondary)

                if trackedCompounds.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "pills",
                        title: "No Active Compounds",
                        message: "Start tracking compounds in the Library"
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(trackedCompounds, id: \.id) { tracked in
                                ActiveCompoundRow(tracked: tracked)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

struct ActiveCompoundRow: View {
    let tracked: TrackedCompound

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tracked.compound?.category.icon ?? "pills")
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(tracked.compound?.category.color ?? .accentPrimary)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(tracked.compound?.name ?? "Unknown")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Text(tracked.dosageString)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)

                Text(tracked.scheduleDisplayString)
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }

            Spacer()

            if tracked.notificationEnabled {
                Image(systemName: "bell.fill")
                    .foregroundColor(.accentPrimary)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}
