import Foundation
import UserNotifications
import HealthKit

struct PermissionsStatus {
    var notifications: FeatureStatus = .notConfigured
    var focusProtection: FeatureStatus = .notConfigured
    var health: FeatureStatus = .notConfigured
    var calendar: FeatureStatus = .notConfigured

    enum FeatureStatus {
        case enabled
        case disabled
        case notConfigured
    }
}

@MainActor
final class PermissionCenter: ObservableObject {
    @Published var status = PermissionsStatus()

    func refresh() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    self.status.notifications = .enabled
                case .denied:
                    self.status.notifications = .disabled
                case .notDetermined:
                    self.status.notifications = .notConfigured
                @unknown default:
                    self.status.notifications = .notConfigured
                }
            }
        }
    }

    func healthKitStatus() -> PermissionsStatus.FeatureStatus {
        guard HKHealthStore.isHealthDataAvailable() else { return .notConfigured }
        return .notConfigured
    }
}