import Foundation
import UserNotifications

@MainActor
final class NotificationManager: NSObject, ObservableObject {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func requestAuthorization() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {}
        refreshAuthorizationStatus()
    }

    func scheduleStudyReminder(title: String, body: String, at date: Date, id: String = UUID().uuidString) {
        schedule(title: title, body: body, at: date, id: id, category: .study)
    }

    func scheduleExamReminder(title: String, body: String, at date: Date, id: String) {
        schedule(title: title, body: body, at: date, id: id, category: .exam)
    }

    func scheduleTaskDeadline(title: String, body: String, at date: Date, id: String) {
        schedule(title: title, body: body, at: date, id: id, category: .task)
    }

    func scheduleBreakReminder(title: String = "Break time", body: String, at date: Date, id: String = UUID().uuidString) {
        schedule(title: title, body: body, at: date, id: id, category: .breakReminder)
    }

    func scheduleWaterReminder(at date: Date, id: String = UUID().uuidString) {
        schedule(title: "Hydration", body: "Time to drink some water.", at: date, id: id, category: .water)
    }

    func scheduleHabitReminder(title: String, at date: Date, id: String) {
        schedule(title: title, body: "Time for your habit.", at: date, id: id, category: .habit)
    }

    func removePendingNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func removeAllPending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func schedule(title: String, body: String, at date: Date, id: String, category: NotificationType) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category.rawValue

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let identifier = response.notification.request.identifier
        await MainActor.run {
            handleDeepLink(identifier)
        }
    }

    @MainActor
    func handleDeepLink(_ identifier: String) {
        NotificationCenter.default.post(name: .openDeepLink, object: identifier)
    }
}

extension Notification.Name {
    static let openDeepLink = Notification.Name("openDeepLink")
}