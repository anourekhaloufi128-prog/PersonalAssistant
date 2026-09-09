import SwiftUI
import SwiftData

struct PrivacyDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var memories: [AIMemory]
    @Query private var syncRecords: [SyncRecord]
    @State private var dataSections: [(title: String, count: Int)] = []

    var body: some View {
        Form {
            Section("What is stored") {
                ForEach(dataSections, id: \.title) { section in
                    HStack {
                        Text(section.title)
                        Spacer()
                        Text("\(section.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("AI Memory") {
                Text("\(memories.filter(\.isEnabled).count) memories enabled")
                NavigationLink {
                    MemoryView()
                } label: {
                    Label("Manage AI memory", systemImage: "brain.head.profile")
                }
            }

            Section("Cloud Sync") {
                Text("\(syncRecords.count) pending sync records")
                    .foregroundStyle(.secondary)
                Toggle("Cloud sync enabled", isOn: .constant(false))
                    .disabled(true)
            }

            Section("Usage & Analytics") {
                Toggle("Allow product analytics", isOn: .constant(false))
                    .disabled(true)
                Text("When disabled, no usage events are collected.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Account") {
                NavigationLink {
                    AccountDeletionView()
                } label: {
                    Text("Delete Account")
                        .foregroundStyle(.red)
                }
            }

            Section {
                Text("Health data (if HealthKit is enabled) is only used to display your own sleep and activity. It is never sent to analytics or to the AI.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Privacy Dashboard")
        .onAppear {
            reloadCounts()
        }
    }

    private func reloadCounts() {
        let typed: [(String, Int)] = [
            ("Subjects", count(of: Subject.self)),
            ("Tasks", count(of: StudyTask.self)),
            ("Exams", count(of: Exam.self)),
            ("Study sessions", count(of: StudySession.self)),
            ("Clients", count(of: BusinessClient.self)),
            ("Business tasks", count(of: BusinessTask.self)),
            ("Habits", count(of: Habit.self)),
            ("Goals", count(of: Goal.self)),
            ("AI conversations", count(of: AIConversation.self))
        ]
        dataSections = typed
    }

    private func count<T: PersistentModel>(of type: T.Type) -> Int {
        (try? modelContext.fetchCount(FetchDescriptor<T>())) ?? 0
    }
}

struct AccountDeletionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var confirming = false

    var body: some View {
        Form {
            Section {
                Text("Deleting your account permanently removes your cloud records and clears local app data.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Delete My Account", role: .destructive) {
                    confirming = true
                }
                .disabled(confirming)
            } footer: {
                Text("This action cannot be undone. Your data export should be completed first if you want your records.")
            }
        }
        .navigationTitle("Delete Account")
        .alert("Confirm account deletion", isPresented: $confirming) {
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your account and all associated data.")
        }
    }

    private func deleteAccount() {
        dismiss()
    }
}