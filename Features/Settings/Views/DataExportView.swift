import SwiftUI
import SwiftData

private struct ExportPayload: Codable {
    var exportDate: Date
    var subjects: [SubjectDTO]
    var tasks: [TaskDTO]
    var businessClients: [ClientDTO]
    var habits: [HabitDTO]
    var goals: [GoalDTO]
    var appVersion: String
}

private struct SubjectDTO: Codable {
    var name: String
    var difficulty: String
    var weeklyTargetMinutes: Int
}

private struct TaskDTO: Codable {
    var title: String
    var category: String
    var priority: String
    var status: String
    var estimatedMinutes: Int
    var deadline: Date?
}

private struct ClientDTO: Codable {
    var name: String
    var company: String
    var status: String
}

private struct HabitDTO: Codable {
    var name: String
    var frequency: String
    var streak: Int
}

private struct GoalDTO: Codable {
    var name: String
    var type: String
    var progress: Double
}

struct DataExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var json = ""
    @State private var isPreparing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("Export your data as JSON")
                    .font(.headline)

                Text("This includes your study, task, business, habit, and goal records. It is written to a file you can keep or move to another iPhone.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if isPreparing {
                    ActivityIndicatorView(style: .medium)
                }

                Button {
                    prepareExport()
                } label: {
                    Text("Generate Export")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isPreparing)

                if !json.isEmpty {
                    ShareLink(item: jsonData, preview: SharePreview("My Personal Assistant Data")) {
                        Label("Share Export", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button("Show JSON") { showingJSON = true }
                        .sheet(isPresented: $showingJSON) {
                            ScrollView {
                                Text(json)
                                    .font(.caption2)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                            }
                            .presentationDetents([.medium, .large])
                        }
                }

                Text("Deleting your account uses the same data flow: confirm first, then local data is cleared and cloud records are removed per our retention policy.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Done") { dismiss() }
                    .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Data Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @State private var showingJSON = false

    private var jsonData: Data {
        json.data(using: .utf8) ?? Data()
    }

    private func prepareExport() {
        isPreparing = true
        let subjects = (try? modelContext.fetch(FetchDescriptor<Subject>())) ?? []
        let tasks = (try? modelContext.fetch(FetchDescriptor<StudyTask>())) ?? []
        let clients = (try? modelContext.fetch(FetchDescriptor<BusinessClient>())) ?? []
        let habits = (try? modelContext.fetch(FetchDescriptor<Habit>())) ?? []
        let goals = (try? modelContext.fetch(FetchDescriptor<Goal>())) ?? []

        let payload = ExportPayload(
            exportDate: Date(),
            subjects: subjects.map { SubjectDTO(name: $0.name, difficulty: $0.difficulty.rawValue, weeklyTargetMinutes: $0.weeklyTargetMinutes) },
            tasks: tasks.map { TaskDTO(title: $0.title, category: $0.category.rawValue, priority: $0.priority.rawValue, status: $0.status.rawValue, estimatedMinutes: $0.estimatedMinutes, deadline: $0.deadline) },
            businessClients: clients.map { ClientDTO(name: $0.name, company: $0.company, status: $0.status.rawValue) },
            habits: habits.map { HabitDTO(name: $0.name, frequency: $0.frequency.rawValue, streak: $0.currentStreak) },
            goals: goals.map { GoalDTO(name: $0.name, type: $0.goalType.rawValue, progress: $0.progress) },
            appVersion: AppConfiguration.appVersion
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        if let data = try? encoder.encode(payload), let string = String(data: data, encoding: .utf8) {
            json = string
        }
        isPreparing = false
    }
}