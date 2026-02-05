import SwiftUI
import Charts
import Observation

// MARK: - Analytics View Model
@Observable
final class AnalyticsViewModel {
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case allTime = "All Time"
    }

    var selectedPeriod: TimePeriod = .week
    var doseLogs: [DoseLog] = []
    var weightEntries: [WeightEntry] = []
    var trackedCompounds: [TrackedCompound] = []
    var showAddWeight = false

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

    var adherenceDescription: String {
        let percentage = adherencePercentage
        if percentage >= 90 {
            return "Excellent"
        } else if percentage >= 75 {
            return "Good"
        } else if percentage >= 50 {
            return "Fair"
        } else {
            return "Needs Improvement"
        }
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

    var weightChange: Double? {
        guard weightEntries.count >= 2 else { return nil }
        let sorted = weightEntries.sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }
        guard let first = sorted.first, let last = sorted.last else { return nil }
        return last.weight - first.weight
    }

    var latestWeight: WeightEntry? {
        return weightEntries.max { ($0.date ?? Date()) < ($1.date ?? Date()) }
    }

    var averageDosesPerDay: Double {
        let range = dateRange
        let daysInPeriod = max(1, Calendar.current.dateComponents([.day], from: range.start, to: range.end).day ?? 1)
        return Double(totalDoses) / Double(daysInPeriod)
    }

    func loadData() {
        let range = dateRange
        doseLogs = CoreDataManager.shared.fetchDoseLogs(from: range.start, to: range.end)
        weightEntries = CoreDataManager.shared.fetchWeightEntries(from: range.start, to: range.end)
        trackedCompounds = CoreDataManager.shared.fetchTrackedCompounds(activeOnly: true)
    }

    func addWeightEntry(weight: Double, unit: WeightUnit, notes: String?) {
        CoreDataManager.shared.logWeight(weight: weight, unit: unit, date: Date(), notes: notes)
        loadData()

        HapticManager.success()
    }
}

struct AnalyticsView: View {
    @State private var viewModel = AnalyticsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if viewModel.doseLogs.isEmpty && viewModel.weightEntries.isEmpty {
                            // Empty state for analytics
                            analyticsEmptyState
                        } else {
                            // Time Period Picker
                            periodPicker

                            // Summary Cards
                            summaryCards

                            // Adherence Card
                            adherenceCard

                            // Dose Frequency Chart
                            if !viewModel.doseLogs.isEmpty {
                                doseFrequencyChart
                            }

                            // Weight Tracking Section
                            weightSection

                            // Compounds Breakdown
                            if !viewModel.dosesByCompound.isEmpty {
                                compoundsBreakdown
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showAddWeight = true
                    } label: {
                        Image(systemName: "scalemass")
                            .foregroundColor(.accentPrimary)
                    }
                }
            }
            .onAppear {
                viewModel.loadData()
            }
            .onChange(of: viewModel.selectedPeriod) {
                viewModel.loadData()
            }
            .sheet(isPresented: $viewModel.showAddWeight) {
                AddWeightSheet(viewModel: viewModel)
            }
        }
    }

    // MARK: - Analytics Empty State
    private var analyticsEmptyState: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 40)

            Image(systemName: "chart.bar.fill")
                .font(.system(size: 56))
                .foregroundColor(.textTertiary)

            Text("No Data Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text("Start logging doses to see your analytics. Your adherence, frequency charts, and compound breakdowns will appear here.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 12) {
                analyticsFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Adherence tracking", color: .statusSuccess)
                analyticsFeatureRow(icon: "chart.bar.fill", text: "Dose frequency charts", color: .accentPrimary)
                analyticsFeatureRow(icon: "scalemass", text: "Weight trend tracking", color: .accentSecondary)
                analyticsFeatureRow(icon: "flask.fill", text: "Compound breakdowns", color: .categoryPeptide)
            }
            .padding(20)
            .background(Color.backgroundSecondary)
            .cornerRadius(16)

            // Weight logging shortcut
            Button {
                viewModel.showAddWeight = true
            } label: {
                HStack {
                    Image(systemName: "scalemass")
                    Text("Log Your First Weight Entry")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.accentPrimary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentPrimary.opacity(0.12))
                .cornerRadius(12)
            }

            Spacer()
        }
    }

    private func analyticsFeatureRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
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
                title: "Avg/Day",
                value: String(format: "%.1f", viewModel.averageDosesPerDay),
                icon: "chart.line.uptrend.xyaxis",
                color: .categoryMedicine
            )
        }
    }

    // MARK: - Adherence Card
    private var adherenceCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Adherence")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                Text(viewModel.adherenceDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(adherenceColor)
            }

            // Circular Progress
            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.backgroundTertiary, lineWidth: 10)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: min(viewModel.adherencePercentage / 100, 1.0))
                        .stroke(adherenceColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    Text(String(format: "%.0f%%", viewModel.adherencePercentage))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    adherenceStatRow(title: "Logged", value: "\(viewModel.totalDoses) doses")
                    adherenceStatRow(title: "Active Compounds", value: "\(viewModel.trackedCompounds.count)")
                    adherenceStatRow(title: "Period", value: viewModel.selectedPeriod.rawValue)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(16)
    }

    private var adherenceColor: Color {
        let percentage = viewModel.adherencePercentage
        if percentage >= 80 {
            return .statusSuccess
        } else if percentage >= 50 {
            return .statusWarning
        } else {
            return .statusError
        }
    }

    private func adherenceStatRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
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

    // MARK: - Weight Section
    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weight Tracking")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                Button {
                    viewModel.showAddWeight = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Log")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.accentPrimary)
                }
            }

            if viewModel.weightEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "scalemass")
                        .font(.largeTitle)
                        .foregroundColor(.textTertiary)

                    Text("No weight entries yet")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)

                    Text("Track your weight to see trends over time")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                // Current Weight Stats
                HStack(spacing: 16) {
                    // Latest Weight
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", viewModel.latestWeight?.weight ?? 0))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)

                        Text(viewModel.latestWeight?.unit.rawValue ?? "lbs")
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                        Text("Current")
                            .font(.caption2)
                            .foregroundColor(.textTertiary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 50)
                        .background(Color.backgroundTertiary)

                    // Change
                    VStack(spacing: 4) {
                        if let change = viewModel.weightChange {
                            HStack(spacing: 2) {
                                Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                                    .font(.caption)
                                Text(String(format: "%.1f", abs(change)))
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(change >= 0 ? .statusSuccess : .accentPrimary)
                        } else {
                            Text("--")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.textTertiary)
                        }

                        Text(viewModel.latestWeight?.unit.rawValue ?? "lbs")
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                        Text("Change")
                            .font(.caption2)
                            .foregroundColor(.textTertiary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 50)
                        .background(Color.backgroundTertiary)

                    // Entries
                    VStack(spacing: 4) {
                        Text("\(viewModel.weightEntries.count)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)

                        Text("entries")
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                        Text("Logged")
                            .font(.caption2)
                            .foregroundColor(.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)

                // Weight Chart
                if viewModel.weightEntries.count >= 2 {
                    weightChart
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(16)
    }

    // MARK: - Weight Chart
    private var weightChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trend")
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            Chart(viewModel.weightEntries.sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }, id: \.id) { entry in
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
            .frame(height: 150)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
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
    }
}

// MARK: - Add Weight Sheet
struct AddWeightSheet: View {
    @Bindable var viewModel: AnalyticsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var weightString = ""
    @State private var selectedUnit: WeightUnit = .lbs
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()
                    .onTapGesture {
                        hideKeyboard()
                    }

                ScrollView {
                    VStack(spacing: 24) {
                        // Weight Input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Weight")
                                .font(.headline)
                                .foregroundColor(.textPrimary)

                            HStack(spacing: 12) {
                                TextField("0.0", text: $weightString)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.backgroundSecondary)
                                    .cornerRadius(12)

                                // Unit Picker
                                Picker("Unit", selection: $selectedUnit) {
                                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                                        Text(unit.rawValue).tag(unit)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 100)
                            }
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes (Optional)")
                                .font(.headline)
                                .foregroundColor(.textPrimary)

                            TextField("e.g., Morning weight, post-workout", text: $notes)
                                .padding()
                                .background(Color.backgroundSecondary)
                                .cornerRadius(10)
                                .foregroundColor(.textPrimary)
                        }

                        // Save Button
                        Button {
                            saveWeight()
                        } label: {
                            Text("Log Weight")
                                .primaryButtonStyle()
                        }
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.5)

                        Spacer()
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                    .foregroundColor(.accentPrimary)
                }
            }
            .onAppear {
                // Pre-fill with latest weight if available
                if let latest = viewModel.latestWeight {
                    selectedUnit = latest.unit
                }
            }
        }
    }

    private var canSave: Bool {
        guard let weight = Double(weightString), weight > 0, weight <= 1500 else { return false }
        return true
    }

    private func saveWeight() {
        guard let weight = Double(weightString) else { return }
        viewModel.addWeightEntry(
            weight: weight,
            unit: selectedUnit,
            notes: notes.isEmpty ? nil : notes
        )
        dismiss()
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
