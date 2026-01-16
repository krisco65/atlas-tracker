import SwiftUI

struct ReconstitutionCalculatorView: View {
    @StateObject private var viewModel = ReconstitutionViewModel()
    @Environment(\.dismiss) private var dismiss
    var preselectedCompound: TrackedCompound?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()
                    .onTapGesture {
                        hideKeyboard()
                    }

                VStack(spacing: 0) {
                    // PROMINENT CLOSE BUTTON HEADER - Always visible at top
                    closeButtonHeader

                    ScrollView {
                        VStack(spacing: 24) {
                            // Header info
                            headerSection

                        // Presets
                        presetsSection

                        // Input Fields
                        inputSection

                        // Auto-Suggest Button (prominent)
                        if viewModel.suggestBacWater() != nil && viewModel.bacWaterMl.isEmpty {
                            autoSuggestButton
                        }

                        // Calculate Button
                        calculateButton

                        // Results
                        if let result = viewModel.result {
                            resultsSection(result)

                            // Human-readable explanation
                            if let explanation = viewModel.explanationText {
                                explanationCard(explanation)
                            }
                        }

                        // Error Message
                        if let error = viewModel.errorMessage {
                            errorView(error)
                        }

                        // Save to Compound (if applicable)
                        if viewModel.selectedCompound != nil && viewModel.result != nil {
                            saveSection
                        }

                        // BOTTOM CLOSE BUTTON - ALWAYS VISIBLE
                        bottomCloseButton

                        Spacer(minLength: 40)
                        }
                        .padding()
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                    .foregroundColor(.accentPrimary)
                }
            }
            .onAppear {
                if let compound = preselectedCompound {
                    viewModel.loadFromCompound(compound)
                }
            }
            .sheet(isPresented: $viewModel.showBeginnerGuide) {
                BeginnerGuideView()
            }
        }
    }

    // MARK: - Close Button Header (ALWAYS VISIBLE)
    private var closeButtonHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                    Text("Close")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.accentPrimary)
            }

            Spacer()

            Text("Reconstitution Calculator")
                .font(.headline)
                .foregroundColor(.textPrimary)

            Spacer()

            HStack(spacing: 12) {
                Button {
                    viewModel.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                        .foregroundColor(.textSecondary)
                }

                Button {
                    viewModel.showBeginnerGuide = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.title3)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.backgroundSecondary)
    }

    // MARK: - Bottom Close Button (FAILSAFE - ALWAYS VISIBLE)
    private var bottomCloseButton: some View {
        Button {
            dismiss()
        } label: {
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                Text("Close Calculator")
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.statusError)
            .cornerRadius(12)
        }
        .padding(.top, 20)
    }

    // MARK: - Auto-Suggest Button
    private var autoSuggestButton: some View {
        Button {
            viewModel.autoCalculate()
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } label: {
            HStack {
                Image(systemName: "wand.and.stars")
                Text("Auto-Calculate for 25 Units/Dose")
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.categoryPeptide)
            .cornerRadius(12)
        }
    }

    // MARK: - Explanation Card
    private func explanationCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "text.bubble")
                    .foregroundColor(.accentPrimary)
                Text("Summary")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
            }

            Text(text)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "eyedropper")
                    .font(.title2)
                    .foregroundColor(.categoryPeptide)

                Text("Peptide Reconstitution")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
            }

            Text("Calculate the exact amount to draw from your reconstituted peptide vial")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }

    // MARK: - Presets Section

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Presets")
                .font(.headline)
                .foregroundColor(.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.commonPresets) { preset in
                        PresetChip(preset: preset) {
                            viewModel.applyPreset(preset)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 16) {
            // Vial Size
            inputField(
                title: "Vial Size",
                placeholder: "e.g., 5",
                value: $viewModel.vialSizeMg,
                unit: "mg",
                icon: "flask"
            )

            // BAC Water
            VStack(alignment: .leading, spacing: 8) {
                inputField(
                    title: "BAC Water Added",
                    placeholder: "e.g., 2.0",
                    value: $viewModel.bacWaterMl,
                    unit: "ml",
                    icon: "drop"
                )

                if let suggestion = viewModel.suggestBacWater(),
                   viewModel.bacWaterMl.isEmpty {
                    Button {
                        viewModel.bacWaterMl = suggestion
                        viewModel.calculate()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                            Text("Suggested: \(suggestion) ml")
                                .font(.caption)
                        }
                        .foregroundColor(.accentPrimary)
                    }
                }
            }

            // Desired Dose with unit toggle
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Desired Dose")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)

                    Spacer()

                    // Unit toggle
                    Picker("Unit", selection: $viewModel.doseUnitIsMcg) {
                        Text("mg").tag(false)
                        Text("mcg").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                }

                HStack(spacing: 12) {
                    Image(systemName: "syringe")
                        .foregroundColor(.textTertiary)
                        .frame(width: 24)

                    TextField("e.g., 250", text: $viewModel.desiredDoseMg)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.textPrimary)

                    Text(viewModel.doseUnitLabel)
                        .foregroundColor(.textSecondary)
                        .frame(width: 40)
                }
                .padding()
                .background(Color.backgroundSecondary)
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Input Field Helper

    private func inputField(title: String, placeholder: String, value: Binding<String>, unit: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.textTertiary)
                    .frame(width: 24)

                TextField(placeholder, text: value)
                    .keyboardType(.decimalPad)
                    .foregroundColor(.textPrimary)

                Text(unit)
                    .foregroundColor(.textSecondary)
                    .frame(width: 40)
            }
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(10)
        }
    }

    // MARK: - Calculate Button

    private var calculateButton: some View {
        Button {
            viewModel.calculate()
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } label: {
            HStack {
                Image(systemName: "function")
                Text("Calculate")
            }
            .primaryButtonStyle()
        }
        .disabled(!viewModel.canCalculate)
        .opacity(viewModel.canCalculate ? 1 : 0.5)
    }

    // MARK: - Results Section

    private func resultsSection(_ result: ReconstitutionResult) -> some View {
        VStack(spacing: 16) {
            // Main Result Card
            VStack(spacing: 16) {
                Text("AMOUNT TO DRAW")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(result.syringeUnitsString)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.statusSuccess)

                    VStack(alignment: .leading) {
                        Text("insulin syringe")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        Text("(\(result.volumeToDrawString))")
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                    }
                }

                // Visual syringe indicator
                SyringeVisual(units: result.syringeUnits)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color.statusSuccess.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.statusSuccess.opacity(0.3), lineWidth: 1)
            )

            // Warnings
            if result.isVolumeVerySmall {
                warningCard(
                    icon: "exclamationmark.triangle",
                    message: "Very small volume - consider using more BAC water for easier measuring",
                    color: .statusWarning
                )
            }

            if result.isVolumeLarge {
                warningCard(
                    icon: "exclamationmark.triangle",
                    message: "Large volume for SubQ injection - consider splitting into multiple injections",
                    color: .statusWarning
                )
            }

            // Additional Info Cards
            HStack(spacing: 12) {
                resultInfoCard(
                    title: "Concentration",
                    value: result.concentrationString,
                    icon: "percent"
                )

                resultInfoCard(
                    title: "Doses per Vial",
                    value: result.dosesPerVialString,
                    icon: "number"
                )
            }
        }
    }

    // MARK: - Result Info Card

    private func resultInfoCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentPrimary)

            Text(value)
                .font(.headline)
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

    // MARK: - Warning Card

    private func warningCard(icon: String, message: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(message)
                .font(.caption)
                .foregroundColor(.textSecondary)

            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.statusError)

            Text(error)
                .font(.subheadline)
                .foregroundColor(.statusError)

            Spacer()
        }
        .padding()
        .background(Color.statusError.opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - Save Section

    private var saveSection: some View {
        VStack(spacing: 12) {
            Divider()
                .background(Color.backgroundTertiary)

            if let compound = viewModel.selectedCompound?.compound {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Save to Compound")
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                        Text(compound.name ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    Button {
                        viewModel.saveToCompound()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.accentPrimary)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

// MARK: - Preset Chip

struct PresetChip: View {
    let preset: ReconstitutionViewModel.Preset
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(preset.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.backgroundSecondary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.backgroundTertiary, lineWidth: 1)
                )
        }
    }
}

// MARK: - Syringe Visual

struct SyringeVisual: View {
    let units: Double

    private var fillPercentage: Double {
        min(1.0, units / 100.0)
    }

    var body: some View {
        VStack(spacing: 4) {
            // Syringe barrel
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.backgroundTertiary)

                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.statusSuccess.opacity(0.6))
                        .frame(width: geometry.size.width * fillPercentage)

                    // Tick marks
                    HStack {
                        ForEach(0..<11) { i in
                            if i > 0 {
                                Spacer()
                            }
                            Rectangle()
                                .fill(Color.textTertiary)
                                .frame(width: 1, height: i % 5 == 0 ? 12 : 6)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .frame(height: 24)

            // Labels
            HStack {
                Text("0")
                Spacer()
                Text("50")
                Spacer()
                Text("100 units")
            }
            .font(.system(size: 10))
            .foregroundColor(.textTertiary)
        }
        .padding(.horizontal)
    }
}

// MARK: - Beginner Guide View

struct BeginnerGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("How to Reconstitute Peptides")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)

                        // Steps
                        stepCard(
                            number: 1,
                            title: "Gather Your Supplies",
                            description: "You'll need: lyophilized peptide vial, bacteriostatic (BAC) water, alcohol swabs, and insulin syringes.",
                            icon: "shippingbox"
                        )

                        stepCard(
                            number: 2,
                            title: "Clean the Vial Tops",
                            description: "Swab both the peptide vial and BAC water tops with alcohol. Let them dry for a few seconds.",
                            icon: "drop.triangle"
                        )

                        stepCard(
                            number: 3,
                            title: "Draw BAC Water",
                            description: "Using a syringe, draw your desired amount of BAC water. More water = easier to measure small doses, but larger injection volumes.",
                            icon: "syringe"
                        )

                        stepCard(
                            number: 4,
                            title: "Add Water to Peptide",
                            description: "Slowly inject the BAC water into the peptide vial, aiming at the side of the vial. Let it drip down gently - never spray directly onto the powder.",
                            icon: "arrow.down.to.line"
                        )

                        stepCard(
                            number: 5,
                            title: "Let It Dissolve",
                            description: "Gently swirl the vial (don't shake!). Most peptides dissolve within 5-10 minutes. Some may take longer.",
                            icon: "hourglass"
                        )

                        stepCard(
                            number: 6,
                            title: "Store Properly",
                            description: "Reconstituted peptides should be stored in the refrigerator. Most are stable for 4-6 weeks once reconstituted.",
                            icon: "thermometer.snowflake"
                        )

                        // Tips
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pro Tips")
                                .font(.headline)
                                .foregroundColor(.textPrimary)

                            tipRow(icon: "lightbulb.fill", text: "Use 1-2ml of BAC water per 5mg vial for easy measuring")
                            tipRow(icon: "lightbulb.fill", text: "Always use the same BAC water amount for consistency")
                            tipRow(icon: "lightbulb.fill", text: "Label your vials with the reconstitution date and concentration")
                            tipRow(icon: "lightbulb.fill", text: "Rotate injection sites to prevent tissue buildup")
                        }
                        .padding()
                        .background(Color.backgroundSecondary)
                        .cornerRadius(12)

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Beginner Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentPrimary)
                }
            }
        }
    }

    private func stepCard(number: Int, title: String, description: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number
            ZStack {
                Circle()
                    .fill(Color.categoryPeptide)
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.categoryPeptide)

                    Text(title)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                }

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.statusWarning)
                .font(.caption)

            Text(text)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    ReconstitutionCalculatorView()
        .preferredColorScheme(.dark)
}
