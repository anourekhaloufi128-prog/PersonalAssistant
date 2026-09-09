import SwiftUI
import SwiftData

struct SubjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.name) private var subjects: [Subject]
    @State private var showingEditor = false

    var body: some View {
        List {
            ForEach(subjects.filter { !$0.isArchived }) { subject in
                NavigationLink {
                    SubjectDetailView(subject: subject)
                } label: {
                    SubjectRow(subject: subject)
                }
            }
            .onDelete(perform: deleteSubjects)

            Section {
                Button {
                    showingEditor = true
                } label: {
                    Label("Add Subject", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Subjects")
        .sheet(isPresented: $showingEditor) {
            SubjectEditorView()
        }
        .overlay {
            if subjects.isEmpty {
                EmptyStateView(
                    icon: "books.vertical",
                    title: "No Subjects Yet",
                    message: "Add subjects like Mathematics, Physics, or French to organize your study.",
                    actionTitle: "Add Subject",
                    action: { showingEditor = true }
                )
            }
        }
    }

    private func deleteSubjects(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(subjects[index])
        }
    }
}

struct SubjectRow: View {
    let subject: Subject

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: subject.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color(hex: subject.colorHex), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(subject.name)
                    .font(.headline)
                Text("\(subject.difficulty.rawValue) · \(subject.totalStudyMinutes.minutesToHoursLabel) studied")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ProgressRing(progress: subject.averageMastery / 100, color: Color(hex: subject.colorHex), lineWidth: 4)
                .frame(width: 32, height: 32)
        }
        .padding(.vertical, 4)
    }
}

struct SubjectEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var subjectDescription = ""
    @State private var difficulty: Difficulty = .medium
    @State private var weeklyTarget = 300
    @State private var icon = "book.fill"
    @State private var selectedColor = "#4A90D9"

    private let icons = ["book.fill", "function", "atom", "globe", "textformat", "map", "cpu.fill", "paintpalette"]
    private let colors = ["#4A90D9", "#E74C3C", "#27AE60", "#8E44AD", "#F39C12", "#16A085"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Subject name", text: $name)
                    TextField("Description", text: $subjectDescription)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(icons, id: \.self) { item in
                            Button {
                                icon = item
                            } label: {
                                Image(systemName: item)
                                    .font(.title3)
                                    .frame(width: 48, height: 48)
                                    .background(icon == item ? Color(hex: selectedColor).opacity(0.25) : Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Color") {
                    HStack {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 28, height: 28)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { selectedColor = color }
                        }
                    }
                }

                Section("Settings") {
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(Difficulty.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    Stepper("Weekly target: \(weeklyTarget) min", value: $weeklyTarget, in: 60...1200, step: 30)
                }
            }
            .navigationTitle("New Subject")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.isEmpty)
                }
            }
        }
    }

    private func save() {
        let subject = Subject(
            name: name,
            description: subjectDescription,
            icon: icon,
            colorHex: selectedColor,
            difficulty: difficulty
        )
        subject.weeklyTargetMinutes = weeklyTarget
        modelContext.insert(subject)
        dismiss()
    }
}

struct SubjectDetailView: View {
    let subject: Subject
    @Environment(\.modelContext) private var modelContext
    @State private var showingTopicEditor = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: subject.icon)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(Color(hex: subject.colorHex), in: RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading) {
                            Text(subject.name)
                                .font(.title2.weight(.bold))
                            Text("\(subject.difficulty.rawValue) difficulty")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    ProgressView(value: subject.averageMastery / 100)
                    Text("Average mastery \(Int(subject.averageMastery))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Topics") {
                if let topics = subject.topics, !topics.isEmpty {
                    ForEach(topics) { topic in
                        NavigationLink {
                            TopicDetailView(topic: topic)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(topic.title)
                                        .font(.subheadline.weight(.medium))
                                    Text(topic.status.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                ProgressRing(progress: Double(topic.mastery) / 100, color: Color(hex: subject.colorHex), lineWidth: 3)
                                    .frame(width: 26, height: 26)
                            }
                        }
                    }
                } else {
                    Text("No topics yet.")
                        .foregroundStyle(.secondary)
                }

                Button {
                    showingTopicEditor = true
                } label: {
                    Label("Add Topic", systemImage: "plus")
                }
            }
        }
        .navigationTitle(subject.name)
        .sheet(isPresented: $showingTopicEditor) {
            TopicEditorView(subject: subject)
        }
    }
}

struct TopicEditorView: View {
    let subject: Subject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var topicDescription = ""
    @State private var estimatedMinutes = 30
    @State private var difficulty: Difficulty = .medium

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Description", text: $topicDescription)
                Stepper("Estimated time: \(estimatedMinutes) min", value: $estimatedMinutes, in: 5...240, step: 5)
                Picker("Difficulty", selection: $difficulty) {
                    ForEach(Difficulty.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
            }
            .navigationTitle("New Topic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let topic = Topic(title: title, description: topicDescription, estimatedMinutes: estimatedMinutes, difficulty: difficulty)
                        topic.subject = subject
                        modelContext.insert(topic)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct TopicDetailView: View {
    let topic: Topic

    var body: some View {
        Form {
            Section("Topic") {
                Text(topic.title).font(.headline)
                if !topic.topicDescription.isEmpty {
                    Text(topic.topicDescription).foregroundStyle(.secondary)
                }
                LabeledContent("Status", value: topic.status.displayName)
                LabeledContent("Mastery", value: "\(topic.mastery)%")
                LabeledContent("Estimated time", value: "\(topic.estimatedMinutes) min")
                LabeledContent("Time studied", value: topic.totalStudyMinutes.minutesToHoursLabel)
            }
            Section("Notes") {
                Text(topic.notes.isEmpty ? "No notes. Add some notes to remember key concepts." : topic.notes)
                    .foregroundStyle(topic.notes.isEmpty ? .secondary : .primary)
            }
        }
        .navigationTitle(topic.title)
    }
}