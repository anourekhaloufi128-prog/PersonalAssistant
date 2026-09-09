import SwiftUI
import SwiftData
import FamilyControls

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var permissionCenter = PermissionCenter()
    @StateObject private var focusProtection = FocusBlockingService()
    @State private var showingExport = false
    @State private var showingPrivacy = false

    var body: some View {
        Form {
            Section("Setup") {
                NavigationLink {
                    SetupCenterView()
                } label: {
                    Label("Setup Center", systemImage: "checklist")
                }
                NavigationLink {
                    PermissionCenterView(permissionCenter: permissionCenter)
                } label: {
                    Label("Permissions", systemImage: "lock.shield")
                }
                NavigationLink {
                    BlockingSetupView(service: focusProtection)
                } label: {
                    Label("Focus Protection", systemImage: "timer")
                }
            }

            Section("Data") {
                Button {
                    showingExport = true
                } label: {
                    Label("Export All Data", systemImage: "square.and.arrow.up")
                }
                NavigationLink {
                    PrivacyDashboardView()
                } label: {
                    Label("Privacy Dashboard", systemImage: "hand.raised.fill")
                }
                Button("Delete Account", role: .destructive) {
                    // Confirms before deleting cloud + local data.
                }
            }

            Section("Preferences") {
                NavigationLink {
                    NotificationPreferenceView()
                } label: {
                    Label("Notifications", systemImage: "bell.badge.fill")
                }
                NavigationLink {
                    AppearanceSettingsView()
                } label: {
                    Label("Appearance", systemImage: "paintpalette")
                }
            }

            Section("Help") {
                Label("App Version \(AppConfiguration.appVersion) (\(AppConfiguration.buildNumber))",
                      systemImage: "info.circle")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingExport) {
            DataExportView()
        }
        .onAppear {
            permissionCenter.refresh()
        }
    }
}

struct SetupCenterView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var focusProtection = FocusBlockingService()

    @Query private var subjects: [Subject]
    @Query private var notificationPreferences: [NotificationPreference]

    var body: some View {
        Form {
            Section("Your Progress") {
                SetupRow(label: "Profile", status: status(of: profileConfigured), icon: "person.fill")
                SetupRow(label: "Subjects", status: status(of: !subjects.isEmpty), icon: "books.vertical.fill")
                SetupRow(label: "Notifications", status: status(of: !notificationPreferences.isEmpty), icon: "bell.fill")
                SetupRow(label: "Focus Protection", status: status(of: focusProtection.authorizationState == .authorized), icon: "shield.lefthalf.filled")
                SetupRow(label: "AI", status: status(of: AppConfiguration.isAIEnabled), icon: "sparkles")
                SetupRow(label: "Cloud Sync", status: .incomplete, icon: "icloud.fill")
            }
        }
        .navigationTitle("Setup Center")
        .onAppear {
            focusProtection.refreshAuthorizationState()
        }
    }

    private var profileConfigured: Bool {
        (try? modelContext.fetchCount(FetchDescriptor<UserProfile>())) ?? 0 > 0
    }

    private func status(of configured: Bool) -> SetupStatus {
        configured ? .complete : .warning
    }
}

enum SetupStatus {
    case complete
    case warning
    case incomplete

    var symbol: String {
        switch self {
        case .complete: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .incomplete: return "circle"
        }
    }

    var color: Color {
        switch self {
        case .complete: return .green
        case .warning: return .orange
        case .incomplete: return .secondary
        }
    }
}

struct SetupRow: View {
    let label: String
    let status: SetupStatus
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 28)
            Text(label)
            Spacer()
            Image(systemName: status.symbol)
                .foregroundStyle(status.color)
        }
    }
}

struct PermissionCenterView: View {
    @ObservedObject var permissionCenter: PermissionCenter

    var body: some View {
        List {
            Section {
                PermissionRow(
                    title: "Notifications",
                    description: "Used for study, exam, habit, water, and business reminders.",
                    statusLabel: statusLabel(for: permissionCenter.status.notifications),
                    isEnabled: permissionCenter.status.notifications == .enabled
                )
            }
            Section {
                PermissionRow(
                    title: "Focus Protection (Screen Time)",
                    description: "Requires Apple authorization. Restricts selected apps during focus sessions.",
                    statusLabel: "Not configured",
                    isEnabled: false
                )
                PermissionRow(
                    title: "Health (HealthKit)",
                    description: "Optional. Requests the minimum sleep and activity permissions if enabled.",
                    statusLabel: "Not configured",
                    isEnabled: false
                )
            }

            Section {
                Text("Permissions are requested only when you enable the related feature. You can always revoke access in the iOS Settings app.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Permissions")
        .onAppear {
            permissionCenter.refresh()
        }
    }

    private func statusLabel(for status: PermissionsStatus.FeatureStatus) -> String {
        switch status {
        case .enabled: return "Enabled"
        case .disabled: return "Disabled"
        case .notConfigured: return "Not configured"
        }
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let statusLabel: String
    let isEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(statusLabel)
                    .font(.caption)
                    .foregroundStyle(isEnabled ? .green : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((isEnabled ? Color.green : Color.gray).opacity(0.15), in: Capsule())
            }
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}