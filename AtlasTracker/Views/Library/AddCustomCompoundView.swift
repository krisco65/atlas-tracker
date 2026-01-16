import SwiftUI

struct AddCustomCompoundView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedCategory: CompoundCategory = .supplement
    @State private var selectedUnits: Set<DosageUnit> = [.mg]
    @State private var defaultUnit: DosageUnit = .mg
    @State private var requiresInjection = false

    var canSave: Bool {
        !name.isEmpty && !selectedUnits.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Compound Name")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)

                            TextField("Enter name", text: $name)
                                .padding()
                                .background(Color.backgroundSecondary)
                                .cornerRadius(10)
                                .foregroundColor(.textPrimary)
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(CompoundCategory.allCases, id: \.self) { category in
                                    Button {
                                        selectedCategory = category
                                        // Auto-enable injection for PEDs and peptides
                                        if category == .ped || category == .peptide {
                                            requiresInjection = true
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: category.icon)
                                            Text(category.displayName)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(selectedCategory == category ? category.color : Color.backgroundSecondary)
                                        .foregroundColor(selectedCategory == category ? .white : .textSecondary)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }

                        // Dosage Units
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Supported Units")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(DosageUnit.allCases, id: \.self) { unit in
                                    Button {
                                        if selectedUnits.contains(unit) {
                                            selectedUnits.remove(unit)
                                            if defaultUnit == unit {
                                                defaultUnit = selectedUnits.first ?? .mg
                                            }
                                        } else {
                                            selectedUnits.insert(unit)
                                        }
                                    } label: {
                                        Text(unit.displayName)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(selectedUnits.contains(unit) ? Color.accentPrimary : Color.backgroundSecondary)
                                            .foregroundColor(selectedUnits.contains(unit) ? .white : .textSecondary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }

                        // Default Unit
                        if !selectedUnits.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Default Unit")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)

                                Picker("Default Unit", selection: $defaultUnit) {
                                    ForEach(Array(selectedUnits), id: \.self) { unit in
                                        Text(unit.displayName).tag(unit)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        // Requires Injection
                        Toggle(isOn: $requiresInjection) {
                            HStack {
                                Image(systemName: "syringe")
                                Text("Requires Injection")
                            }
                            .foregroundColor(.textPrimary)
                        }
                        .padding()
                        .background(Color.backgroundSecondary)
                        .cornerRadius(10)

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Compound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.addCustomCompound(
                            name: name,
                            category: selectedCategory,
                            supportedUnits: Array(selectedUnits),
                            defaultUnit: defaultUnit,
                            requiresInjection: requiresInjection
                        )
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

#Preview {
    AddCustomCompoundView(viewModel: LibraryViewModel())
        .preferredColorScheme(.dark)
}
