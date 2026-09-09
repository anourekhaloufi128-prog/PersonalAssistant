import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @State private var step = 0

    var body: some View {
        NavigationStack {
            TabView(selection: $step) {
                OnboardingIntroView(onContinue: { step = 1 })
                    .tag(0)
                OnboardingFocusView(onFinish: { finish() })
                    .tag(1)
            }
            .tabViewStyle(.page)
        }
    }

    private func finish() {
        createProfile()
        appState.currentTab = .home
        appState.showOnboarding = false
    }

    private func createProfile() {
        let profile = UserProfile(name: "You")
        profile.onboardingCompleted = true
        let settings = AppSettings()
        settings.userProfile = profile
        modelContext.insert(profile)
        modelContext.insert(settings)
        try? modelContext.save()

        NotificationPreferenceSeeder.seedIfNeeded(into: modelContext)
        appState.currentUser = profile
    }
}

private enum NotificationPreferenceSeeder {
    static func seedIfNeeded(into context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<NotificationPreference>())) ?? 0
        guard existing == 0 else { return }
        for type in NotificationType.allCases {
            context.insert(NotificationPreference(type: type, isEnabled: true))
        }
    }
}

struct OnboardingIntroView: View {
    var onContinue: (() -> Void)

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("Your Personal Operating System")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text("Study, focus, wellness, business and personal goals in one calm daily experience.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 10) {
                Label("What should I do now?", systemImage: "checkmark.circle")
                Label("AI planning that adapts to you", systemImage: "brain.head.profile")
                Label("Focus protection with Screen Time", systemImage: "shield.lefthalf.filled")
                Label("Private by default", systemImage: "hand.raised")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Spacer()

            Button("Get Started", action: onContinue)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)

            Text("Data stays on your device. Cloud sync and AI are optional and explained before you enable them.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }
}

struct OnboardingFocusView: View {
    var onFinish: (() -> Void)
    @State private var wantsStudy = true
    @State private var wantsFocus = true
    @State private var wantsWellness = true
    @State private var wantsBusiness = true
    @State private var wantsGoals = true

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("What do you want help with?")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                FeatureToggleRow(title: "Study", icon: "graduationcap.fill", isOn: $wantsStudy)
                FeatureToggleRow(title: "Focus", icon: "timer", isOn: $wantsFocus)
                FeatureToggleRow(title: "Wellness", icon: "heart.fill", isOn: $wantsWellness)
                FeatureToggleRow(title: "Business", icon: "briefcase.fill", isOn: $wantsBusiness)
                FeatureToggleRow(title: "Goals", icon: "target", isOn: $wantsGoals)
            }
            .padding(.horizontal, 24)

            Text("You can change any of this later in Settings. Your first plan will be created right after this.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Button("Start My Day", action: onFinish)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
        }
    }
}

struct FeatureToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 34, height: 34)
                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(12)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14))
    }
}