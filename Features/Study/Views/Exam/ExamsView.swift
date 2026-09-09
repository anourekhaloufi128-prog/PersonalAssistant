import SwiftUI
import SwiftData

struct ExamsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exam.examDate) private var exams: [Exam]
    @State private var showingEditor = false

    var body: some View {
        List {
            Section("Upcoming") {
                ForEach(exams.filter(\.isUpcoming).sorted(by: { $0.daysRemaining < $1.daysRemaining })) { exam in
                    NavigationLink {
                        ExamDetailView(exam: exam)
                    } label: {
                        ExamRow(exam: exam)
                    }
                }
                .onDelete { offsets in
                    let upcoming = exams.filter(\.isUpcoming).sorted(by: { $0.daysRemaining < $1.daysRemaining })
                    for index in offsets {
                        modelContext.delete(upcoming[index])
                    }
                }
            }

            Section("Past") {
                ForEach(exams.filter { !$0.isUpcoming }.prefix(10)) { exam in
                    ExamRow(exam: exam, isPast: true)
                }
            }

            Section {
                Button {
                    showingEditor = true
                } label: {
                    Label("Add Exam", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Exams")
        .sheet(isPresented: $showingEditor) {
            ExamEditorView()
        }
        .overlay {
            if exams.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.exclamationmark",
                    title: "No Exams",
                    message: "Add upcoming exams and the planner will build revision time around them.",
                    actionTitle: "Add Exam",
                    action: { showingEditor = true }
                )
            }
        }
    }
}

struct ExamRow: View {
    let exam: Exam
    var isPast: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(exam.title)
                    .font(.subheadline.weight(.semibold))
                if let subject = exam.subject {
                    Text(subject.name)
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
                Text(exam.examDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !isPast {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(max(0, exam.daysRemaining))")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(exam.daysRemaining <= 3 ? .red : .primary)
                    Text("days left")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ExamEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var examDescription = ""
    @State private var examDate = Date().addingTimeInterval(7 * 86400)
    @State private var importance: ExamImportance = .medium
    @State private var selectedSubjectID: UUID?

    @Query(sort: \Subject.name) private var subjects: [Subject]

    var body: some View {
        NavigationStack {
            Form {
                Section("Exam") {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $examDescription)
                }
                Section("Details") {
                    DatePicker("Date", selection: $examDate)
                    Picker("Importance", selection: $importance) {
                        ForEach(ExamImportance.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    Picker("Subject (optional)", selection: $selectedSubjectID) {
                        Text("None").tag(UUID?.none)
                        ForEach(subjects) { subject in
                            Text(subject.name).tag(subject.id as UUID?)
                        }
                    }
                }
            }
            .navigationTitle("New Exam")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let exam = Exam(title: title, examDate: examDate, importance: importance)
                        exam.examDescription = examDescription
                        if let selectedSubjectID {
                            exam.subject = subjects.first { $0.id == selectedSubjectID }
                        }
                        modelContext.insert(exam)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct ExamDetailView: View {
    let exam: Exam

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(max(0, exam.daysRemaining)) DAYS LEFT")
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(exam.daysRemaining <= 3 ? .red : .primary)
                    if let subject = exam.subject {
                        Text(subject.name)
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }
                    Text(exam.examDate.formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Preparation") {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: Double(exam.preparationProgress) / 100)
                    Text("\(exam.preparationProgress)% prepared")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !exam.notes.isEmpty {
                Section("Notes") {
                    Text(exam.notes)
                }
            }
        }
        .navigationTitle(exam.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}