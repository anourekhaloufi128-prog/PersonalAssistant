import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: UUID
    var startedAt: Date
    var endDate: Date?
    var endedAt: Date?
    var pausedAt: Date?
    var plannedDurationMinutes: Int
    var actualDurationMinutes: Int
    var isActive: Bool
    var isPaused: Bool
    var completion: SessionCompletion
    var interruptionCount: Int
    var temporaryUnlockCount: Int
    var wasFocusProtected: Bool
    var notes: String
    var label: String?

    var subject: Subject?
    var topic: Topic?
    var task: StudyTask?

    var focusPolicy: FocusPolicy?

    init(startedAt: Date, plannedDurationMinutes: Int, label: String? = nil) {
        self.id = UUID()
        self.startedAt = startedAt
        self.endDate = startedAt.addingTimeInterval(TimeInterval(plannedDurationMinutes * 60))
        self.pausedAt = nil
        self.plannedDurationMinutes = plannedDurationMinutes
        self.actualDurationMinutes = 0
        self.isActive = true
        self.isPaused = false
        self.completion = .inProgress
        self.interruptionCount = 0
        self.temporaryUnlockCount = 0
        self.wasFocusProtected = false
        self.notes = ""
        self.label = label
    }

    var remainingTime: TimeInterval {
        guard let endDate else { return 0 }
        return max(0, endDate.timeIntervalSinceNow)
    }
}

@Model
final class FocusPolicy {
    var id: UUID
    var name: String
    var sessionDurationMinutes: Int
    var breakDurationMinutes: Int
    var scheduleStart: Int?
    var scheduleEnd: Int?
    var allowEmergencyUnlock: Bool
    var appliesOnlyDuringSchedule: Bool
    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date

    var userProfile: UserProfile?

    @Relationship(deleteRule: .cascade, inverse: \BlockedApp.policy)
    var blockedApps: [BlockedApp]?

    @Relationship(deleteRule: .cascade, inverse: \FocusSession.focusPolicy)
    var focusSessions: [FocusSession]?

    init(name: String, sessionDurationMinutes: Int = 45, breakDurationMinutes: Int = 10) {
        self.id = UUID()
        self.name = name
        self.sessionDurationMinutes = sessionDurationMinutes
        self.breakDurationMinutes = breakDurationMinutes
        self.allowEmergencyUnlock = true
        self.appliesOnlyDuringSchedule = false
        self.isDefault = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class BlockedApp {
    var id: UUID
    var displayName: String
    var bundleIdentifier: String
    var isEnabled: Bool

    var policy: FocusPolicy?

    init(displayName: String, bundleIdentifier: String) {
        self.id = UUID()
        self.displayName = displayName
        self.bundleIdentifier = bundleIdentifier
        self.isEnabled = true
    }
}

enum SyncStatus: String, Codable {
    case local = "LOCAL"
    case pending = "PENDING"
    case synced = "SYNCED"
    case conflict = "CONFLICT"
    case error = "ERROR"
}