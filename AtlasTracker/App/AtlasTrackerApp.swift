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

    private let totalPages = 6

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < totalPages - 1 {
                        Button("Skip") {
                            withAnimation {
                                currentPage = totalPages - 1
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.textTertiary)
                        .padding(.trailing, 24)
                        .padding(.top, 16)
                    }
                }

                TabView(selection: $currentPage) {
                    // Welcome
                    OnboardingPage(
                        icon: "pills.fill",
                        iconColor: .accentPrimary,
                        title: "Welcome to Atlas",
                        subtitle: "Your Personal Compound Tracker",
                        features: [
                            OnboardingFeature(icon: "syringe.fill", text: "Log doses with one tap"),
                            OnboardingFeature(icon: "calendar.badge.clock", text: "Smart scheduling & reminders"),
                            OnboardingFeature(icon: "chart.bar.fill", text: "Track your progress over time"),
                        ]
                    )
                    .tag(0)

                    // Dose Logging
                    OnboardingPage(
                        icon: "list.clipboard.fill",
                        iconColor: .accentSecondary,
                        title: "Easy Dose Logging",
                        subtitle: "Track Every Dose",
                        features: [
                            OnboardingFeature(icon: "hand.tap.fill", text: "Tap to log from your daily schedule"),
                            OnboardingFeature(icon: "pencil.and.list.clipboard", text: "Record dose, site, and notes"),
                            OnboardingFeature(icon: "clock.arrow.circlepath", text: "Edit or delete past entries anytime"),
                        ]
                    )
                    .tag(1)

                    // Injection Sites
                    OnboardingPage(
                        icon: "figure.stand",
                        iconColor: .categoryPED,
                        title: "Injection Site Rotation",
                        subtitle: "Interactive Body Maps",
                        features: [
                            OnboardingFeature(icon: "person.fill", text: "Visual body maps for IM & SubQ"),
                            OnboardingFeature(icon: "arrow.triangle.2.circlepath", text: "Smart rotation recommendations"),
                            OnboardingFeature(icon: "shield.checkered", text: "Prevent tissue buildup"),
                        ]
                    )
                    .tag(2)

                    // Calculator
                    OnboardingPage(
                        icon: "function",
                        iconColor: .categoryPeptide,
                        title: "Reconstitution Calculator",
                        subtitle: "Perfect Dosing Every Time",
                        features: [
                            OnboardingFeature(icon: "eyedropper", text: "Enter vial size, dose & syringe units"),
                            OnboardingFeature(icon: "drop.fill", text: "Calculates BAC water to add"),
                            OnboardingFeature(icon: "star.fill", text: "Presets for popular peptides"),
                        ]
                    )
                    .tag(3)

                    // Privacy
                    OnboardingPage(
                        icon: "lock.shield.fill",
                        iconColor: .statusSuccess,
                        title: "100% Private",
                        subtitle: "Your Data Never Leaves Your Device",
                        features: [
                            OnboardingFeature(icon: "iphone.and.arrow.forward", text: "Everything stored locally"),
                            OnboardingFeature(icon: "faceid", text: "Face ID / Touch ID protection"),
                            OnboardingFeature(icon: "xmark.icloud", text: "No cloud, no analytics, no tracking"),
                        ]
                    )
                    .tag(4)

                    // Weight Unit Selection (final setup step)
                    WeightUnitSelectionPage(
                        selectedUnit: $preferredWeightUnit,
                        onComplete: onComplete
                    )
                    .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                if currentPage < totalPages - 1 {
                    Button {
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        Text("Next")
                            .primaryButtonStyle()
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

struct OnboardingFeature {
    let icon: String
    let text: String
}

struct OnboardingPage: View {
    let icon: String
    var iconColor: Color = .accentPrimary
    let title: String
    var subtitle: String = ""
    var features: [OnboardingFeature] = []

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(iconColor)
                .padding(.bottom, 8)

            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if !features.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(features.indices, id: \.self) { index in
                        HStack(spacing: 14) {
                            Image(systemName: features[index].icon)
                                .font(.body)
                                .foregroundColor(iconColor)
                                .frame(width: 28)

                            Text(features[index].text)
                                .font(.body)
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 12)
            }

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
