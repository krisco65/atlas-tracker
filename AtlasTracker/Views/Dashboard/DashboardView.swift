import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var selectedTracked: TrackedCompound?
    @State private var showActiveCompounds = false
    @State private var showInventory = false
    @State private var showReconstitutionCalculator = false
    @State private var showSkipConfirmation = false
    @State private var trackedToSkip: TrackedCompound?

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

                        // Quick Tools (Calculator)
                        quickToolsCard

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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .cornerRadius(8)
                }
            }
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
            .sheet(isPresented: $showActiveCompounds) {
                ActiveCompoundsSheet(trackedCompounds: viewModel.activeTrackedCompounds)
            }
            .sheet(isPresented: $showInventory) {
                InventoryView()
            }
            .sheet(isPresented: $showReconstitutionCalculator) {
                ReconstitutionCalculatorView()
            }
            .alert("Skip Dose?", isPresented: $showSkipConfirmation) {
                Button("Cancel", role: .cancel) {
                    trackedToSkip = nil
                }
                Button("Skip", role: .destructive) {
                    if let tracked = trackedToSkip {
                        viewModel.skipDose(for: tracked)
                    }
                    trackedToSkip = nil
                }
            } message: {
                if let tracked = trackedToSkip {
                    Text("Skip today's \(tracked.compound?.name ?? "dose")? This will be recorded in your history.")
                } else {
                    Text("Skip this dose? This will be recorded in your history.")
                }
            }
        }
    }

    // MARK: - Quick Tools Card
    private var quickToolsCard: some View {
        Button {
            showReconstitutionCalculator = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "function")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.categoryPeptide)
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Reconstitution Calculator")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Text("Calculate BAC water & dosing")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.textTertiary)
                    .font(.caption)
            }
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
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
                        recommendedSite: viewModel.recommendedSite(for: tracked),
                        onLogTap: {
                            selectedTracked = tracked
                        },
                        onSkipTap: {
                            showSkipConfirmation = true
                            trackedToSkip = tracked
                        }
                    )
                }
            }
        }
    }

    // MARK: - Low Stock Section
    private var lowStockSection: some View {
        Button {
            showInventory = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.statusWarning)
                    Text("Low Stock")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.textTertiary)
                        .font(.caption)
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
        .buttonStyle(.plain)
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

            Button {
                showActiveCompounds = true
            } label: {
                StatCard(
                    title: "Active",
                    value: "\(viewModel.activeCompoundsCount)",
                    subtitle: "compounds",
                    icon: "pills.fill",
                    color: .accentSecondary
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Last Injections Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Last Injections")
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

// MARK: - Preview

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
}
