import SwiftUI

struct InventoryView: View {
    @StateObject private var viewModel = InventoryViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()

                if viewModel.inventoryItems.isEmpty {
                    emptyStateView
                } else {
                    inventoryList
                }
            }
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.compoundsWithoutInventory.isEmpty {
                        Button {
                            viewModel.prepareForAdd()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddSheet) {
                AddInventorySheet(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadInventory()
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

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            EmptyStateView(
                icon: "shippingbox",
                title: "No Inventory Tracked",
                message: "Track vial inventory for your peptides and PEDs to monitor stock levels"
            )

            if !viewModel.compoundsWithoutInventory.isEmpty {
                Button {
                    viewModel.prepareForAdd()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Inventory")
                    }
                    .primaryButtonStyle()
                }
                .padding(.horizontal, 40)
            } else {
                Text("Start tracking peptides or PEDs to add inventory")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
        }
    }

    // MARK: - Inventory List

    private var inventoryList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Low Stock Alert Section
                if !viewModel.lowStockItems.isEmpty {
                    lowStockSection
                }

                // All Inventory Section
                allInventorySection
            }
            .padding()
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
            }

            ForEach(viewModel.lowStockItems, id: \.id) { inventory in
                InventoryItemCard(
                    inventory: inventory,
                    viewModel: viewModel,
                    isLowStockHighlight: true
                )
            }
        }
    }

    // MARK: - All Inventory Section

    private var allInventorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Inventory")
                .font(.headline)
                .foregroundColor(.textPrimary)

            ForEach(viewModel.inventoryItems, id: \.id) { inventory in
                InventoryItemCard(
                    inventory: inventory,
                    viewModel: viewModel,
                    isLowStockHighlight: false
                )
            }
        }
    }
}

// MARK: - Inventory Item Card

struct InventoryItemCard: View {
    let inventory: Inventory
    @ObservedObject var viewModel: InventoryViewModel
    let isLowStockHighlight: Bool

    @State private var showActions = false
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack(spacing: 12) {
                // Compound Icon
                Image(systemName: inventory.compound?.category.icon ?? "pill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(inventory.compound?.category.color ?? .accentPrimary)
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(inventory.compound?.name ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text(inventory.stockStatusString)
                        .font(.subheadline)
                        .foregroundColor(inventory.isLowStock ? .statusWarning : .textSecondary)
                }

                Spacer()

                // More Actions Button
                Button {
                    showActions = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.textSecondary)
                }
            }

            // Stats Row
            HStack(spacing: 16) {
                // Total Remaining
                statItem(
                    title: "Remaining",
                    value: inventory.remainingString,
                    icon: "cube.box"
                )

                Divider()
                    .frame(height: 30)
                    .background(Color.backgroundTertiary)

                // Doses Left
                statItem(
                    title: "Doses Left",
                    value: "\(viewModel.remainingDoses(for: inventory))",
                    icon: "syringe"
                )

                Divider()
                    .frame(height: 30)
                    .background(Color.backgroundTertiary)

                // Days of Supply
                statItem(
                    title: "Days Supply",
                    value: "\(viewModel.daysRemaining(for: inventory))",
                    icon: "calendar"
                )
            }

            // Progress Bar
            progressBar

            // Quick Actions
            HStack(spacing: 12) {
                Button {
                    viewModel.addVials(to: inventory, count: 1)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Vial")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.accentPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.accentPrimary.opacity(0.1))
                    .cornerRadius(8)
                }

                Button {
                    viewModel.startNewVial(for: inventory)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("New Vial")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.backgroundTertiary)
                    .cornerRadius(8)
                }

                Spacer()

                // Auto-decrement toggle
                Toggle(isOn: Binding(
                    get: { inventory.autoDecrement },
                    set: { _ in viewModel.toggleAutoDecrement(for: inventory) }
                )) {
                    Text("Auto")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(0.8)
            }
        }
        .padding()
        .background(isLowStockHighlight ? Color.statusWarning.opacity(0.1) : Color.backgroundSecondary)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isLowStockHighlight ? Color.statusWarning.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .confirmationDialog("Inventory Actions", isPresented: $showActions) {
            Button("Edit Inventory") {
                viewModel.prepareForEdit(inventory)
            }
            Button("Add Vials") {
                viewModel.addVials(to: inventory, count: 1)
            }
            Button("Start New Vial") {
                viewModel.startNewVial(for: inventory)
            }
            Button("Delete Inventory", role: .destructive) {
                showDeleteConfirm = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Delete Inventory?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteInventory(inventory)
            }
        } message: {
            Text("This will remove inventory tracking for \(inventory.compound?.name ?? "this compound"). Your dose logs will not be affected.")
        }
    }

    private func statItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.textPrimary)

            Text(title)
                .font(.caption2)
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var progressBar: some View {
        let percentage: Double = {
            guard inventory.vialSizeMg > 0 else { return 0 }
            return min(1.0, inventory.remainingInCurrentVial / inventory.vialSizeMg)
        }()

        return VStack(spacing: 4) {
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
                Text("Current vial:")
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
                Spacer()
                Text(String(format: "%.0f mg / %.0f mg", inventory.remainingInCurrentVial, inventory.vialSizeMg))
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

// MARK: - Add Inventory Sheet

struct AddInventorySheet: View {
    @ObservedObject var viewModel: InventoryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Compound Selector (only for new inventory)
                        if viewModel.editingInventory == nil {
                            compoundSelector
                        } else {
                            // Show selected compound info
                            selectedCompoundCard
                        }

                        // Vial Details
                        vialDetailsSection

                        // Settings
                        settingsSection

                        // Save Button
                        saveButton
                    }
                    .padding()
                }
            }
            .navigationTitle(viewModel.editingInventory == nil ? "Add Inventory" : "Edit Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
    }

    // MARK: - Compound Selector

    private var compoundSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compound")
                .font(.headline)
                .foregroundColor(.textPrimary)

            if viewModel.compoundsWithoutInventory.isEmpty {
                Text("No eligible compounds available. Start tracking peptides or PEDs first.")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.backgroundSecondary)
                    .cornerRadius(12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.compoundsWithoutInventory, id: \.id) { compound in
                            CompoundSelectChip(
                                compound: compound,
                                isSelected: viewModel.selectedCompound?.id == compound.id
                            ) {
                                viewModel.selectedCompound = compound
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Selected Compound Card

    private var selectedCompoundCard: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.selectedCompound?.category.icon ?? "pill")
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(viewModel.selectedCompound?.category.color ?? .accentPrimary)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.selectedCompound?.name ?? "Unknown")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Text(viewModel.selectedCompound?.category.displayName ?? "")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }

    // MARK: - Vial Details Section

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

                    TextField("1", text: $viewModel.vialCountString)
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

                    TextField("5", text: $viewModel.vialSizeString)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.backgroundSecondary)
                        .cornerRadius(10)
                        .foregroundColor(.textPrimary)
                }
            }
        }
    }

    // MARK: - Settings Section

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
                    TextField("2", text: $viewModel.lowStockThresholdString)
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

                Toggle("", isOn: $viewModel.autoDecrementEnabled)
                    .labelsHidden()
                    .tint(.accentPrimary)
            }
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            viewModel.saveInventory()
        } label: {
            Text(viewModel.editingInventory == nil ? "Add Inventory" : "Save Changes")
                .primaryButtonStyle()
        }
        .disabled(!viewModel.canSaveInventory)
        .opacity(viewModel.canSaveInventory ? 1 : 0.5)
    }
}

// MARK: - Compound Select Chip

struct CompoundSelectChip: View {
    let compound: Compound
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: compound.category.icon)
                    .font(.caption)
                Text(compound.name ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : .textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? compound.category.color : Color.backgroundSecondary)
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview

#Preview {
    InventoryView()
        .preferredColorScheme(.dark)
}
