import SwiftUI

struct CompoundDetailView: View {
    @StateObject private var viewModel: CompoundDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var showReconstitutionCalculator = false

    init(compound: Compound) {
        _viewModel = StateObject(wrappedValue: CompoundDetailViewModel(compound: compound))
    }

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    headerCard

                    // Tracking Status Card
                    trackingCard

                    // Injection Site Info (if applicable)
                    if viewModel.requiresInjection {
                        injectionSiteCard
                    }

                    // Reconstitution Calculator (for peptides)
                    if viewModel.compound.category == .peptide && viewModel.isTracked {
                        reconstitutionCard
                    }

                    // Recent Dose History
                    if !viewModel.recentDoseLogs.isEmpty {
                        doseHistoryCard
                    }

                    // Delete button for custom compounds
                    if viewModel.compound.isCustom {
                        deleteButton
                    }
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(viewModel.compound.name ?? "Compound")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.toggleFavorite()
                } label: {
                    Image(systemName: viewModel.compound.isFavorited ? "star.fill" : "star")
                        .foregroundColor(viewModel.compound.isFavorited ? .yellow : .textSecondary)
                }
            }
        }
        .sheet(isPresented: $viewModel.showTrackingSetup) {
            TrackingSetupView(viewModel: viewModel)
        }
        .alert("Delete Compound?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if viewModel.deleteCompound() {
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete this custom compound and all its data.")
        }
        .sheet(isPresented: $showReconstitutionCalculator) {
            ReconstitutionCalculatorView(preselectedCompound: viewModel.trackedCompound)
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.compound.category.icon)
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(viewModel.compound.category.color)
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.compound.name ?? "Unknown")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    HStack(spacing: 8) {
                        CategoryBadge(category: viewModel.compound.category)

                        if viewModel.compound.requiresInjection {
                            HStack(spacing: 4) {
                                Image(systemName: "syringe")
                                Text("Injectable")
                            }
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        }
                    }
                }

                Spacer()
            }

            // Stats row
            HStack(spacing: 20) {
                StatItem(title: "Total Doses", value: "\(viewModel.totalDosesLogged)")
                StatItem(title: "Use Count", value: "\(viewModel.compound.useCount)")

                if viewModel.isTracked {
                    StatItem(title: "Since Start", value: "\(viewModel.dosesSinceStarting)")
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(16)
    }

    // MARK: - Tracking Card
    private var trackingCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Tracking")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()

                if viewModel.isTracked {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Active")
                    }
                    .font(.subheadline)
                    .foregroundColor(.statusSuccess)
                }
            }

            if viewModel.isTracked, let tracked = viewModel.trackedCompound {
                VStack(spacing: 12) {
                    HStack {
                        Text("Dosage")
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text(tracked.dosageString)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                    }

                    HStack {
                        Text("Schedule")
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text(tracked.scheduleDescription)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                    }

                    if tracked.notificationEnabled, let time = tracked.notificationTime {
                        HStack {
                            Text("Notification")
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text(time.timeString)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            viewModel.showTrackingSetup = true
                        } label: {
                            Text("Edit")
                                .secondaryButtonStyle()
                        }

                        Button {
                            viewModel.stopTracking()
                        } label: {
                            Text("Stop Tracking")
                                .font(.headline)
                                .foregroundColor(.statusError)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.backgroundTertiary)
                                .cornerRadius(12)
                        }
                    }
                }
                .font(.subheadline)
            } else {
                Button {
                    viewModel.showTrackingSetup = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Start Tracking")
                    }
                    .primaryButtonStyle()
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(16)
    }

    // MARK: - Injection Site Card
    private var injectionSiteCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Injection Sites")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Used")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(viewModel.lastUsedSite ?? "None")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Recommended Next")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(viewModel.recommendedNextSite ?? "N/A")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.accentPrimary)
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(16)
    }

    // MARK: - Reconstitution Card
    private var reconstitutionCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "eyedropper")
                    .foregroundColor(.categoryPeptide)

                Text("Reconstitution Calculator")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()
            }

            if let tracked = viewModel.trackedCompound,
               tracked.reconstitutionConcentration > 0 {
                // Show saved reconstitution info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Concentration")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        Text(String(format: "%.2f mg/ml", tracked.reconstitutionConcentration))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("BAC Water")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        Text(String(format: "%.1f ml", tracked.reconstitutionBAC))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                    }
                }
            }

            Button {
                showReconstitutionCalculator = true
            } label: {
                HStack {
                    Image(systemName: "function")
                    Text("Open Calculator")
                }
                .secondaryButtonStyle()
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(16)
    }

    // MARK: - Dose History Card
    private var doseHistoryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Recent Doses")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
            }

            ForEach(viewModel.recentDoseLogs.prefix(5), id: \.id) { log in
                DoseLogRow(log: log)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(16)
    }

    // MARK: - Delete Button
    private var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Custom Compound")
            }
            .font(.subheadline)
            .foregroundColor(.statusError)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
        }
    }
}

// MARK: - Supporting Views
struct StatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DoseLogRow: View {
    let log: DoseLog

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(log.dosageString)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)

                if let site = log.injectionSiteDisplayName {
                    Text(site)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(log.dateOnlyString)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text(log.timeOnlyString)
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(.vertical, 8)
    }
}
