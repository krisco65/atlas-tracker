import SwiftUI

struct EditDoseLogSheet: View {
    let log: DoseLog
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var dosageAmount: String = ""
    @State private var selectedUnit: DosageUnit = .mg
    @State private var selectedInjectionSite: String?
    @State private var selectedSideEffects: [SideEffect] = []
    @State private var timestamp: Date = Date()
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()
                    .onTapGesture { hideKeyboard() }

                ScrollView {
                    VStack(spacing: 20) {
                        // Compound (read-only)
                        compoundHeader

                        // Dosage
                        dosageSection

                        // Injection site
                        if log.compound?.requiresInjection == true {
                            injectionSiteSection
                        }

                        // Side effects
                        sideEffectsSection

                        // Date/Time
                        dateTimeSection

                        // Notes
                        notesSection

                        // Save button
                        saveButton

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Edit Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { hideKeyboard() }
                        .foregroundColor(.accentPrimary)
                }
            }
            .onAppear { populateFromLog() }
        }
    }

    // MARK: - Populate from existing log

    private func populateFromLog() {
        dosageAmount = log.dosageAmount.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", log.dosageAmount)
            : String(format: "%.2f", log.dosageAmount)
        selectedUnit = log.dosageUnit
        selectedInjectionSite = log.injectionSiteRaw
        selectedSideEffects = log.sideEffects
        timestamp = log.timestamp ?? Date()
        notes = log.notes ?? ""
    }

    // MARK: - Compound Header

    private var compoundHeader: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(log.compound?.category.color ?? .gray)
                .frame(width: 12, height: 12)

            Text(log.compound?.name ?? "Unknown")
                .font(.headline)
                .foregroundColor(.textPrimary)

            Spacer()

            Text(log.compound?.category.displayName ?? "")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }

    // MARK: - Dosage Section

    private var dosageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dosage")
                .font(.headline)
                .foregroundColor(.textPrimary)

            HStack(spacing: 12) {
                TextField("Amount", text: $dosageAmount)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color.backgroundSecondary)
                    .cornerRadius(10)
                    .foregroundColor(.textPrimary)

                Picker("Unit", selection: $selectedUnit) {
                    ForEach(log.compound?.supportedUnits ?? DosageUnit.allCases, id: \.self) { unit in
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Injection Site")
                .font(.headline)
                .foregroundColor(.textPrimary)

            let groups = injectionSiteGroups
            ForEach(groups, id: \.name) { group in
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.name)
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    FlowLayout(spacing: 6) {
                        ForEach(group.sites, id: \.rawValue) { site in
                            Button {
                                selectedInjectionSite = site.rawValue
                                HapticManager.selectionChanged()
                            } label: {
                                Text(site.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(selectedInjectionSite == site.rawValue
                                                ? Color.accentPrimary : Color.backgroundTertiary)
                                    .foregroundColor(selectedInjectionSite == site.rawValue
                                                     ? .white : .textSecondary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }

    private var injectionSiteGroups: [(name: String, sites: [(rawValue: String, displayName: String)])] {
        guard let compound = log.compound else { return [] }
        switch compound.category {
        case .ped:
            return PEDInjectionSite.grouped.map { group in
                (name: group.name, sites: group.sites.map { ($0.rawValue, $0.displayName) })
            }
        case .peptide:
            return PeptideInjectionSite.grouped.map { group in
                (name: group.name, sites: group.sites.map { ($0.rawValue, $0.displayName) })
            }
        default:
            return []
        }
    }

    // MARK: - Side Effects Section

    private var sideEffectsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Side Effects")
                .font(.headline)
                .foregroundColor(.textPrimary)

            FlowLayout(spacing: 6) {
                ForEach(SideEffect.common) { effect in
                    SideEffectChip(
                        effect: effect,
                        isSelected: selectedSideEffects.contains(effect)
                    ) {
                        toggleSideEffect(effect)
                    }
                }
            }
        }
    }

    private func toggleSideEffect(_ effect: SideEffect) {
        if effect == .none {
            selectedSideEffects = [.none]
        } else {
            selectedSideEffects.removeAll { $0 == .none }
            if selectedSideEffects.contains(effect) {
                selectedSideEffects.removeAll { $0 == effect }
            } else {
                selectedSideEffects.append(effect)
            }
        }
        HapticManager.lightImpact()
    }

    // MARK: - Date/Time Section

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date & Time")
                .font(.headline)
                .foregroundColor(.textPrimary)

            DatePicker(
                "When",
                selection: $timestamp,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(10)
        }
    }

    // MARK: - Notes Section

    private let maxNotesLength = 500

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Notes")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(notes.count)/\(maxNotesLength)")
                    .font(.caption2)
                    .foregroundColor(notes.count > maxNotesLength ? .statusError : .textTertiary)
            }

            TextField("Add any notes...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .padding()
                .background(Color.backgroundSecondary)
                .cornerRadius(10)
                .foregroundColor(.textPrimary)
                .onChange(of: notes) {
                    if notes.count > maxNotesLength {
                        notes = String(notes.prefix(maxNotesLength))
                    }
                }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            saveChanges()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Save Changes")
            }
            .primaryButtonStyle()
        }
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.5)
    }

    private var canSave: Bool {
        guard let amount = Double(dosageAmount), amount > 0, amount <= 10000 else { return false }
        if log.compound?.requiresInjection == true && selectedInjectionSite == nil { return false }
        return true
    }

    private func saveChanges() {
        guard let amount = Double(dosageAmount) else { return }

        log.dosageAmount = amount
        log.dosageUnit = selectedUnit
        log.injectionSiteRaw = selectedInjectionSite
        log.timestamp = timestamp
        log.notes = notes.isEmpty ? nil : notes

        let effects = selectedSideEffects.isEmpty || selectedSideEffects == [.none]
            ? nil : selectedSideEffects
        log.sideEffects = effects ?? []

        CoreDataManager.shared.saveContext()

        HapticManager.success()
        onSave()
        dismiss()
    }
}
