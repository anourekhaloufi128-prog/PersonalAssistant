import SwiftUI
import SwiftData

struct StudyTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudyTask.createdAt, order: .reverse) private var tasks: [StudyTask]
    @State private var showingEditor = false

    var body: some View {
        List {
            Section("Today") {
                HStack {
                    StatCard(
                        title: "Pending",
                        value: "\(tasks.filter { $0.status == .todo }.count)",
                        icon: "hourglass",
                        color: .orange
                    )
                    StatCard(
                        title: "Due today",
                        value: "\(tasks.filter { $0.deadline != nil && Calendar.current.isDateInToday($0.deadline!) }.count)",
                        icon: "clock",
                        color: .red
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                ForEach(tasks.filter { $0.status != .completed }.sorted(by: { $0.priority > $1.priority })) { task in
                    StudyTaskRow(task: task) {
                        complete(task)
                    }
                }
                .onDelete { offsets in
                    let pending = tasks.filter { $0.status != .completed }
                    for index in offsets {
                        modelContext.delete(pending[index])
                    }
                }
            } header: {
                Text("To Do")
            }

            Section {
                ForEach(tasks.filter { $0.status == .completed }.prefix(20)) { task in
                    StudyTaskRow(task: task, isCompleted: true) {}
                }
            } header: {
                Text("Completed")
            }
        }
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            TaskEditView(mode: .create)
        }
        .overlay {
            if tasks.isEmpty {
                EmptyStateView(
                    icon: "checklist",
                    title: "No Tasks",
                    message: "Add homework, revision, and study tasks to build today's plan.",
                    actionTitle: "Add Task",
                    action: { showingEditor = true }
                )
            }
        }
    }

    private func complete(_ task: StudyTask) {
        task.status = .completed
        task.completedAt = Date()
        task.updatedAt = Date()
        try? modelContext.save()
    }
}

struct StudyTaskRow: View {
    let task: StudyTask
    let isCompleted: Bool
    var onComplete: (() -> Void)

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onComplete) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                HStack(spacing: 6) {
                    if let subject = task.subject {
                        Text(subject.name)
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                    Text("\(task.estimatedMinutes) min")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let deadline = task.deadline {
                        Text(deadline.relativeDayLabel())
                            .font(.caption2)
                            .foregroundStyle(deadline < Date() && !isCompleted ? .red : .secondary)
                    }
                }
            }
            Spacer()
            PriorityBadge(priority: task.priority)
        }
        .padding(.vertical, 4)
    }
}

struct TaskEditView: View {
    enum Mode {
        case create
        case edit(StudyTask)
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var taskDescription = ""
    @State private var category: TaskCategory = .study
    @State private var priority: TaskPriority = .medium
    @State private var estimatedMinutes = 30
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(86400)
    @State private var selectedSubjectID: UUID?
    @State private var selectedTopicID: UUID?

    @Query(sort: \Subject.name) private var subjects: [Subject]

    private var taskBeingEdited: StudyTask? {
        if case .edit(let task) = mode { return task }
        return nil
    }

    init(mode: Mode) {
        self.mode = mode
        if case .edit(let task) = mode {
            _title = State(initialValue: task.title)
            _taskDescription = State(initialValue: task.taskDescription)
            _category = State(initialValue: task.category)
            _priority = State(initialValue: task.priority)
            _estimatedMinutes = State(initialValue: task.estimatedMinutes)
            _hasDeadline = State(initialValue: task.deadline != nil)
            _deadline = State(initialValue: task.deadline ?? Date().addingTimeInterval(86400))
            _selectedSubjectID = State(initialValue: task.subject?.id)
            _selectedTopicID = State(initialValue: task.topic?.id)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $taskDescription)
                }

                Section("Details") {
                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { prio in
                            Text(prio.rawValue.capitalized).tag(prio)
                        }
                    }
                    Stepper("Duration: \(estimatedMinutes) min", value: $estimatedMinutes, in: 5...480, step: 5)
                }

                if category == .study {
                    Section("Study") {
                        Picker("Subject (optional)", selection: $selectedSubjectID) {
                            Text("None").tag(UUID?.none)
                            ForEach(subjects) { subject in
                                Text(subject.name).tag(subject.id as UUID?)
                            }
                        }
                    }
                }

                Section("Deadline") {
                    Toggle("Has deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline)
                    }
                }
            }
            .navigationTitle(taskBeingEdited == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(title.isEmpty)
                }
            }
        }
    }

    private func save() {
        let task: StudyTask
        if let existing = taskBeingEdited {
            task = existing
            task.title = title
            task.taskDescription = taskDescription
            task.category = category
            task.priority = priority
            task.estimatedMinutes = estimatedMinutes
            task.deadline = hasDeadline ? deadline : nil
            task.updatedAt = Date()
        } else {
            task = StudyTask(
                title: title,
                description: taskDescription,
                category: category,
                priority: priority,
                estimatedMinutes: estimatedMinutes
            )
            task.deadline = hasDeadline ? deadline : nil
            if let selectedSubjectID {
                task.subject = subjects.first { $0.id == selectedSubjectID }
            }
            modelContext.insert(task)
        }
        try? modelContext.save()
        dismiss()
    }
}