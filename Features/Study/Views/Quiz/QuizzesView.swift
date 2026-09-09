import SwiftUI
import SwiftData

struct QuizzesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var quizzes: [Quiz]
    @State private var showingSetup = false

    var body: some View {
        List {
            Section {
                Button {
                    showingSetup = true
                } label: {
                    Label("Create Quiz", systemImage: "plus")
                }
            }

            Section("Quizzes") {
                ForEach(quizzes) { quiz in
                    NavigationLink {
                        QuizDetailView(quiz: quiz)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(quiz.title)
                                .font(.subheadline.weight(.medium))
                            Text(quiz.isCompleted
                                 ? "Score \(quiz.percentage, specifier: "%.0f")%"
                                 : "\(quiz.totalQuestions) questions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        modelContext.delete(quizzes[index])
                    }
                }
            }
        }
        .navigationTitle("Quizzes")
        .sheet(isPresented: $showingSetup) {
            QuizSetupView()
        }
        .overlay {
            if quizzes.isEmpty {
                EmptyStateView(
                    icon: "questionmark.circle",
                    title: "No Quizzes",
                    message: "Test yourself with quizzes. You can generate them with the AI.",
                    actionTitle: "Create Quiz",
                    action: { showingSetup = true }
                )
            }
        }
    }
}

struct QuizSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var questionCount = 5
    @State private var selectedSubjectID: UUID?
    @State private var isGenerating = false

    @Query(sort: \Subject.name) private var subjects: [Subject]

    var body: some View {
        NavigationStack {
            Form {
                Section("Quiz") {
                    TextField("Title", text: $title)
                }
                Section("Options") {
                    Picker("Subject", selection: $selectedSubjectID) {
                        Text("None").tag(UUID?.none)
                        ForEach(subjects) { subject in
                            Text(subject.name).tag(subject.id as UUID?)
                        }
                    }
                    Stepper("Questions: \(questionCount)", value: $questionCount, in: 3...30)
                }
                Section {
                    Button {
                        createQuiz()
                    } label: {
                        if isGenerating {
                            HStack {
                                ActivityIndicatorView(style: .medium)
                                Text("Generating...")
                            }
                        } else {
                            Label("Create with AI", systemImage: "sparkles")
                        }
                    }
                    .disabled(isGenerating || title.isEmpty)
                    .frame(maxWidth: .infinity, alignment: .center)
                } footer: {
                    Text("AI quiz generation requires an internet connection.")
                }
            }
            .navigationTitle("New Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private func createQuiz() {
        isGenerating = true
        let quiz = Quiz(title: title)
        let subjectName = subjects.first { $0.id == selectedSubjectID }?.name ?? ""
        modelContext.insert(quiz)

        Task {
            let ai = AIService()
            do {
                let seeds = try await ai.generateQuiz(subjectName: subjectName, topic: nil, count: questionCount)
                for seed in seeds {
                    let question = QuizQuestion(question: seed.question, options: seed.options, correctIndex: seed.correctIndex)
                    question.quiz = quiz
                    modelContext.insert(question)
                }
                quiz.totalQuestions = seeds.count
                if let selectedSubjectID {
                    quiz.subject = subjects.first { $0.id == selectedSubjectID }
                }
                quiz.isCompleted = false
                try? modelContext.save()
            } catch {
                quiz.totalQuestions = 0
            }
            isGenerating = false
            dismiss()
        }
    }
}

struct QuizDetailView: View {
    let quiz: Quiz
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var isFinished = false

    var body: some View {
        if quiz.isCompleted {
            QuizResultsView(quiz: quiz)
        } else if isFinished {
            finishQuiz()
        } else {
            questionFlow
        }
    }

    private var questions: [QuizQuestion] {
        (quiz.questions ?? []).sorted { $0.id.uuidString < $1.id.uuidString }
    }

    private var questionFlow: some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(currentIndex + 1), total: Double(max(1, questions.count)))
                .padding()

            Text("Question \(currentIndex + 1) of \(questions.count)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(questions[currentIndex].question)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding()

            VStack(spacing: 10) {
                ForEach(Array(questions[currentIndex].options.enumerated()), id: \.offset) { index, option in
                    Button {
                        questions[currentIndex].userAnswerIndex = index
                        advance()
                    } label: {
                        Text(option)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Take Quiz")
    }

    private func advance() {
        if currentIndex < questions.count - 1 {
            currentIndex += 1
        } else {
            scoreQuiz()
        }
    }

    private func scoreQuiz() {
        let result = QuizScorer.score(questions: questions)
        quiz.score = result.correct
        quiz.totalQuestions = result.total
        quiz.isCompleted = true
        isFinished = true
    }

    private func finishQuiz() -> some View {
        QuizResultsView(quiz: quiz)
    }
}

struct QuizResultsView: View {
    let quiz: Quiz
    @Environment(\.dismiss) private var dismiss
    @State private var isRetaking = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: resultIcon)
                    .font(.system(size: 56))
                    .foregroundStyle(resultColor)

                Text("\(Int(quiz.percentage))%")
                    .font(.system(size: 60, weight: .bold, design: .rounded))

                Text("\(quiz.score) / \(quiz.totalQuestions) correct")
                    .font(.headline)

                resultMessage

                VStack(spacing: 10) {
                    ForEach(Array((quiz.questions ?? []).enumerated()), id: \.offset) { index, q in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: q.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(q.isCorrect ? .green : .red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(q.question)
                                    .font(.subheadline.weight(.medium))
                                if !q.isCorrect {
                                    Text("Correct answer: \(q.options[q.correctIndex])")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                }
                .cardStyle()

                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var resultIcon: String {
        if quiz.percentage >= 80 { return "trophy.fill" }
        if quiz.percentage >= 50 { return "checkmark.seal.fill" }
        return "arrowcounterclockwise"
    }

    private var resultColor: Color {
        if quiz.percentage >= 80 { return .yellow }
        if quiz.percentage >= 50 { return .green }
        return .orange
    }

    private var resultMessage: some View {
        Text(quiz.percentage >= 80
             ? "Great work. Review the missed questions and move on."
             : quiz.percentage >= 50
             ? "Decent. Review the topics you missed and try again soon."
             : "Keep going. Review the material and retake this quiz.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
}