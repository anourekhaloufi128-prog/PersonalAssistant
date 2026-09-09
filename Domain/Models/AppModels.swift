import Foundation
import SwiftData

@Model
final class AIConversation {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    var userProfile: UserProfile?

    @Relationship(deleteRule: .cascade, inverse: \AIMessage.conversation)
    var messages: [AIMessage]?

    init(title: String = "New Conversation") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isArchived = false
    }
}

@Model
final class AIMessage {
    var id: UUID
    var content: String
    var role: AIMessageRole
    var createdAt: Date
    var toolCall: String?

    var conversation: AIConversation?

    init(content: String, role: AIMessageRole) {
        self.id = UUID()
        self.content = content
        self.role = role
        self.createdAt = Date()
    }
}

enum AIMessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

@Model
final class AIMemory {
    var id: UUID
    var key: String
    var value: String
    var category: String
    var isEnabled: Bool
    var createdAt: Date
    var updatedAt: Date

    init(key: String, value: String, category: String = "general") {
        self.id = UUID()
        self.key = key
        self.value = value
        self.category = category
        self.isEnabled = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class NotificationPreference {
    var id: UUID
    var type: NotificationType
    var isEnabled: Bool
    var time: Date?
    var days: [Int]

    init(type: NotificationType, isEnabled: Bool = true) {
        self.id = UUID()
        self.type = type
        self.isEnabled = isEnabled
        self.days = []
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case morningBriefing = "Morning Briefing"
    case studyReminder = "Study Reminder"
    case examReminder = "Exam Reminder"
    case taskDeadline = "Task Deadline"
    case focusCompletion = "Focus Completion"
    case breakReminder = "Break Reminder"
    case habitReminder = "Habit Reminder"
    case waterReminder = "Water Reminder"
    case businessFollowUp = "Business Follow-up"
    case sleepReminder = "Sleep Reminder"
}

@Model
final class AppSettings {
    var id: UUID
    var appVersion: String
    var lastDataExportAt: Date?
    var themePreference: ThemePreference
    var languagePreference: String
    var aiEnabled: Bool
    var healthKitEnabled: Bool
    var screenTimeEnabled: Bool
    var calendarEnabled: Bool
    var cloudSyncEnabled: Bool
    var widgetsEnabled: Bool
    var hapticsEnabled: Bool
    var reduceMotion: Bool
    var allowAnalytics: Bool
    var waterDailyGoalML: Int
    var exerciseWeeklyTargetMinutes: Int
    var sleepDailyTargetHours: Double
    var createdAt: Date
    var updatedAt: Date

    var userProfile: UserProfile?

    init() {
        self.id = UUID()
        self.appVersion = "1.0.0"
        self.themePreference = .system
        self.languagePreference = "en"
        self.aiEnabled = true
        self.healthKitEnabled = false
        self.screenTimeEnabled = false
        self.calendarEnabled = false
        self.cloudSyncEnabled = false
        self.widgetsEnabled = true
        self.hapticsEnabled = true
        self.reduceMotion = false
        self.allowAnalytics = false
        self.waterDailyGoalML = 2000
        self.exerciseWeeklyTargetMinutes = 150
        self.sleepDailyTargetHours = 8
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum ThemePreference: String, Codable, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

@Model
final class SyncRecord {
    var id: UUID
    var entityName: String
    var entityID: UUID
    var syncStatus: SyncStatus
    var lastSyncedAt: Date?
    var conflictNote: String?
    var version: Int

    init(entityName: String, entityID: UUID) {
        self.id = UUID()
        self.entityName = entityName
        self.entityID = entityID
        self.syncStatus = .pending
        self.version = 1
    }
}

@Model
final class DailyPlan {
    var id: UUID
    var date: Date
    var mainPriority: String?
    var summary: String
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date

    var userProfile: UserProfile?

    @Relationship(deleteRule: .cascade, inverse: \PlannedItem.plan)
    var items: [PlannedItem]?

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.summary = ""
        self.isCompleted = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class PlannedItem {
    var id: UUID
    var title: String
    var category: TaskCategory
    var estimatedMinutes: Int
    var startTime: Date?
    var reason: String?
    var isCompleted: Bool
    var sortOrder: Int

    var plan: DailyPlan?
    var task: StudyTask?
    var businessTask: BusinessTask?
    var habit: Habit?

    init(title: String, category: TaskCategory, estimatedMinutes: Int, reason: String? = nil) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.estimatedMinutes = estimatedMinutes
        self.reason = reason
        self.isCompleted = false
        self.sortOrder = 0
    }
}