import SwiftUI

struct SettingsView: View {
    @AppStorage(AppConstants.UserDefaultsKeys.biometricEnabled) private var biometricEnabled = false
    @AppStorage(AppConstants.UserDefaultsKeys.notificationsEnabled) private var notificationsEnabled = true
    @AppStorage(AppConstants.UserDefaultsKeys.preferredWeightUnit) private var preferredWeightUnit = WeightUnit.lbs.rawValue

    @State private var showResetConfirmation = false
    @State private var notificationCount = 0
    @State private var showReconstitutionCalculator = false

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
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                Task {
                                    await NotificationService.shared.requestAuthorization()
                                }
                            }
                        }

                        HStack {
                            Label("Scheduled Notifications", systemImage: "calendar.badge.clock")
                            Spacer()
                            Text("\(notificationCount)")
                                .foregroundColor(.textSecondary)
                        }
                    } header: {
                        Text("Notifications")
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
                        HStack {
                            Label("Version", systemImage: "info.circle")
                            Spacer()
                            Text(AppConstants.appVersion)
                                .foregroundColor(.textSecondary)
                        }

                        Link(destination: URL(string: "https://github.com")!) {
                            Label("Report Issue", systemImage: "ant")
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
        }
    }

    private func loadNotificationCount() {
        NotificationService.shared.getPendingNotificationsCount { count in
            notificationCount = count
        }
    }
}

struct DataManagementView: View {
    @State private var compoundCount = 0
    @State private var doseLogCount = 0
    @State private var trackedCount = 0

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
                } header: {
                    Text("Maintenance")
                } footer: {
                    Text("This will re-add any deleted default compounds without affecting your custom compounds or logs.")
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
    }

    private func loadStats() {
        compoundCount = CoreDataManager.shared.fetchAllCompounds().count
        trackedCount = CoreDataManager.shared.fetchTrackedCompounds(activeOnly: true).count
        doseLogCount = CoreDataManager.shared.doseCount(from: Date.distantPast, to: Date())
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
