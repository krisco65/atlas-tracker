import SwiftUI

struct LogDoseView: View {
    @StateObject private var viewModel = DoseLogViewModel()
    @State private var showBodyDiagram = false
    var onSuccess: (() -> Void)?
    var preselectedCompound: Compound?

    init(onSuccess: (() -> Void)? = nil, preselectedCompound: Compound? = nil) {
        self.onSuccess = onSuccess
        self.preselectedCompound = preselectedCompound
    }

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            if viewModel.showSuccess {
                successView
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Compound Selector
                        compoundSelector

                        if viewModel.selectedCompound != nil {
                            // Dosage Section
                            dosageSection

                            // Injection Site Section (if applicable)
                            if viewModel.requiresInjectionSite {
                                injectionSiteSection
                            }

                            // Date/Time Section
                            dateTimeSection

                            // Notes Section
                            notesSection

                            // Log Button
                            logButton
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Log Dose")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadTrackedCompounds()
            if let compound = preselectedCompound {
                viewModel.selectCompound(compound)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showBodyDiagram) {
            if let compound = viewModel.selectedCompound {
                InjectionSitePickerView(
                    compound: compound,
                    selectedSite: $viewModel.selectedInjectionSite,
                    onConfirm: {}
                )
            }
        }
    }

    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.statusSuccess)

            Text("Dose Logged!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text("Your dose has been recorded successfully")
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            Spacer()
        }
        .onAppear {
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Call success callback
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                onSuccess?()
            }
        }
    }

    // MARK: - Compound Selector
    private var compoundSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compound")
                .font(.headline)
                .foregroundColor(.textPrimary)

            if viewModel.trackedCompounds.isEmpty {
                EmptyStateView(
                    icon: "pills",
                    title: "No Tracked Compounds",
                    message: "Start tracking compounds in the Library to log doses"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.trackedCompounds, id: \.id) { tracked in
                            CompoundChip(
                                tracked: tracked,
                                isSelected: viewModel.selectedCompound?.id == tracked.compound?.id
                            ) {
                                viewModel.selectTrackedCompound(tracked)
                            }
                        }
                    }
                }

                if let compound = viewModel.selectedCompound {
                    SelectedCompoundCard(compound: compound)
                }
            }
        }
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

    // MARK: - Injection Site Section
    private var injectionSiteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Injection Site")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                Button {
                    showBodyDiagram = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.stand")
                        Text("Body Diagram")
                    }
                    .font(.caption)
                    .foregroundColor(.accentPrimary)
                }
            }

            // Recommendation Card
            if let recommended = viewModel.recommendedSite {
                HStack {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.statusSuccess)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recommended")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        Text(recommended)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                    }

                    Spacer()

                    if viewModel.selectedInjectionSite != viewModel.recommendedSiteRawValue {
                        Button {
                            viewModel.selectedInjectionSite = viewModel.recommendedSiteRawValue
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        } label: {
                            Text("Use")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.statusSuccess)
                                .cornerRadius(6)
                        }
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.statusSuccess)
                    }
                }
                .padding()
                .background(Color.statusSuccess.opacity(0.1))
                .cornerRadius(10)
            }

            if let lastUsed = viewModel.lastUsedSite {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.statusWarning)
                        .font(.caption)
                    Text("Last used: \(lastUsed)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            // Injection site picker
            ForEach(viewModel.injectionSiteOptions, id: \.name) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.name)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(group.sites, id: \.rawValue) { site in
                            InjectionSiteButton(
                                name: site.displayName,
                                isSelected: viewModel.selectedInjectionSite == site.rawValue,
                                isRecommended: viewModel.recommendedSiteRawValue == site.rawValue
                            ) {
                                viewModel.selectedInjectionSite = site.rawValue
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Date/Time Section
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date & Time")
                .font(.headline)
                .foregroundColor(.textPrimary)

            DatePicker(
                "When",
                selection: $viewModel.timestamp,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(10)
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes (Optional)")
                .font(.headline)
                .foregroundColor(.textPrimary)

            TextField("Add any notes...", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)
                .padding()
                .background(Color.backgroundSecondary)
                .cornerRadius(10)
                .foregroundColor(.textPrimary)
        }
    }

    // MARK: - Log Button
    private var logButton: some View {
        Button {
            viewModel.logDose()
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Log Dose")
                }
            }
            .primaryButtonStyle()
        }
        .disabled(!viewModel.canLogDose || viewModel.isLoading)
        .opacity(viewModel.canLogDose ? 1 : 0.5)
    }
}

// MARK: - Supporting Views

struct CompoundChip: View {
    let tracked: TrackedCompound
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(tracked.compound?.name ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                Text(tracked.dosageString)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : .textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? (tracked.compound?.category.color ?? .accentPrimary) : Color.backgroundSecondary)
            .cornerRadius(12)
        }
    }
}

struct SelectedCompoundCard: View {
    let compound: Compound

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: compound.category.icon)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(compound.category.color)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(compound.name ?? "Unknown")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Text(compound.category.displayName)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

struct InjectionSiteButton: View {
    let name: String
    let isSelected: Bool
    let isRecommended: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(name)
                    .font(.subheadline)

                if isRecommended && !isSelected {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.accentPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.accentPrimary : Color.backgroundTertiary)
            .foregroundColor(isSelected ? .white : .textSecondary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isRecommended && !isSelected ? Color.accentPrimary : Color.clear, lineWidth: 1)
            )
        }
    }
}

#Preview {
    NavigationStack {
        LogDoseView()
    }
    .preferredColorScheme(.dark)
}
