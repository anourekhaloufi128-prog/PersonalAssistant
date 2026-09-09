import SwiftUI
import SwiftData

struct BusinessProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BusinessProject.createdAt, order: .reverse) private var projects: [BusinessProject]
    @State private var showingEditor = false

    var body: some View {
        List {
            ForEach(projects) { project in
                NavigationLink {
                    BusinessProjectDetailView(project: project)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(project.title)
                                .font(.subheadline.weight(.medium))
                            if let client = project.client {
                                Text(client.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(project.status.displayName)
                            .font(.caption2)
                            .foregroundStyle(statusColor(project.status))
                    }
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    modelContext.delete(projects[index])
                }
            }

            Section {
                Button {
                    showingEditor = true
                } label: {
                    Label("Add Project", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Projects")
        .sheet(isPresented: $showingEditor) {
            BusinessProjectEditorView()
        }
        .overlay {
            if projects.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    title: "No Projects",
                    message: "Break client work into projects with deadlines, revenue, and tasks.",
                    actionTitle: "Add Project",
                    action: { showingEditor = true }
                )
            }
        }
    }

    private func statusColor(_ status: ProjectStatus) -> Color {
        switch status {
        case .planning: return .blue
        case .active: return .green
        case .waiting: return .orange
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

struct BusinessProjectEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var projectDescription = ""
    @State private var status: ProjectStatus = .planning
    @State private var estimatedRevenue = 0.0
    @State private var costs = 0.0
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(14 * 86400)
    @State private var selectedClientID: UUID?

    @Query(sort: \BusinessClient.name) private var clients: [BusinessClient]

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $projectDescription, axis: .vertical)
                    Picker("Status", selection: $status) {
                        ForEach(ProjectStatus.allCases, id: \.self) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                }
                Section("Client (optional)") {
                    Picker("Client", selection: $selectedClientID) {
                        Text("None").tag(UUID?.none)
                        ForEach(clients) { client in
                            Text(client.name).tag(client.id as UUID?)
                        }
                    }
                }
                Section("Finance") {
                    TextField("Estimated revenue", value: $estimatedRevenue, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                    TextField("Costs", value: $costs, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                }
                Section("Deadline") {
                    Toggle("Has deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline)
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let project = BusinessProject(title: title, description: projectDescription, estimatedRevenue: estimatedRevenue, costs: costs)
                        project.status = status
                        project.deadline = hasDeadline ? deadline : nil
                        if let selectedClientID {
                            project.client = clients.first { $0.id == selectedClientID }
                        }
                        modelContext.insert(project)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct BusinessProjectDetailView: View {
    let project: BusinessProject
    @Query private var allTasks: [BusinessTask]

    var displayTasks: [BusinessTask] {
        (project.tasks ?? allTasks.filter { $0.project == nil }).sorted { $0.priority > $1.priority }
    }

    var body: some View {
        Form {
            Section("Project") {
                Text(project.title).font(.headline)
                if !project.projectDescription.isEmpty {
                    Text(project.projectDescription)
                }
                LabeledContent("Status", value: project.status.displayName)
                if let client = project.client {
                    LabeledContent("Client", value: client.name)
                }
                if let deadline = project.deadline {
                    LabeledContent("Deadline", value: deadline.formatted(date: .abbreviated, time: .omitted))
                }
            }
            Section("Finance") {
                LabeledContent("Estimated revenue", value: project.estimatedRevenue.currencyLabel)
                LabeledContent("Costs", value: project.costs.currencyLabel)
                LabeledContent("Projected profit", value: project.projectedProfit.currencyLabel)
                    .foregroundStyle(project.projectedProfit >= 0 ? .green : .red)
            }
            Section("Tasks") {
                ForEach(displayTasks) { task in
                    HStack {
                        Text(task.title)
                        Spacer()
                        Text(task.status.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                NavigationLink {
                    AddProjectTaskView(project: project)
                } label: {
                    Label("Add Task", systemImage: "plus")
                }
            }
        }
        .navigationTitle(project.title)
    }
}

struct AddProjectTaskView: View {
    let project: BusinessProject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var priority: TaskPriority = .medium
    @State private var kind: BusinessTaskKind = .general

    var body: some View {
        Form {
            TextField("Task title", text: $title)
            Picker("Priority", selection: $priority) {
                ForEach(TaskPriority.allCases, id: \.self) { p in
                    Text(p.rawValue.capitalized).tag(p)
                }
            }
            Picker("Kind", selection: $kind) {
                ForEach(BusinessTaskKind.allCases, id: \.self) { k in
                    Text(k.rawValue).tag(k)
                }
            }
        }
        .navigationTitle("New Project Task")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    let task = BusinessTask(title: title, kind: kind, priority: priority)
                    task.project = project
                    modelContext.insert(task)
                    dismiss()
                }
                .disabled(title.isEmpty)
            }
        }
    }
}