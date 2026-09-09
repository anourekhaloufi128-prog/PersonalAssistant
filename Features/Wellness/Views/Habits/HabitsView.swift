import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.name) private var habits: [Habit]
    @State private var showingEditor = false

    var body: some View {
        List {
            Section("Habits") {
                ForEach(habits.filter { !$0.isArchived }) { habit in
                    HabitRow(habit: habit)
                }
                .onDelete { offsets in
                    let active = habits.filter { !$0.isArchived }
                    for index in offsets {
                        modelContext.delete(active[index])
                    }
                }
            }

            Section {
                Button {
                    showingEditor = true
                } label: {
                    Label("Add Habit", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Habits")
        .sheet(isPresented: $showingEditor) {
            HabitEditorView()
        }
        .overlay {
            if habits.isEmpty {
                EmptyStateView(
                    icon: "repeat",
                    title: "No Habits",
                    message: "Build reliable routines like studying mathematics, reading, moving, or drinking water.",
                    actionTitle: "Add Habit",
                    action: { showingEditor = true }
                )
            }
        }
    }
}

struct HabitRow: View {
    let habit: Habit
    @Environment(\.modelContext) private var modelContext
    @State private var loggedToday = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                toggleToday()
            } label: {
                Image(systemName: loggedToday ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(loggedToday ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.subheadline.weight(.medium))
                Text("\(habit.frequency.rawValue) · \(habit.currentStreak)-day streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let last = habitTargetLabel {
                Text(last)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            loggedToday = habit.loggedToday
        }
    }

    private var habitTargetLabel: String? {
        let todayCount = habit.todayCount
        return "\(todayCount)/\(habit.targetCount)"
    }

    private func toggleToday() {
        loggedToday.toggle()
        if loggedToday {
            let log = HabitLog(loggedAt: Date(), count: 1)
            log.habit = habit
            modelContext.insert(log)
        } else {
            if let existing = habit.logs?.first(where: { Calendar.current.isDateInToday($0.loggedAt) }) {
                modelContext.delete(existing)
            }
        }
    }
}

extension Habit {
    var todayCount: Int {
        (logs ?? []).filter { Calendar.current.isDateInToday($0.loggedAt) }.reduce(0) { $0 + $1.count }
    }

    var loggedToday: Bool {
        (logs ?? []).contains { Calendar.current.isDateInToday($0.loggedAt) }
    }
}

struct HabitEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var habitDescription = ""
    @State private var frequency: HabitFrequency = .daily
    @State private var targetCount = 1

    var body: some View {
        NavigationStack {
            Form {
                TextField("Habit name", text: $name)
                TextField("Description (optional)", text: $habitDescription)
                Picker("Frequency", selection: $frequency) {
                    ForEach(HabitFrequency.allCases, id: \.self) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }
                Stepper("Target: \(targetCount) per \(frequency.rawValue.lowercased())", value: $targetCount, in: 1...10)
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let habit = Habit(name: name, frequency: frequency, targetCount: targetCount)
                        habit.habitDescription = habitDescription
                        modelContext.insert(habit)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}