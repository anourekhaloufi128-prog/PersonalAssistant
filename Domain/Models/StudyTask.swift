import Foundation
import SwiftData

@Model
final class StudyTask {
    var id: UUID
    var title: String
    var taskDescription: String
    var category: TaskCategory
    var status: TaskStatus
    var priority: TaskPriority
    var deadline: Date?
    var estimatedMinutes: Int
    var isRecurring: Bool
    var recurrenceRule: String?
    var createdViaAI: Bool
    var completedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    var userProfile: UserProfile?
    var subject: Subject?
    var topic: Topic?

    @Relationship(deleteRule: .cascade, inverse: \BusinessTask.linkedStudyTask)
    var linkedBusinessTask: [BusinessTask]?

    init(title: String, description: String = "", category: TaskCategory = .study, priority: TaskPriority = .medium, estimatedMinutes: Int = 30) {
        self.id = UUID()
        self.title = title
        self.taskDescription = description
        self.category = category
        self.status = .todo
        self.priority = priority
        self.estimatedMinutes = estimatedMinutes
        self.isRecurring = false
        self.createdViaAI = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum TaskCategory: String, Codable, CaseIterable {
    case study = "Study"
    case business = "Business"
    case wellness = "Wellness"
    case personal = "Personal"
    case goal = "Goal"
}

enum TaskStatus: String, Codable, CaseIterable {
    case todo = "TODO"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"

    var displayName: String {
        switch self {
        case .todo: return "To Do"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

enum TaskPriority: String, Codable, CaseIterable, Comparable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case urgent = "URGENT"

    var sortOrder: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .urgent: return 3
        }
    }

    static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}