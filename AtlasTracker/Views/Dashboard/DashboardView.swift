import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedTracked: TrackedCompound?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Progress Card
                        if viewModel.hasDosesToday {
                            todayProgressCard
                        }

                        // Today's Doses
                        todaysDosesSection

                        // Low Stock Alerts
                        if viewModel.hasLowStock {
                            lowStockSection
                        }

                        // Quick Stats
                        quickStatsCard

                        // Recent Activity
                        if !viewModel.recentLogs.isEmpty {
                            recentActivitySection
                        }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.loadData()
            }
            .onAppear {
                viewModel.loadData()
            }
            .sheet(item: $selectedTracked) { tracked in
                if let compound = tracked.compound {
                    QuickLogSheet(compound: compound, tracked: tracked) {
                        viewModel.loadData()
                    }
                }
            }
        }
    }

    // MARK: - Today Progress Card
    private var todayProgressCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Progress")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(viewModel.todaysCompletedCount)/\(viewModel.todaysTotalCount)")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.backgroundTertiary)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentSecondary)
                        .frame(width: geometry.size.width * viewModel.todaysProgressPercentage, height: 8)
                }
            }
            .frame(height: 8)

            if viewModel.todaysCompletedCount == viewModel.todaysTotalCount {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.statusSuccess)
                    Text("All doses completed!")
                        .font(.subheadline)
                        .foregroundColor(.statusSuccess)
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(16)
    }

    // MARK: - Today's Doses Section
    private var todaysDosesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Schedule")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
            }

            if viewModel.todaysDoses.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.checkmark",
                    title: "No Doses Today",
                    message: "You're all caught up! No scheduled doses for today."
                )
            } else {
                ForEach(viewModel.todaysDoses, id: \.id) { tracked in
                    TodayDoseCard(
                        tracked: tracked,
                        isCompleted: viewModel.isDoseCompletedToday(tracked),
                        recommendedSite: viewModel.recommendedSite(for: tracked)
                    ) {
                        selectedTracked = tracked
                    }
                }
            }
        }
    }

    // MARK: - Low Stock Section
    private var lowStockSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.statusWarning)
                Text("Low Stock")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
            }

            ForEach(viewModel.lowStockItems, id: \.id) { inventory in
                HStack {
                    Text(inventory.compound?.name ?? "Unknown")
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text(inventory.stockStatusString)
                        .font(.subheadline)
                        .foregroundColor(.statusWarning)
                }
                .padding()
                .background(Color.backgroundTertiary)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(16)
    }

    // MARK: - Quick Stats Card
    private var quickStatsCard: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "This Week",
                value: "\(viewModel.weeklyDoseCount)",
                subtitle: "doses logged",
                icon: "chart.bar.fill",
                color: .accentPrimary
            )

            StatCard(
                title: "Active",
                value: "\(viewModel.activeCompoundsCount)",
                subtitle: "compounds",
                icon: "pills.fill",
                color: .accentSecondary
            )
        }
    }

    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
            }

            ForEach(viewModel.recentLogs.prefix(5), id: \.id) { log in
                RecentLogRow(log: log)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(16)
    }
}

// MARK: - Supporting Views

struct TodayDoseCard: View {
    let tracked: TrackedCompound
    let isCompleted: Bool
    let recommendedSite: String?
    let onLogTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(isCompleted ? Color.statusSuccess : Color.accentPrimary)
                .frame(width: 12, height: 12)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(tracked.compound?.name ?? "Unknown")
                    .font(.headline)
                    .foregroundColor(isCompleted ? .textSecondary : .textPrimary)
                    .strikethrough(isCompleted)

                HStack(spacing: 8) {
                    Text(tracked.dosageString)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)

                    if let site = recommendedSite, tracked.compound?.requiresInjection == true {
                        Text("•")
                            .foregroundColor(.textTertiary)
                        Text(site)
                            .font(.caption)
                            .foregroundColor(.accentPrimary)
                    }
                }
            }

            Spacer()

            // Time
            if let time = tracked.notificationTime {
                Text(time.timeString)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }

            // Log button
            if !isCompleted {
                Button(action: onLogTap) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentPrimary)
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.statusSuccess)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

struct RecentLogRow: View {
    let log: DoseLog

    var body: some View {
        HStack {
            Circle()
                .fill(log.compound?.category.color ?? .gray)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(log.compound?.name ?? "Unknown")
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                Text(log.dosageString)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Text(log.relativeDateString)
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Quick Log Sheet
struct QuickLogSheet: View {
    let compound: Compound
    let tracked: TrackedCompound
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: DoseLogViewModel

    init(compound: Compound, tracked: TrackedCompound, onComplete: @escaping () -> Void) {
        self.compound = compound
        self.tracked = tracked
        self.onComplete = onComplete
        _viewModel = StateObject(wrappedValue: DoseLogViewModel(preselectedCompound: compound))
    }

    var body: some View {
        NavigationStack {
            LogDoseView(viewModel: viewModel, onSuccess: {
                onComplete()
                dismiss()
            })
            .navigationTitle("Log \(compound.name ?? "Dose")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
}
