import SwiftUI
import SwiftData

struct GoalsView: View {
    var isPartOfBusiness = false
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]
    @State private var showingEditor = false

    var body: some View {
        List {
            ForEach(goals.filter { !$0.isArchived }) { goal in
                NavigationLink {
                    GoalDetailView(goal: goal)
                } label: {
                    GoalRow(goal: goal)
                }
            }
            .onDelete { offsets in
                let active = goals.filter { !$0.isArchived }
                for index in offsets {
                    modelContext.delete(active[index])
                }
            }

            Section {
                Button {
                    showingEditor = true
                } label: {
                    Label("Add Goal", systemImage: "plus")
                }
            }
        }
        .navigationTitle(isPartOfBusiness ? "Business Goals" : "Goals")
        .sheet(isPresented: $showingEditor) {
            GoalEditorView(isBusiness: isPartOfBusiness)
        }
        .overlay {
            if goals.isEmpty {
                EmptyStateView(
                    icon: "target",
                    title: "No Goals",
                    message: "Define study, business, and personal goals and track progress over time.",
                    actionTitle: "Add Goal",
                    action: { showingEditor = true }
                )
            }
        }
    }
}

struct GoalRow: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(goal.name)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if let target = goal.targetDate {
                    Text(target.relativeDayLabel())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            ProgressView(value: min(1, goal.progress))
                .tint(goal.goalType == .business ? .orange : .blue)
            HStack {
                Text("\(Int(goal.progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if goal.totalMilestones > 0 {
                    Text("\(goal.completedMilestones)/\(goal.totalMilestones) milestones")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct GoalDetailView: View {
    let goal: Goal

    var body: some View {
        Form {
            Section("Goal") {
                Text(goal.name).font(.headline)
                if !goal.goalDescription.isEmpty {
                    Text(goal.goalDescription).foregroundStyle(.secondary)
                }
                LabeledContent("Type", value: goal.goalType.rawValue)
                LabeledContent("Progress", value: "\(Int(goal.progress * 100))%")
                if let target = goal.targetDate {
                    LabeledContent("Target date", value: target.formatted(date: .abbreviated, time: .omitted))
                }
            }

            Section("Milestones") {
                if let milestones = goal.milestones, !milestones.isEmpty {
                    ForEach(milestones) { milestone in
                        HStack {
                            Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(milestone.isCompleted ? .green : .secondary)
                            Text(milestone.title)
                                .font(.subheadline)
                                .strikethrough(milestone.isCompleted)
                            Spacer()
                        }
                    }
                } else {
                    Text("No milestones yet.")
                        .foregroundStyle(.secondary)
                }
                NavigationLink {
                    MilestoneEditorView(goal: goal)
                } label: {
                    Label("Add Milestone", systemImage: "plus")
                }
            }
        }
        .navigationTitle(goal.name)
    }
}

struct GoalEditorView: View {
    let isBusiness: Bool
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var goalDescription = ""
    @State private var goalType: GoalType = .personal
    @State private var hasTargetDate = false
    @State private var targetDate = Date().addingTimeInterval(30 * 86400)

    var body: some View {
        NavigationStack {
            Form {
                TextField("Goal name", text: $name)
                TextField("Description", text: $goalDescription)
                Picker("Type", selection: $goalType) {
                    ForEach(GoalType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                Toggle("Has target date", isOn: $hasTargetDate)
                if hasTargetDate {
                    DatePicker("Target", selection: $targetDate)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let goal = Goal(name: name, goalType: goalType)
                        goal.goalDescription = goalDescription
                        goal.targetDate = hasTargetDate ? targetDate : nil
                        modelContext.insert(goal)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .onAppear {
            if isBusiness { goalType = .business }
        }
    }
}

struct MilestoneEditorView: View {
    let goal: Goal
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""

    var body: some View {
        Form {
            TextField("Milestone", text: $title)
            Button("Add") {
                let milestone = Milestone(title: title)
                milestone.goal = goal
                modelContext.insert(milestone)
                let total = Double(goal.totalMilestones + 1)
                goal.progress = max(goal.progress, goal.completedMilestones / total)
                goal.updatedAt = Date()
                dismiss()
            }
            .disabled(title.isEmpty)
        }
        .navigationTitle("New Milestone")
    }
}