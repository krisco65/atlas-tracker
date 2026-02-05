import SwiftUI
import LocalAuthentication

@main
struct AtlasTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage(AppConstants.UserDefaultsKeys.biometricEnabled) private var biometricEnabled = false
    @AppStorage(AppConstants.UserDefaultsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    @State private var isAuthenticated = false
    @State private var showAuthError = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !hasCompletedOnboarding {
                    OnboardingView(onComplete: {
                        hasCompletedOnboarding = true
                    })
                } else if biometricEnabled && !isAuthenticated {
                    AuthenticationView(
                        onAuthenticate: authenticate,
                        showError: showAuthError
                    )
                } else {
                    ContentView()
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                setupApp()
                if biometricEnabled {
                    authenticate()
                } else {
                    isAuthenticated = true
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                // Security: Reset authentication when app goes to background
                if newPhase == .background && biometricEnabled {
                    isAuthenticated = false
                    showAuthError = false
                }
                // Re-authenticate when returning to active
                if newPhase == .active && biometricEnabled && !isAuthenticated {
                    authenticate()
                }
            }
        }
    }

    private func setupApp() {
        // Seed database if needed
        SeedDataService.shared.seedDatabaseIfNeeded(context: CoreDataManager.shared.viewContext)

        // Request notification permissions
        Task {
            await NotificationService.shared.requestAuthorization()
        }
    }

    private func authenticate() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock Atlas Tracker"
            ) { success, error in
                DispatchQueue.main.async {
                    if success {
                        isAuthenticated = true
                        showAuthError = false
                    } else {
                        showAuthError = true
                    }
                }
            }
        } else {
            // Biometrics not available, fall back to device passcode
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock Atlas Tracker"
            ) { success, error in
                DispatchQueue.main.async {
                    if success {
                        isAuthenticated = true
                        showAuthError = false
                    } else {
                        showAuthError = true
                    }
                }
            }
        }
    }
}

// MARK: - Authentication View
struct AuthenticationView: View {
    let onAuthenticate: () -> Void
    let showError: Bool

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "faceid")
                    .font(.system(size: 64))
                    .foregroundColor(.accentPrimary)

                Text("Atlas Tracker")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                Text("Authenticate to continue")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)

                if showError {
                    Text("Authentication failed. Try again.")
                        .font(.caption)
                        .foregroundColor(.statusError)
                }

                Button {
                    onAuthenticate()
                } label: {
                    Text("Unlock")
                        .primaryButtonStyle()
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0
    @AppStorage(AppConstants.UserDefaultsKeys.preferredWeightUnit) private var preferredWeightUnit = ""

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            VStack {
                TabView(selection: $currentPage) {
                    // Welcome
                    OnboardingPage(
                        icon: "pills.fill",
                        title: "Welcome to Atlas Tracker",
                        description: "Track your supplements, peptides, and more with ease"
                    )
                    .tag(0)

                    // Features
                    OnboardingPage(
                        icon: "syringe.fill",
                        title: "Smart Injection Tracking",
                        description: "Get intelligent site rotation recommendations to prevent scar tissue buildup"
                    )
                    .tag(1)

                    // Privacy
                    OnboardingPage(
                        icon: "lock.shield.fill",
                        title: "Your Data, Your Device",
                        description: "All data stays local. No cloud sync, no tracking, complete privacy."
                    )
                    .tag(2)

                    // Weight Unit Selection
                    WeightUnitSelectionPage(
                        selectedUnit: $preferredWeightUnit,
                        onComplete: onComplete
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                if currentPage < 3 {
                    Button {
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        Text(currentPage == 2 ? "Get Started" : "Next")
                            .primaryButtonStyle()
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(.accentPrimary)

            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            Text(description)
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }
}

struct WeightUnitSelectionPage: View {
    @Binding var selectedUnit: String
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "scalemass.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentPrimary)

            Text("Choose Weight Unit")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text("Select your preferred unit for weight tracking")
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            VStack(spacing: 12) {
                ForEach(WeightUnit.allCases, id: \.self) { unit in
                    Button {
                        selectedUnit = unit.rawValue
                    } label: {
                        HStack {
                            Text(unit.displayName)
                                .font(.headline)

                            Spacer()

                            if selectedUnit == unit.rawValue {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentPrimary)
                            }
                        }
                        .foregroundColor(selectedUnit == unit.rawValue ? .textPrimary : .textSecondary)
                        .padding()
                        .background(selectedUnit == unit.rawValue ? Color.backgroundTertiary : Color.backgroundSecondary)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            Button {
                if selectedUnit.isEmpty {
                    selectedUnit = WeightUnit.lbs.rawValue
                }
                onComplete()
            } label: {
                Text("Continue")
                    .primaryButtonStyle()
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)

            Spacer()
        }
    }
}
