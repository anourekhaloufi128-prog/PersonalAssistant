import Foundation

final class FocusSessionManager: ObservableObject {
    @Published private(set) var activeSession: FocusSession?

    init() {}

    func startSession(plannedMinutes: Int, label: String? = nil) -> FocusSession {
        let session = FocusSession(startedAt: Date(), plannedDurationMinutes: plannedMinutes, label: label)
        activeSession = session
        return session
    }

    func pause() {
        guard let session = activeSession else { return }
        session.isPaused = true
        session.pausedAt = Date()
    }

    func resume() {
        guard let session = activeSession else { return }
        guard session.isPaused, let pausedAt = session.pausedAt else { return }
        let pausedDuration = Date().timeIntervalSince(pausedAt)
        if let endDate = session.endDate {
            session.endDate = endDate.addingTimeInterval(pausedDuration)
        }
        session.isPaused = false
        session.pausedAt = nil
    }

    func finish() {
        guard let session = activeSession else { return }
        session.isActive = false
        session.completion = .completed
        session.actualDurationMinutes = max(0, Int(Date().timeIntervalSince(session.startedAt) / 60))
        session.endDate = nil
        session.endedAt = Date()
    }

    func cancel() {
        guard let session = activeSession else { return }
        session.isActive = false
        session.completion = .skipped
        session.endedAt = Date()
        session.actualDurationMinutes = 0
    }

    func recordInterruption() {
        activeSession?.interruptionCount += 1
    }

    func recordTemporaryUnlock() {
        activeSession?.temporaryUnlockCount += 1
    }

    func remainingDuration(of session: FocusSession) -> TimeInterval {
        guard let endDate = session.endDate else { return 0 }
        return max(0, endDate.timeIntervalSinceNow)
    }

    func recoverInterruptedSession(active: FocusSession?) {
        guard let active, active.isActive else { return }
        activeSession = active
    }
}