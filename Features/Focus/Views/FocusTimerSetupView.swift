import SwiftUI
import SwiftData

struct FocusTimerSetupView: View {
    @ObservedObject var manager: FocusSessionManager
    var onDismiss: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPreset = "45"
    @State private var customMinutes = 45
    @State private var label = ""
    @State private var selectedTaskID: UUID?
    @State private var startProtection = true

    @Query private var tasks: [StudyTask]

    private let presets = ["25", "45", "50"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Duration") {
                    Picker("Duration", selection: $selectedPreset) {
                        ForEach(presets, id: \.self) { preset in
                            Text("\(preset) minutes").tag(preset)
                        }
                        Text("Custom").tag("custom")
                    }
                    .pickerStyle(.segmented)

                    if selectedPreset == "custom" {
                        Stepper("\(customMinutes) minutes", value: $customMinutes, in: 5...180, step: 5)
                    }
                }

                Section("What are you focusing on?") {
                    TextField("Label (optional)", text: $label)

                    Picker("Task (optional)", selection: $selectedTaskID) {
                        Text("None").tag(UUID?.none)
                        ForEach(tasks.filter { $0.status != .completed }) { task in
                            Text(task.title).tag(task.id as UUID?)
                        }
                    }
                }

                Section {
                    Toggle("Apply focus protection", isOn: $startProtection)
                } header: {
                    Text("Blocking")
                } footer: {
                    Text("Focus protection restricts the apps you selected while the session runs. It uses Apple's Screen Time APIs.")
                }
            }
            .navigationTitle("New Focus Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") { startSession() }
                }
            }
        }
    }

    private var effectiveMinutes: Int {
        selectedPreset == "custom" ? customMinutes : Int(selectedPreset) ?? 45
    }

    private func startSession() {
        let session = manager.startSession(plannedMinutes: effectiveMinutes, label: label.isEmpty ? nil : label)
        if let selectedTaskID,
           let task = tasks.first(where: { $0.id == selectedTaskID }) {
            session.task = task
            session.topic = task.topic
            session.subject = task.subject
            task.status = .inProgress
        }
        modelContext.insert(session)

        if startProtection {
            try? sessionContextProtection()
        }

        onDismiss?()
        dismiss()
    }

    private func sessionContextProtection() {
        let blocking = FocusBlockingService()
        blocking.applyRestriction()
    }
}