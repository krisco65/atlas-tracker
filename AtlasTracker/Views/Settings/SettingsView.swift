import SwiftUI

struct SettingsView: View {
    @AppStorage(AppConstants.UserDefaultsKeys.biometricEnabled) private var biometricEnabled = false
    @AppStorage(AppConstants.UserDefaultsKeys.notificationsEnabled) private var notificationsEnabled = true
    @AppStorage(AppConstants.UserDefaultsKeys.discreetNotifications) private var discreetNotifications = false
    @AppStorage(AppConstants.UserDefaultsKeys.preferredWeightUnit) private var preferredWeightUnit = WeightUnit.lbs.rawValue

    @State private var showResetConfirmation = false
    @State private var notificationCount = 0
    @State private var showReconstitutionCalculator = false
    @State private var isHealthKitAuthorized = false
    @State private var isImportingFromHealth = false
    @State private var healthImportCount = 0
    @State private var showHealthImportResult = false
    @State private var showHealthKitError = false
    @State private var healthKitErrorMessage = ""
    @State private var isConnectingHealthKit = false
    @State private var isExporting = false
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var showExportError = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()

                List {
                    // Security Section
                    Section {
                        Toggle(isOn: $biometricEnabled) {
                            Label("Face ID / Touch ID", systemImage: "faceid")
                        }
                        .tint(.accentPrimary)
                    } header: {
                        Text("Security")
                    } footer: {
                        Text("Require biometric authentication every time you open the app")
                    }

                    // Notifications Section
                    Section {
                        Toggle(isOn: $notificationsEnabled) {
                            Label("Enable Notifications", systemImage: "bell.fill")
                        }
                        .tint(.accentPrimary)
                        .onChange(of: notificationsEnabled) { newValue in
                            if newValue {
                                Task {
                                    await NotificationService.shared.requestAuthorization()
                                }
                            }
                        }

                        Toggle(isOn: $discreetNotifications) {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Discreet Mode", systemImage: "eye.slash")
                                Text("Hide compound names in notifications")
                                    .font(.caption)
                                    .foregroundColor(.textTertiary)
                            }
                        }
                        .tint(.accentPrimary)
                        .onChange(of: discreetNotifications) { _ in
                            // Reschedule all notifications with new format
                            NotificationService.shared.rescheduleAllNotifications()
                        }

                        HStack {
                            Label("Scheduled Notifications", systemImage: "calendar.badge.clock")
                            Spacer()
                            Text("\(notificationCount)")
                                .foregroundColor(.textSecondary)
                        }
                    } header: {
                        Text("Notifications")
                    } footer: {
                        if discreetNotifications {
                            Text("Notifications will show \"Dose Reminder\" instead of compound names for privacy.")
                        }
                    }

                    // Units Section
                    Section {
                        Picker(selection: $preferredWeightUnit) {
                            ForEach(WeightUnit.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit.rawValue)
                            }
                        } label: {
                            Label("Weight Unit", systemImage: "scalemass")
                        }
                    } header: {
                        Text("Units")
                    }

                    // Tools Section
                    Section {
                        Button {
                            showReconstitutionCalculator = true
                        } label: {
                            Label("Reconstitution Calculator", systemImage: "eyedropper")
                        }
                    } header: {
                        Text("Tools")
                    } footer: {
                        Text("Calculate peptide dosing from reconstituted vials")
                    }

                    // Apple Health Section
                    Section {
                        HStack {
                            Label("Apple Health", systemImage: "heart.fill")
                                .foregroundColor(.pink)
                            Spacer()
                            if !HealthKitService.shared.isHealthKitAvailable {
                                Text("Not Available")
                                    .font(.caption)
                                    .foregroundColor(.textTertiary)
                            } else if isHealthKitAuthorized {
                                Text("Connected")
                                    .font(.caption)
                                    .foregroundColor(.statusSuccess)
                            } else if isConnectingHealthKit {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Button("Connect") {
                                    connectToHealthKit()
                                }
                                .font(.caption)
                                .foregroundColor(.accentPrimary)
                            }
                        }

                        if isHealthKitAuthorized {
                            Button {
                                importFromHealth()
                            } label: {
                                HStack {
                                    Label("Import Weight Data", systemImage: "arrow.down.circle")
                                    Spacer()
                                    if isImportingFromHealth {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                }
                            }
                            .disabled(isImportingFromHealth)
                        }
                    } header: {
                        Text("Apple Health")
                    } footer: {
                        if HealthKitService.shared.isHealthKitAvailable {
                            Text("Sync weight entries from Apple Health to track your progress alongside your compounds.")
                        } else {
                            Text("Apple Health integration requires the HealthKit capability. This feature will be available in App Store builds.")
                        }
                    }

                    // Export Section
                    Section {
                        Button {
                            exportData()
                        } label: {
                            HStack {
                                Label("Export Dose History", systemImage: "square.and.arrow.up")
                                Spacer()
                                if isExporting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                        }
                        .disabled(isExporting)
                    } header: {
                        Text("Export")
                    } footer: {
                        Text("Export your complete dose history as a CSV file. Share with doctors or use as a backup.")
                    }

                    // Data Section
                    Section {
                        NavigationLink {
                            DataManagementView()
                        } label: {
                            Label("Data Management", systemImage: "externaldrive")
                        }

                        Button(role: .destructive) {
                            showResetConfirmation = true
                        } label: {
                            Label("Reset All Data", systemImage: "trash")
                                .foregroundColor(.statusError)
                        }
                    } header: {
                        Text("Data")
                    } footer: {
                        Text("All data is stored locally on your device. No cloud sync.")
                    }

                    // About Section
                    Section {
                        // App Logo and Name
                        HStack(spacing: 16) {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .cornerRadius(12)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Atlas Tracker")
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)
                                Text("Compound & Peptide Tracking")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                Text("Version \(AppConstants.appVersion)")
                                    .font(.caption2)
                                    .foregroundColor(.textTertiary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)

                        if let issueURL = URL(string: "https://github.com") {
                            Link(destination: issueURL) {
                                Label("Report Issue", systemImage: "ant")
                            }
                        }
                    } header: {
                        Text("About")
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadNotificationCount()
                isHealthKitAuthorized = HealthKitService.shared.isAuthorized()
            }
            .alert("Import Complete", isPresented: $showHealthImportResult) {
                Button("OK") { }
            } message: {
                Text("Imported \(healthImportCount) weight entries from Apple Health.")
            }
            .alert("Apple Health Error", isPresented: $showHealthKitError) {
                Button("OK") { }
            } message: {
                Text(healthKitErrorMessage)
            }
            .alert("Reset All Data?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    CoreDataManager.shared.resetAllData()
                    NotificationService.shared.cancelAllNotifications()
                }
            } message: {
                Text("This will permanently delete all your compounds, dose logs, and settings. This action cannot be undone.")
            }
            .sheet(isPresented: $showReconstitutionCalculator) {
                ReconstitutionCalculatorView()
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Export Failed", isPresented: $showExportError) {
                Button("OK") { }
            } message: {
                Text("No dose history to export. Start logging doses to create exportable data.")
            }
        }
    }

    private func exportData() {
        isExporting = true

        DispatchQueue.global(qos: .userInitiated).async {
            let url = DataExportService.shared.exportDoseLogsToCSV()

            DispatchQueue.main.async {
                isExporting = false

                if let exportedURL = url {
                    exportURL = exportedURL
                    showExportSheet = true
                    HapticManager.success()
                } else {
                    showExportError = true
                    HapticManager.error()
                }
            }
        }
    }

    private func loadNotificationCount() {
        NotificationService.shared.getPendingNotificationsCount { count in
            notificationCount = count
        }
    }

    private func connectToHealthKit() {
        guard HealthKitService.shared.isHealthKitAvailable else {
            healthKitErrorMessage = "Apple Health is not available on this device. HealthKit requires an iPhone or Apple Watch."
            showHealthKitError = true
            return
        }

        isConnectingHealthKit = true

        Task {
            do {
                let authorized = await HealthKitService.shared.requestAuthorization()

                await MainActor.run {
                    isConnectingHealthKit = false
                    isHealthKitAuthorized = authorized

                    if authorized {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    } else {
                        healthKitErrorMessage = "Could not connect to Apple Health. Please check that you've granted permission in Settings > Privacy > Health > Atlas Tracker."
                        showHealthKitError = true
                    }
                }
            }
        }
    }

    private func importFromHealth() {
        isImportingFromHealth = true

        Task {
            // Import last 90 days of weight data
            let startDate = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
            let count = await HealthKitService.shared.importWeightEntriesToCoreData(from: startDate, to: Date())

            await MainActor.run {
                isImportingFromHealth = false
                healthImportCount = count
                showHealthImportResult = true

                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}

struct DataManagementView: View {
    @State private var compoundCount = 0
    @State private var doseLogCount = 0
    @State private var trackedCount = 0
    @State private var showForceRefreshConfirm = false
    @State private var showRefreshSuccess = false

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            List {
                Section {
                    HStack {
                        Text("Compounds")
                        Spacer()
                        Text("\(compoundCount)")
                            .foregroundColor(.textSecondary)
                    }

                    HStack {
                        Text("Tracked Compounds")
                        Spacer()
                        Text("\(trackedCount)")
                            .foregroundColor(.textSecondary)
                    }

                    HStack {
                        Text("Dose Logs")
                        Spacer()
                        Text("\(doseLogCount)")
                            .foregroundColor(.textSecondary)
                    }
                } header: {
                    Text("Database Statistics")
                }

                Section {
                    Button {
                        SeedDataService.shared.forceSeed(context: CoreDataManager.shared.viewContext)
                        loadStats()
                    } label: {
                        Label("Re-seed Default Compounds", systemImage: "arrow.clockwise")
                    }

                    Button {
                        showForceRefreshConfirm = true
                    } label: {
                        Label("Force Refresh Database", systemImage: "arrow.triangle.2.circlepath")
                            .foregroundColor(.statusWarning)
                    }
                } header: {
                    Text("Maintenance")
                } footer: {
                    Text("Re-seed adds missing compounds. Force Refresh deletes ALL default compounds and re-imports from scratch (your custom compounds and logs are kept).")
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadStats()
        }
        .alert("Force Refresh Database?", isPresented: $showForceRefreshConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Refresh", role: .destructive) {
                forceRefreshDatabase()
            }
        } message: {
            Text("This will delete all default compounds and re-import them from scratch. Your custom compounds, tracked compounds, and dose logs will be preserved.")
        }
        .alert("Database Refreshed", isPresented: $showRefreshSuccess) {
            Button("OK") { }
        } message: {
            Text("All default compounds have been refreshed. New peptides (GLOW, MOTS-C, Retatrutide) should now be available.")
        }
    }

    private func loadStats() {
        compoundCount = CoreDataManager.shared.fetchAllCompounds().count
        trackedCount = CoreDataManager.shared.fetchTrackedCompounds(activeOnly: true).count
        doseLogCount = CoreDataManager.shared.doseCount(from: Date.distantPast, to: Date())
    }

    private func forceRefreshDatabase() {
        SeedDataService.shared.forceReseedFromScratch(context: CoreDataManager.shared.viewContext)
        loadStats()
        showRefreshSuccess = true

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
