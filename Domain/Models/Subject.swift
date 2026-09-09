import Foundation
import SwiftData

@Model
final class Subject {
    var id: UUID
    var name: String
    var subjectDescription: String
    var icon: String
    var colorHex: String
    var difficulty: Difficulty
    var weeklyTargetMinutes: Int
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    var userProfile: UserProfile?

    @Relationship(deleteRule: .cascade, inverse: \Topic.subject)
    var topics: [Topic]?

    @Relationship(deleteRule: .cascade, inverse: \StudyTask.subject)
    var tasks: [StudyTask]?

    @Relationship(deleteRule: .cascade, inverse: \Exam.subject)
    var exams: [Exam]?

    @Relationship(deleteRule: .cascade, inverse: \StudySession.subject)
    var studySessions: [StudySession]?

    init(name: String, description: String = "", icon: String = "book.fill", colorHex: String = "#4A90D9", difficulty: Difficulty = .medium) {
        self.id = UUID()
        self.name = name
        self.subjectDescription = description
        self.icon = icon
        self.colorHex = colorHex
        self.difficulty = difficulty
        self.weeklyTargetMinutes = 300
        self.isArchived = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var totalStudyMinutes: Int {
        (studySessions ?? []).reduce(0) { $0 + $1.durationMinutes }
    }

    var averageMastery: Double {
        let topicList = topics ?? []
        guard !topicList.isEmpty else { return 0 }
        return topicList.reduce(0.0) { $0 + Double($1.mastery) } / Double(topicList.count)
    }
}

enum Difficulty: String, Codable, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}
