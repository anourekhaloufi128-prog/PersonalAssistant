import Foundation
import SwiftData

@Model
final class Goal {
    var id: UUID
    var name: String
    var goalDescription: String
    var goalType: GoalType
    var targetDate: Date?
    var startDate: Date
    var isCompleted: Bool
    var progress: Double
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    var userProfile: UserProfile?

    @Relationship(deleteRule: .cascade, inverse: \Milestone.goal)
    var milestones: [Milestone]?

    @Relationship(deleteRule: .cascade, inverse: \StudyTask.goal)
    var tasks: [StudyTask]?

    init(name: String, goalType: GoalType = .personal, progress: Double = 0) {
        self.id = UUID()
        self.name = name
        self.goalDescription = ""
        self.goalType = goalType
        self.startDate = Date()
        self.isCompleted = false
        self.progress = progress
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isArchived = false
    }

    var completedMilestones: Int {
        (milestones ?? []).filter { $0.isCompleted }.count
    }

    var totalMilestones: Int {
        (milestones ?? []).count
    }
}

enum GoalType: String, Codable, CaseIterable {
    case study = "Study"
    case business = "Business"
    case programming = "Programming"
    case personalDevelopment = "Personal Development"
    case longTerm = "Long Term"
    case personal = "Personal"
}

@Model
final class Milestone {
    var id: UUID
    var title: String
    var milestoneDescription: String
    var targetDate: Date?
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date

    var goal: Goal?

    init(title: String, description: String = "") {
        self.id = UUID()
        self.title = title
        self.milestoneDescription = description
        self.isCompleted = false
        self.createdAt = Date()
    }
}