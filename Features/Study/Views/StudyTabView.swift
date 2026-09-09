import SwiftUI
import SwiftData

struct StudyTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section("Study") {
                    NavigationLink(value: "subjects") {
                        Label("Subjects & Topics", systemImage: "books.vertical.fill")
                    }
                    NavigationLink(value: "tasks") {
                        Label("Tasks & Homework", systemImage: "checklist")
                    }
                    NavigationLink(value: "exams") {
                        Label("Exams", systemImage: "calendar.badge.exclamationmark")
                    }
                    NavigationLink(value: "history") {
                        Label("Study History", systemImage: "clock.arrow.circlepath")
                    }
                }

                Section("Practice") {
                    NavigationLink(value: "flashcards") {
                        Label("Flashcards", systemImage: "rectangle.on.rectangle.angled")
                    }
                    NavigationLink(value: "quizzes") {
                        Label("Quizzes", systemImage: "questionmark.circle")
                    }
                    NavigationLink(value: "notes") {
                        Label("Notes", systemImage: "note.text")
                    }
                }
            }
            .navigationTitle("Study")
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "subjects": SubjectsView()
                case "tasks": StudyTasksView()
                case "exams": ExamsView()
                case "history": StudyHistoryView()
                case "flashcards": FlashcardsView()
                case "quizzes": QuizzesView()
                case "notes": NotesView()
                default: EmptyView()
                }
            }
        }
    }
}