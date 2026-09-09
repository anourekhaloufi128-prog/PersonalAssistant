import SwiftUI
import SwiftData

struct FocusPoliciesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var policies: [FocusPolicy]
    @State private var showingEditor = false

    var body: some View {
        List {
            Section {
                ForEach(policies) { policy in
                    NavigationLink {
                        FocusPolicyDetailView(policy: policy)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(policy.name)
                                .font(.headline)
                            Text("\(policy.sessionDurationMinutes) min focus · \(policy.breakDurationMinutes) min break")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deletePolicies)
            } header: {
                Text("Policies")
            } footer: {
                Text("Each policy defines a focus duration, break length, blocked apps, and whether temporary unlocks are allowed.")
            }

            Section {
                Button {
                    showingEditor = true
                } label: {
                    Label("New Policy", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Focus Policies")
        .sheet(isPresented: $showingEditor) {
            FocusPolicyEditorView()
        }
        .overlay {
            if policies.isEmpty {
                EmptyStateView(
                    icon: "shield.lefthalf.filled",
                    title: "No Focus Policies",
                    message: "Create a policy to pair a focus duration with a set of blocked apps.",
                    actionTitle: "Create Policy",
                    action: { showingEditor = true }
                )
            }
        }
    }

    private func deletePolicies(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(policies[index])
        }
    }
}

struct FocusPolicyDetailView: View {
    let policy: FocusPolicy
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            Section("Duration") {
                LabeledContent("Focus", value: "\(policy.sessionDurationMinutes) min")
                LabeledContent("Break", value: "\(policy.breakDurationMinutes) min")
            }

            Section("Blocking") {
                if let apps = policy.blockedApps, !apps.isEmpty {
                    ForEach(apps) { app in
                        LabeledContent(app.displayName, value: app.isEnabled ? "Blocked" : "Allowed")
                    }
                } else {
                    Text("No blocked apps configured. Configure blocking in Settings > Focus Protection.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Policy") {
                Toggle("Allow emergency unlock", isOn: Binding(
                    get: { policy.allowEmergencyUnlock },
                    set: { policy.allowEmergencyUnlock = $0 }
                ))
                Toggle("Only apply during schedule", isOn: Binding(
                    get: { policy.appliesOnlyDuringSchedule },
                    set: { policy.appliesOnlyDuringSchedule = $0 }
                ))
                if policy.appliesOnlyDuringSchedule, let start = policy.scheduleStart, let end = policy.scheduleEnd {
                    LabeledContent("Schedule", value: "\(start):00 – \(end):00")
                }
            }

            Section {
                Button("Delete Policy", role: .destructive) {
                    modelContext.delete(policy)
                }
            }
        }
        .navigationTitle(policy.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FocusPolicyEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = "Focus Session"
    @State private var sessionDuration = 45
    @State private var breakDuration = 10
    @State private var allowEmergencyUnlock = true

    var body: some View {
        NavigationStack {
            Form {
                TextField("Policy name", text: $name)
                Stepper("Focus: \(sessionDuration) min", value: $sessionDuration, in: 5...120, step: 5)
                Stepper("Break: \(breakDuration) min", value: $breakDuration, in: 5...60, step: 5)
                Toggle("Allow emergency unlock", isOn: $allowEmergencyUnlock)
            }
            .navigationTitle("New Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        let policy = FocusPolicy(name: name, sessionDurationMinutes: sessionDuration, breakDurationMinutes: breakDuration)
        policy.allowEmergencyUnlock = allowEmergencyUnlock
        modelContext.insert(policy)
        dismiss()
    }
}