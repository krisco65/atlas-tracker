import SwiftUI

struct TrackingSetupView: View {
    @Bindable var viewModel: CompoundDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSaveConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Edit mode info banner
                        if viewModel.isTracked {
                            editInfoBanner
                        }

                        // Dosage Section
                        dosageSection

                        // Schedule Section
                        scheduleSection

                        // Notification Section
                        notificationSection

                        // Preview Section
                        previewSection

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle(viewModel.isTracked ? "Edit Tracking" : "Start Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if viewModel.isTracked {
                            viewModel.updateTracking()
                        } else {
                            viewModel.startTracking()
                        }
                    }
                    .disabled(!viewModel.canSaveTracking || viewModel.isLoading)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Edit Info Banner
    private var editInfoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.accentPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Editing Tracking Settings")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                Text("Your dose history will be preserved")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.accentPrimary.opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - Dosage Section
    private var dosageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dosage")
                .font(.headline)
                .foregroundColor(.textPrimary)

            HStack(spacing: 12) {
                TextField("Amount", text: $viewModel.dosageAmount)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color.backgroundSecondary)
                    .cornerRadius(10)
                    .foregroundColor(.textPrimary)

                Picker("Unit", selection: $viewModel.selectedUnit) {
                    ForEach(viewModel.availableUnits, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .background(Color.backgroundSecondary)
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Schedule Section
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schedule")
                .font(.headline)
                .foregroundColor(.textPrimary)

            // Schedule type picker
            Picker("Schedule Type", selection: $viewModel.scheduleType) {
                ForEach(ScheduleType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)

            // Additional options based on schedule type
            switch viewModel.scheduleType {
            case .everyXDays:
                everyXDaysOptions
            case .specificDays:
                specificDaysOptions
            default:
                EmptyView()
            }
        }
    }

    private var everyXDaysOptions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Interval (days)")
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            HStack(spacing: 8) {
                // Quick presets
                ForEach(["1", "3", "7"], id: \.self) { preset in
                    Button {
                        viewModel.scheduleInterval = preset
                    } label: {
                        Text(preset)
                            .font(.subheadline)
                            .frame(width: 44, height: 44)
                            .background(viewModel.scheduleInterval == preset ? Color.accentPrimary : Color.backgroundTertiary)
                            .foregroundColor(viewModel.scheduleInterval == preset ? .white : .textSecondary)
                            .cornerRadius(8)
                    }
                }

                // E3.5D preset
                Button {
                    viewModel.scheduleInterval = "3" // Will alternate 3/4
                } label: {
                    Text("E3.5D")
                        .font(.caption)
                        .frame(width: 56, height: 44)
                        .background(viewModel.scheduleInterval == "3" ? Color.accentPrimary : Color.backgroundTertiary)
                        .foregroundColor(viewModel.scheduleInterval == "3" ? .white : .textSecondary)
                        .cornerRadius(8)
                }

                Spacer()

                TextField("Days", text: $viewModel.scheduleInterval)
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                    .padding()
                    .background(Color.backgroundSecondary)
                    .cornerRadius(10)
                    .foregroundColor(.textPrimary)
            }

            if viewModel.scheduleInterval == "3" || viewModel.scheduleInterval == "4" {
                Text("E3.5D: Alternates between 3 and 4 days")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
    }

    private var specificDaysOptions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Days")
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            HStack(spacing: 8) {
                ForEach(Weekday.allCases, id: \.self) { day in
                    Button {
                        viewModel.toggleDay(day.rawValue)
                    } label: {
                        Text(String(day.shortName.prefix(1)))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 40, height: 40)
                            .background(viewModel.selectedDays.contains(day.rawValue) ? Color.accentPrimary : Color.backgroundTertiary)
                            .foregroundColor(viewModel.selectedDays.contains(day.rawValue) ? .white : .textSecondary)
                            .cornerRadius(20)
                    }
                }
            }
        }
    }

    // MARK: - Notification Section
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $viewModel.notificationEnabled) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.accentPrimary)
                    Text("Enable Notifications")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                }
            }

            if viewModel.notificationEnabled {
                DatePicker(
                    "Notification Time",
                    selection: $viewModel.notificationTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .foregroundColor(.textPrimary)
                .padding()
                .background(Color.backgroundSecondary)
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.headline)
                .foregroundColor(.textPrimary)

            VStack(alignment: .leading, spacing: 4) {
                if let amount = Double(viewModel.dosageAmount), amount > 0 {
                    Text("\(String(format: "%.1f", amount)) \(viewModel.selectedUnit.displayName)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentPrimary)
                }

                Text(viewModel.scheduleDescription)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.backgroundSecondary)
            .cornerRadius(10)
        }
    }
}

#Preview {
    Text("Preview requires compound instance")
        .preferredColorScheme(.dark)
}
