import SwiftUI

// MARK: - Injection Site Picker View
/// Full-screen picker for selecting injection sites with body diagram
struct InjectionSitePickerView: View {
    let compound: Compound
    @Binding var selectedSite: String?
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var injectionType: BodyDiagramView.InjectionType {
        compound.category == .ped ? .intramuscular : .subcutaneous
    }

    private var recommendedSite: String? {
        InjectionSiteRecommendationService.shared.recommendNextSiteRawValue(for: compound)
    }

    private var lastUsedSite: String? {
        InjectionSiteRecommendationService.shared.lastUsedSiteRawValue(for: compound)
    }

    private var selectedSiteDisplayName: String {
        guard let site = selectedSite else { return "None selected" }

        if compound.category == .ped {
            return PEDInjectionSite(rawValue: site)?.displayName ?? site
        } else {
            return PeptideInjectionSite(rawValue: site)?.displayName ?? site
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Recommendation Card
                        recommendationCard

                        // Body Diagram
                        BodyDiagramView(
                            injectionType: injectionType,
                            selectedSite: $selectedSite,
                            lastUsedSite: lastUsedSite,
                            recommendedSite: recommendedSite
                        )

                        // Site History
                        siteHistorySection

                        // Confirm Button
                        confirmButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Injection Site")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Recommendation Card
    private var recommendationCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(.statusSuccess)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Recommended Site")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)

                    if let site = recommendedSite {
                        let displayName = compound.category == .ped
                            ? PEDInjectionSite(rawValue: site)?.displayName ?? site
                            : PeptideInjectionSite(rawValue: site)?.displayName ?? site

                        Text(displayName)
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                    } else {
                        Text("Any site")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                    }
                }

                Spacer()

                if let site = recommendedSite {
                    Button {
                        selectedSite = site
                        HapticManager.mediumImpact()
                    } label: {
                        Text("Use")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.statusSuccess)
                            .cornerRadius(8)
                    }
                }
            }

            if let lastSite = lastUsedSite {
                let displayName = compound.category == .ped
                    ? PEDInjectionSite(rawValue: lastSite)?.displayName ?? lastSite
                    : PeptideInjectionSite(rawValue: lastSite)?.displayName ?? lastSite

                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.statusWarning)
                        .font(.caption)

                    Text("Last used: \(displayName)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }

    // MARK: - Site History Section
    private var siteHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Injection Sites")
                .font(.headline)
                .foregroundColor(.textPrimary)

            let history = InjectionSiteRecommendationService.shared.recentSiteHistory(for: compound, limit: 5)

            if history.isEmpty {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.textTertiary)
                    Text("No injection history yet")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.backgroundSecondary)
                .cornerRadius(8)
            } else {
                ForEach(history, id: \.date) { entry in
                    HStack {
                        Circle()
                            .fill(compound.category.color)
                            .frame(width: 8, height: 8)

                        Text(entry.displayName)
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)

                        Spacer()

                        Text(entry.date.relativeDateString)
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.backgroundSecondary)
                    .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Confirm Button
    private var confirmButton: some View {
        Button {
            onConfirm()
            dismiss()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Confirm: \(selectedSiteDisplayName)")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedSite != nil ? Color.accentPrimary : Color.backgroundTertiary)
            .foregroundColor(selectedSite != nil ? .white : .textSecondary)
            .cornerRadius(12)
        }
        .disabled(selectedSite == nil)
    }
}

#Preview {
    InjectionSitePickerView(
        compound: Compound.preview,
        selectedSite: .constant("glute_left"),
        onConfirm: {}
    )
    .preferredColorScheme(.dark)
}
