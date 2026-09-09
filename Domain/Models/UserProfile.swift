import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var email: String?
    var createdAt: Date
    var updatedAt: Date
    var preferredStudyDuration: Int
    var preferredBreakDuration: Int
    var preferredStudyTime: String
    var energyLevel: EnergyLevel
    var priorityWeights: PriorityWeights
    var onboardingCompleted: Bool
    var isCloudSyncEnabled: Bool
    var isHealthKitEnabled: Bool
    var isFocusProtectionEnabled: Bool

    @Relationship(deleteRule: .cascade, inverse: \Subject.userProfile)
    var subjects: [Subject]?

    @Relationship(deleteRule: .cascade, inverse: \StudyTask.userProfile)
    var tasks: [StudyTask]?

    @Relationship(deleteRule: .cascade, inverse: \Exam.userProfile)
    var exams: [Exam]?

    @Relationship(deleteRule: .cascade, inverse: \Habit.userProfile)
    var habits: [Habit]?

    @Relationship(deleteRule: .cascade, inverse: \Goal.userProfile)
    var goals: [Goal]?

    @Relationship(deleteRule: .cascade, inverse: \BusinessClient.userProfile)
    var clients: [BusinessClient]?

    @Relationship(deleteRule: .cascade, inverse: \BusinessLead.userProfile)
    var leads: [BusinessLead]?

    @Relationship(deleteRule: .cascade, inverse: \BusinessProject.userProfile)
    var projects: [BusinessProject]?

    @Relationship(deleteRule: .cascade, inverse: \FocusPolicy.userProfile)
    var focusPolicies: [FocusPolicy]?

    @Relationship(deleteRule: .cascade, inverse: \DailyPlan.userProfile)
    var dailyPlans: [DailyPlan]?

    @Relationship(deleteRule: .cascade, inverse: \AppSettings.userProfile)
    var settings: AppSettings?

    @Relationship(deleteRule: .cascade, inverse: \AIConversation.userProfile)
    var conversations: [AIConversation]?

    init(name: String, email: String? = nil) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.createdAt = Date()
        self.updatedAt = Date()
        self.preferredStudyDuration = 45
        self.preferredBreakDuration = 10
        self.preferredStudyTime = "morning"
        self.energyLevel = .medium
        self.priorityWeights = PriorityWeights()
        self.onboardingCompleted = false
        self.isCloudSyncEnabled = false
        self.isHealthKitEnabled = false
        self.isFocusProtectionEnabled = false
    }
}

enum EnergyLevel: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

struct PriorityWeights: Codable {
    var study: Double = 0.3
    var business: Double = 0.25
    var wellness: Double = 0.25
    var personal: Double = 0.2
}
