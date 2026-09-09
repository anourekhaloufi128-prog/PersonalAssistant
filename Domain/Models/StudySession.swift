import Foundation
import SwiftData

@Model
final class StudySession {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var durationMinutes: Int
    var plannedDurationMinutes: Int
    var completion: SessionCompletion
    var interruptionCount: Int
    var isFocusProtected: Bool
    var notes: String
    var syncStatus: SyncStatus

    var subject: Subject?
    var topic: Topic?
    var task: StudyTask?

    init(startedAt: Date, plannedDurationMinutes: Int, completion: SessionCompletion = .inProgress) {
        self.id = UUID()
        self.startedAt = startedAt
        self.plannedDurationMinutes = plannedDurationMinutes
        self.durationMinutes = 0
        self.completion = completion
        self.interruptionCount = 0
        self.isFocusProtected = false
        self.notes = ""
        self.syncStatus = .local
    }
}

enum SessionCompletion: String, Codable, CaseIterable {
    case completed = "Completed"
    case interrupted = "Interrupted"
    case skipped = "Skipped"
    case inProgress = "In Progress"
}