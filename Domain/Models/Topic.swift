import Foundation
import SwiftData

@Model
final class Topic {
    var id: UUID
    var title: String
    var topicDescription: String
    var notes: String
    var difficulty: Difficulty
    var estimatedMinutes: Int
    var mastery: Int
    var status: TopicStatus
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    var subject: Subject?

    @Relationship(deleteRule: .cascade, inverse: \StudyTask.topic)
    var tasks: [StudyTask]?

    @Relationship(deleteRule: .cascade, inverse: \StudySession.topic)
    var studySessions: [StudySession]?

    @Relationship(deleteRule: .cascade, inverse: \Flashcard.topic)
    var flashcards: [Flashcard]?

    init(title: String, description: String = "", estimatedMinutes: Int = 30, difficulty: Difficulty = .medium) {
        self.id = UUID()
        self.title = title
        self.topicDescription = description
        self.notes = ""
        self.difficulty = difficulty
        self.estimatedMinutes = estimatedMinutes
        self.mastery = 0
        self.status = .notStarted
        self.isArchived = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var totalStudyMinutes: Int {
        (studySessions ?? []).reduce(0) { $0 + $1.durationMinutes }
    }
}

enum TopicStatus: String, Codable, CaseIterable {
    case notStarted = "NOT_STARTED"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"

    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }
}