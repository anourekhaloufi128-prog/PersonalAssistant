import Foundation
import SwiftData

@Model
final class Flashcard {
    var id: UUID
    var front: String
    var back: String
    var difficulty: Difficulty
    var reviewCount: Int
    var lastReviewedAt: Date?
    var nextReviewAt: Date?
    var isKnown: Bool
    var createdAt: Date

    var topic: Topic?
    var subject: Subject?

    init(front: String, back: String, difficulty: Difficulty = .medium) {
        self.id = UUID()
        self.front = front
        self.back = back
        self.difficulty = difficulty
        self.reviewCount = 0
        self.isKnown = false
        self.createdAt = Date()
    }
}

@Model
final class Quiz {
    var id: UUID
    var title: String
    var quizDescription: String
    var createdAt: Date
    var score: Int
    var totalQuestions: Int
    var isCompleted: Bool

    var subject: Subject?
    var topic: Topic?

    @Relationship(deleteRule: .cascade, inverse: \QuizQuestion.quiz)
    var questions: [QuizQuestion]?

    init(title: String, description: String = "") {
        self.id = UUID()
        self.title = title
        self.quizDescription = description
        self.createdAt = Date()
        self.score = 0
        self.totalQuestions = 0
        self.isCompleted = false
    }

    var percentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(score) / Double(totalQuestions) * 100
    }
}

@Model
final class QuizQuestion {
    var id: UUID
    var question: String
    var options: [String]
    var correctIndex: Int
    var userAnswerIndex: Int?

    var quiz: Quiz?

    init(question: String, options: [String], correctIndex: Int) {
        self.id = UUID()
        self.question = question
        self.options = options
        self.correctIndex = correctIndex
    }

    var isCorrect: Bool {
        userAnswerIndex == correctIndex
    }
}

@Model
final class Note {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool

    var subject: Subject?
    var topic: Topic?

    init(title: String, content: String = "") {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPinned = false
    }
}