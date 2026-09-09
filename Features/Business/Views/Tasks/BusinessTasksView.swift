import SwiftUI
import SwiftData

struct BusinessTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BusinessTask.createdAt, order: .reverse) private var tasks: [BusinessTask]
    @State private var showingEditor = false

    var body: some View {
        List {
            Section("To Do") {
                ForEach(tasks.filter { $0.status == .todo }.sorted(by: { $0.priority > $1.priority })) { task in
                    HStack(spacing: 12) {
                        Button {
                            complete(task)
                        } label: {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(task.title)
                                .font(.subheadline.weight(.medium))
                            Text(task.kind.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let due = task.dueDate {
                                Text(due.relativeDayLabel())
                                    .font(.caption2)
                                    .foregroundStyle(due < Date() ? .red : .secondary)
                            }
                        }
                        Spacer()
                        PriorityBadge(priority: task.priority)
                    }
                }
                .onDelete { offsets in
                    let pending = tasks.filter { $0.status == .todo }
                    for index in offsets {
                        modelContext.delete(pending[index])
                    }
                }
            }

            Section("Completed") {
                ForEach(tasks.filter { $0.status == .completed }.prefix(15)) { task in
                    HStack {
                        Text(task.title)
                            .font(.subheadline)
                            .strikethrough()
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }

            Section {
                Button {
                    showingEditor = true
                } label: {
                    Label("Add Business Task", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Business Tasks")
        .sheet(isPresented: $showingEditor) {
            BusinessTaskEditorView()
        }
    }

    private func complete(_ task: BusinessTask) {
        task.status = .completed
        try? modelContext.save()
    }
}

struct BusinessTaskEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var taskDescription = ""
    @State private var kind: BusinessTaskKind = .general
    @State private var priority: TaskPriority = .medium
    @State private var estimatedMinutes = 30
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(86400)
    @State private var selectedClientID: UUID?

    @Query(sort: \BusinessClient.name) private var clients: [BusinessClient]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $taskDescription)
                    Picker("Kind", selection: $kind) {
                        ForEach(BusinessTaskKind.allCases, id: \.self) { k in
                            Text(k.rawValue).tag(k)
                        }
                    }
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            Text(p.rawValue.capitalized).tag(p)
                        }
                    }
                    Stepper("Duration: \(estimatedMinutes) min", value: $estimatedMinutes, in: 5...480, step: 5)
                }
                Section("Client (optional)") {
                    Picker("Client", selection: $selectedClientID) {
                        Text("None").tag(UUID?.none)
                        ForEach(clients) { client in
                            Text(client.name).tag(client.id as UUID?)
                        }
                    }
                }
                Section("Due Date") {
                    Toggle("Has due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate)
                    }
                }
            }
            .navigationTitle("New Business Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let task = BusinessTask(title: title, description: taskDescription, kind: kind, priority: priority)
                        task.estimatedMinutes = estimatedMinutes
                        task.dueDate = hasDueDate ? dueDate : nil
                        if let selectedClientID {
                            task.client = clients.first { $0.id == selectedClientID }
                        }
                        modelContext.insert(task)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}