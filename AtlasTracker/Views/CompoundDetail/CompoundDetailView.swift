import SwiftUI

struct CompoundDetailView: View {
    @State private var viewModel: CompoundDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var showReconstitutionCalculator = false
    @State private var showAddInventory = false

    init(compound: Compound) {
        _viewModel = State(wrappedValue: CompoundDetailViewModel(compound: compound))
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

                    // Inventory Card (for peptides and PEDs)
                    if (viewModel.compound.category == .peptide || viewModel.compound.category == .ped) && viewModel.isTracked {
                        inventoryCard
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                        Text("Library")
                    }
                    .foregroundColor(.accentPrimary)
                }
            }
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
        .sheet(isPresented: $showAddInventory) {
            AddInventorySheetForCompound(compound: viewModel.compound) {
                viewModel.loadData()
            }
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

    // MARK: - Inventory Card
    private var inventoryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "shippingbox")
                    .foregroundColor(.accentPrimary)

                Text("Inventory")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()
            }

            if let inventory = viewModel.compound.inventoryArray.first {
                // Show inventory info
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Stock")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            Text(inventory.stockStatusString)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(inventory.isLowStock ? .statusWarning : .textPrimary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Remaining")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            Text(inventory.remainingString)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                        }
                    }

                    // Progress bar for current vial
                    if inventory.vialSizeMg > 0 {
                        let percentage = min(1.0, inventory.remainingInCurrentVial / inventory.vialSizeMg)
                        VStack(spacing: 4) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.backgroundTertiary)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(percentage > 0.2 ? Color.statusSuccess : Color.statusWarning)
                                        .frame(width: geometry.size.width * percentage)
                                }
                            }
                            .frame(height: 8)

                            HStack {
                                Text("Current vial")
                                    .font(.caption2)
                                    .foregroundColor(.textTertiary)
                                Spacer()
                                Text(String(format: "%.0f / %.0f mg", inventory.remainingInCurrentVial, inventory.vialSizeMg))
                                    .font(.caption2)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }

                    HStack {
                        Toggle(isOn: Binding(
                            get: { inventory.autoDecrement },
                            set: { newValue in
                                inventory.autoDecrement = newValue
                                CoreDataManager.shared.saveContext()
                            }
                        )) {
                            Text("Auto-decrement")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .toggleStyle(.switch)
                        .tint(.accentPrimary)
                    }

                    Button {
                        showAddInventory = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Inventory")
                        }
                        .secondaryButtonStyle()
                    }
                }
            } else {
                // No inventory - show add button
                VStack(spacing: 8) {
                    Text("No inventory tracked")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)

                    Button {
                        showAddInventory = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Inventory")
                        }
                        .secondaryButtonStyle()
                    }
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

// MARK: - Add Inventory Sheet for Compound
struct AddInventorySheetForCompound: View {
    let compound: Compound
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var vialCountString = "1"
    @State private var vialSizeString = ""
    @State private var lowStockThresholdString = "2"
    @State private var autoDecrementEnabled = true

    private var existingInventory: Inventory? {
        compound.inventoryArray.first
    }

    private var canSave: Bool {
        guard let vialCount = Int16(vialCountString), vialCount >= 0,
              let vialSize = Double(vialSizeString), vialSize > 0 else {
            return false
        }
        return true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Compound Info
                        compoundHeader

                        // Vial Details
                        vialDetailsSection

                        // Settings
                        settingsSection

                        // Save Button
                        saveButton

                        // Delete Button (if editing)
                        if existingInventory != nil {
                            deleteButton
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(existingInventory == nil ? "Add Inventory" : "Edit Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
            .onAppear {
                if let inventory = existingInventory {
                    vialCountString = String(inventory.vialCount)
                    vialSizeString = String(format: "%.0f", inventory.vialSizeMg)
                    lowStockThresholdString = String(inventory.lowStockThreshold)
                    autoDecrementEnabled = inventory.autoDecrement
                }
            }
        }
    }

    private var compoundHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: compound.category.icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(compound.category.color)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(compound.name ?? "Unknown")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Text(compound.category.displayName)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }

    private var vialDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vial Details")
                .font(.headline)
                .foregroundColor(.textPrimary)

            HStack(spacing: 12) {
                // Vial Count
                VStack(alignment: .leading, spacing: 8) {
                    Text("Number of Vials")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)

                    TextField("1", text: $vialCountString)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color.backgroundSecondary)
                        .cornerRadius(10)
                        .foregroundColor(.textPrimary)
                }

                // Vial Size
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vial Size (mg)")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)

                    TextField("5", text: $vialSizeString)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.backgroundSecondary)
                        .cornerRadius(10)
                        .foregroundColor(.textPrimary)
                }
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)
                .foregroundColor(.textPrimary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Low Stock Alert")
                        .font(.subheadline)
                        .foregroundColor(.textPrimary)
                    Text("Alert when vials drop to this level")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }

                Spacer()

                HStack(spacing: 8) {
                    TextField("2", text: $lowStockThresholdString)
                        .keyboardType(.numberPad)
                        .frame(width: 50)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(8)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("vials")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(12)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto-Decrement")
                        .font(.subheadline)
                        .foregroundColor(.textPrimary)
                    Text("Automatically reduce inventory when doses are logged")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }

                Spacer()

                Toggle("", isOn: $autoDecrementEnabled)
                    .labelsHidden()
                    .tint(.accentPrimary)
            }
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
        }
    }

    private var saveButton: some View {
        Button {
            saveInventory()
        } label: {
            Text(existingInventory == nil ? "Add Inventory" : "Save Changes")
                .primaryButtonStyle()
        }
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.5)
    }

    private var deleteButton: some View {
        Button {
            deleteInventory()
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Inventory")
            }
            .font(.subheadline)
            .foregroundColor(.statusError)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
        }
    }

    private func saveInventory() {
        guard let vialCount = Int16(vialCountString), vialCount >= 0,
              let vialSize = Double(vialSizeString), vialSize > 0,
              let threshold = Int16(lowStockThresholdString) else {
            return
        }

        if let existing = existingInventory {
            existing.vialCount = vialCount
            existing.vialSizeMg = vialSize
            existing.lowStockThreshold = threshold
            existing.autoDecrement = autoDecrementEnabled
            existing.lastUpdated = Date()
        } else {
            let inventory = Inventory(
                context: CoreDataManager.shared.viewContext,
                compound: compound,
                vialCount: vialCount,
                vialSizeMg: vialSize,
                lowStockThreshold: threshold
            )
            inventory.autoDecrement = autoDecrementEnabled
        }

        CoreDataManager.shared.saveContext()

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        onSave()
        dismiss()
    }

    private func deleteInventory() {
        if let inventory = existingInventory {
            CoreDataManager.shared.viewContext.delete(inventory)
            CoreDataManager.shared.saveContext()

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)

            onSave()
            dismiss()
        }
    }
}
