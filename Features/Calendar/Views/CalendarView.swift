import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var tasks: [StudyTask]
    @Query private var exams: [Exam]
    @Query private var businessTasks: [BusinessTask]
    @State private var selectedDate = Date()

    var body: some View {
        List {
            Section("Selected Day") {
                DatePicker(
                    "Day",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
            }

            Section("Scheduled") {
                let dayTasks = tasks
                    .filter { $0.deadline.map { Calendar.current.isDate($0, inSameDayAs: selectedDate) } == true }
                    .sorted { $0.priority > $1.priority }
                let dayExams = exams
                    .filter { Calendar.current.isDate($0.examDate, inSameDayAs: selectedDate) }
                let dayBusiness = businessTasks
                    .filter { $0.dueDate.map { Calendar.current.isDate($0, inSameDayAs: selectedDate) } == true }

                if dayTasks.isEmpty && dayExams.isEmpty && dayBusiness.isEmpty {
                    Text("Nothing scheduled for \(selectedDate.formatted(date: .abbreviated, time: .omitted)).")
                        .foregroundStyle(.secondary)
                }

                ForEach(dayTasks) { task in
                    HStack {
                        Image(systemName: "checklist")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text(task.title)
                            Text("\(task.category.rawValue) task")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                ForEach(dayExams) { exam in
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundStyle(.red)
                        VStack(alignment: .leading) {
                            Text(exam.title)
                            Text("Exam")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                ForEach(dayBusiness) { task in
                    HStack {
                        Image(systemName: "briefcase")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading) {
                            Text(task.title)
                            Text("Business")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Calendar")
    }
}

struct CalendarWeekView: View {
    @Query private var tasks: [StudyTask]

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(0..<7) { offset in
                    let day = Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: Date())) ?? Date()
                    let dayTasks = tasks.filter { $0.deadline.map { Calendar.current.isDate($0, inSameDayAs: day) } == true }
                    HStack {
                        Text(day.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline.weight(.medium))
                            .frame(width: 120, alignment: .leading)
                        if dayTasks.isEmpty {
                            Text("—")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        } else {
                            Text("\(dayTasks.count) tasks")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                }
            }
            .padding(.vertical, 12)
        }
        .navigationTitle("Week Overview")
    }
}