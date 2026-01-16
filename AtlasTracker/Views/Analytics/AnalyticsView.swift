import SwiftUI
import Charts

// MARK: - Analytics View Model
final class AnalyticsViewModel: ObservableObject {
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case allTime = "All Time"
    }

    @Published var selectedPeriod: TimePeriod = .week
    @Published var doseLogs: [DoseLog] = []
    @Published var weightEntries: [WeightEntry] = []
    @Published var trackedCompounds: [TrackedCompound] = []

    var dateRange: (start: Date, end: Date) {
        let end = Date()
        let start: Date
        switch selectedPeriod {
        case .week:
            start = end.daysAgo(7)
        case .month:
            start = end.daysAgo(30)
        case .allTime:
            start = Date.distantPast
        }
        return (start, end)
    }

    var totalDoses: Int {
        return doseLogs.count
    }

    var uniqueCompounds: Int {
        return Set(doseLogs.compactMap { $0.compound?.id }).count
    }

    var adherencePercentage: Double {
        guard !trackedCompounds.isEmpty else { return 0 }

        let range = dateRange
        let daysInPeriod = max(1, Calendar.current.dateComponents([.day], from: range.start, to: range.end).day ?? 1)

        var expectedDoses = 0
        for tracked in trackedCompounds {
            switch tracked.scheduleType {
            case .daily:
                expectedDoses += daysInPeriod
            case .everyXDays:
                expectedDoses += daysInPeriod / Int(tracked.scheduleInterval)
            case .specificDays:
                expectedDoses += (daysInPeriod / 7) * tracked.scheduleDays.count
            case .asNeeded:
                continue
            }
        }

        guard expectedDoses > 0 else { return 100 }
        return min(100, Double(totalDoses) / Double(expectedDoses) * 100)
    }

    var dosesByDay: [(date: Date, count: Int)] {
        let grouped = Dictionary(grouping: doseLogs) { log in
            Calendar.current.startOfDay(for: log.timestamp ?? Date())
        }

        let range = dateRange
        var result: [(Date, Int)] = []
        var current = range.start.startOfDay

        while current <= range.end {
            let count = grouped[current]?.count ?? 0
            result.append((current, count))
            current = current.daysFromNow(1)
        }

        return result
    }

    var dosesByCompound: [(name: String, count: Int, color: Color)] {
        let grouped = Dictionary(grouping: doseLogs) { $0.compound?.name ?? "Unknown" }
        return grouped.map { (name, logs) in
            let color = logs.first?.compound?.category.color ?? .gray
            return (name, logs.count, color)
        }
        .sorted { $0.count > $1.count }
    }

    func loadData() {
        let range = dateRange
        doseLogs = CoreDataManager.shared.fetchDoseLogs(from: range.start, to: range.end)
        weightEntries = CoreDataManager.shared.fetchWeightEntries(from: range.start, to: range.end)
        trackedCompounds = CoreDataManager.shared.fetchTrackedCompounds(activeOnly: true)
    }
}

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Time Period Picker
                        periodPicker

                        // Summary Cards
                        summaryCards

                        // Dose Frequency Chart
                        if !viewModel.doseLogs.isEmpty {
                            doseFrequencyChart
                        }

                        // Compounds Breakdown
                        if !viewModel.dosesByCompound.isEmpty {
                            compoundsBreakdown
                        }

                        // Weight Chart (if data exists)
                        if !viewModel.weightEntries.isEmpty {
                            weightChart
                        }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadData()
            }
            .onChange(of: viewModel.selectedPeriod) { _, _ in
                viewModel.loadData()
            }
        }
    }

    // MARK: - Period Picker
    private var periodPicker: some View {
        Picker("Period", selection: $viewModel.selectedPeriod) {
            ForEach(AnalyticsViewModel.TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Summary Cards
    private var summaryCards: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Total Doses",
                value: "\(viewModel.totalDoses)",
                icon: "pills.fill",
                color: .accentPrimary
            )

            SummaryCard(
                title: "Compounds",
                value: "\(viewModel.uniqueCompounds)",
                icon: "flask.fill",
                color: .categoryPeptide
            )

            SummaryCard(
                title: "Adherence",
                value: String(format: "%.0f%%", viewModel.adherencePercentage),
                icon: "checkmark.circle.fill",
                color: viewModel.adherencePercentage >= 80 ? .statusSuccess : .statusWarning
            )
        }
    }

    // MARK: - Dose Frequency Chart
    private var doseFrequencyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dose Frequency")
                .font(.headline)
                .foregroundColor(.textPrimary)

            Chart(viewModel.dosesByDay, id: \.date) { item in
                BarMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Doses", item.count)
                )
                .foregroundStyle(Color.accentPrimary.gradient)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: viewModel.selectedPeriod == .week ? 1 : 7)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date.shortDateString)
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(16)
    }

    // MARK: - Compounds Breakdown
    private var compoundsBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Compound")
                .font(.headline)
                .foregroundColor(.textPrimary)

            ForEach(viewModel.dosesByCompound.prefix(5), id: \.name) { item in
                HStack {
                    Circle()
                        .fill(item.color)
                        .frame(width: 8, height: 8)

                    Text(item.name)
                        .font(.subheadline)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Text("\(item.count) doses")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(16)
    }

    // MARK: - Weight Chart
    private var weightChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weight Trend")
                .font(.headline)
                .foregroundColor(.textPrimary)

            Chart(viewModel.weightEntries, id: \.id) { entry in
                LineMark(
                    x: .value("Date", entry.date ?? Date()),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(Color.accentSecondary)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", entry.date ?? Date()),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(Color.accentSecondary)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(16)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

#Preview {
    AnalyticsView()
        .preferredColorScheme(.dark)
}
