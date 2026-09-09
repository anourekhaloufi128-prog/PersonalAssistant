import SwiftUI
import SwiftData

struct ExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExerciseLog.exerciseDate, order: .reverse) private var logs: [ExerciseLog]
    @State private var showingLog = false
    @State private var weeklyHours = 0.0

    var body: some View {
        List {
            Section("This Week") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(weeklyHoursLabel)")
                            .font(.title.bold())
                        Spacer()
                        Text("target 150 min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: min(1, weeklyHours / 150))
                }
            }

            Section {
                Button {
                    showingLog = true
                } label: {
                    Label("Log Exercise", systemImage: "plus")
                }
            }

            Section("History") {
                ForEach(logs.prefix(20)) { log in
                    HStack {
                        Image(systemName: iconFor(log.exerciseType))
                            .foregroundStyle(.green)
                        Text(log.exerciseType.rawValue)
                            .font(.subheadline)
                        Text(log.exerciseDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(log.durationMinutes) min")
                            .font(.caption.weight(.semibold))
                    }
                }
            }
        }
        .navigationTitle("Exercise")
        .sheet(isPresented: $showingLog) {
            ExerciseLogEditorView()
        }
    }

    private var weeklyHoursLabel: String {
        let minutes = logs.prefix { Calendar.current.isDate($0.exerciseDate, inSameDayAs: Date()) || $0.exerciseDate > Date().addingTimeInterval(-7 * 86400) }
            .reduce(0) { $0 + $1.durationMinutes }
        weeklyHours = Double(minutes)
        return minutes.minutesToHoursLabel
    }

    private func iconFor(_ type: ExerciseType) -> String {
        switch type {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .sports: return "sportscourt"
        case .stretching: return "figure.flexibility"
        case .strength: return "dumbbell.fill"
        case .custom: return "figure.mixed.cardio"
        }
    }
}

struct ExerciseLogEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var type: ExerciseType = .walking
    @State private var duration = 20
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Exercise", selection: $type) {
                        ForEach(ExerciseType.allCases, id: \.self) { exercise in
                            Text(exercise.rawValue).tag(exercise)
                        }
                    }
                }
                Section("Duration") {
                    Stepper("\(duration) minutes", value: $duration, in: 5...300, step: 5)
                }
                Section {
                    TextField("Notes (optional)", text: $notes)
                }
            }
            .navigationTitle("Log Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let log = ExerciseLog(exerciseType: type, durationMinutes: duration)
                        log.notes = notes
                        modelContext.insert(log)
                        dismiss()
                    }
                }
            }
        }
    }
}