import SwiftUI
import SwiftData

struct WellnessTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @Query private var waterLogs: [WaterLog]
    @Query private var exerciseLogs: [ExerciseLog]
    @Query private var moodLogs: [MoodLog]
    @Query private var sleepLogs: [SleepLog]

    var body: some View {
        NavigationStack {
            List {
                Section("Today") {
                    HStack {
                        StatCard(title: "Water", value: "\(waterToday)ml", icon: "drop.fill", color: .blue)
                        StatCard(title: "Exercise", value: "\(exerciseMinutesToday) min", icon: "figure.run", color: .green)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section("Log") {
                    NavigationLink {
                        WaterView()
                    } label: {
                        Label("Water", systemImage: "drop.fill")
                    }
                    NavigationLink {
                        ExerciseView()
                    } label: {
                        Label("Exercise", systemImage: "figure.run")
                    }
                    NavigationLink {
                        SleepView()
                    } label: {
                        Label("Sleep", systemImage: "bed.double.fill")
                    }
                    NavigationLink {
                        MoodView()
                    } label: {
                        Label("Mood & Energy", systemImage: "face.smiling")
                    }
                    NavigationLink {
                        HabitsView()
                    } label: {
                        Label("Habits", systemImage: "repeat")
                    }
                }

                Section("Habits Today") {
                    ForEach(habits.filter { !$0.isArchived }.prefix(8)) { habit in
                        HabitRow(habit: habit)
                    }
                }
            }
            .navigationTitle("Wellness")
        }
    }

    private var waterToday: Int {
        waterLogs.filter { Calendar.current.isDateInToday($0.loggedAt) }.reduce(0) { $0 + $1.amountML }
    }

    private var exerciseMinutesToday: Int {
        exerciseLogs.filter { Calendar.current.isDate($0.exerciseDate, inSameDayAs: Date()) }.reduce(0) { $0 + $1.durationMinutes }
    }
}