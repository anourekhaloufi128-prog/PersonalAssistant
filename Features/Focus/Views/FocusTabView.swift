import SwiftUI
import SwiftData

struct FocusTabView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var manager = FocusSessionManager()
    @StateObject private var blockingService = FocusBlockingService()
    @State private var showTimerSetup = false
    @State private var showActiveRecovery = false
    @State private var interruptedSession: FocusSession?

    @Query private var policies: [FocusPolicy]
    @Query private var sessions: [FocusSession]

    var body: some View {
        NavigationStack {
            List {
                if let active = sessions.first(where: { $0.isActive && $0.completion == .inProgress }) {
                    Section("Active Session") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(active.label ?? "Focus Session")
                                .font(.headline)
                            Text("Started \(active.startedAt.timeLabel)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Resume") {
                                manager.recoverInterruptedSession(active: active)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }

                Section("Quick Start") {
                    Button {
                        showTimerSetup = true
                    } label: {
                        Label("Start a Focus Session", systemImage: "play.fill")
                    }

                    NavigationLink {
                        FocusPoliciesView()
                    } label: {
                        Label("Focus Policies", systemImage: "shield.lefthalf.filled")
                    }

                    NavigationLink {
                        BlockingSetupView(service: blockingService)
                    } label: {
                        Label("Blocking Setup", systemImage: "lock.shield")
                    }
                }

                Section("Focus Protection") {
                    HStack {
                        Label("Status", systemImage: "checkmark.shield")
                        Spacer()
                        Text(blockingService.authorizationState.displayName)
                            .foregroundStyle(blockingService.authorizationState == .authorized ? .green : .orange)
                    }
                    if blockingService.authorizationState != .authorized {
                        Button("Enable in Settings") {
                            blockingService.openScreenTimeSettingsIfNeeded()
                        }
                    }
                }

                Section("Today") {
                    statRow(title: "Focus minutes", value: todaySessions.reduce(0) { $0 + $1.actualDurationMinutes }.minutesToHoursLabel)
                    statRow(title: "Sessions completed", value: "\(todaySessions.filter { $0.completion == .completed }.count)")
                }

                Section("Focus History") {
                    ForEach(sessions.prefix(10)) { session in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(session.label ?? "Focus session")
                                    .font(.subheadline.weight(.medium))
                                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(session.actualDurationMinutes) min")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Focus")
            .sheet(isPresented: $showTimerSetup) {
                FocusTimerSetupView(manager: manager) {
                    showTimerSetup = false
                }
                .environment(\.modelContext, modelContext)
            }
            .onAppear {
                blockingService.refreshAuthorizationState()
                if let interrupted = sessions.first(where: { $0.isActive && $0.completion == .inProgress }) {
                    interruptedSession = interrupted
                    showActiveRecovery = true
                }
            }
        }
    }

    private var todaySessions: [FocusSession] {
        sessions.filter { Calendar.current.isDate($0.startedAt, inSameDayAs: Date()) }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}