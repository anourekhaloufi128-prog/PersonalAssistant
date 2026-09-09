import Foundation
import SwiftData

@Model
final class Exam {
    var id: UUID
    var title: String
    var examDescription: String
    var examDate: Date
    var importance: ExamImportance
    var preparationProgress: Int
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    var userProfile: UserProfile?
    var subject: Subject?

    @Relationship(deleteRule: .nullify, inverse: \Topic.tasks)
    var importedTopics: [Topic]?

    init(title: String, examDate: Date, importance: ExamImportance = .medium) {
        self.id = UUID()
        self.title = title
        self.examDescription = ""
        self.examDate = examDate
        self.importance = importance
        self.preparationProgress = 0
        self.notes = ""
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isArchived = false
    }

    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: examDate).day ?? 0
    }

    var isUpcoming: Bool {
        examDate >= Date()
    }
}

enum ExamImportance: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}