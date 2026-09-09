import Foundation
import FamilyControls
import ManagedSettings
import SwiftUI

enum FocusAuthorizationState {
    case notDetermined
    case authorized
    case denied
    case unavailable
    case pendingReview

    var displayName: String {
        switch self {
        case .notDetermined: return "Not Configured"
        case .authorized: return "Enabled"
        case .denied: return "Denied"
        case .unavailable: return "Unavailable"
        case .pendingReview: return "Under Review"
        }
    }

    var detail: String {
        switch self {
        case .notDetermined:
            return "Focus protection needs to be enabled in iPhone Settings > Screen Time."
        case .authorized:
            return "Focus protection is active."
        case .denied:
            return "Screen Time authorization was denied. Enable it in iPhone Settings > Screen Time."
        case .unavailable:
            return "This feature is not available on your iOS version or device."
        case .pendingReview:
            return "Apple is reviewing the Screen Time authorization request."
        }
    }
}

@MainActor
final class FocusBlockingService: ObservableObject {
    @Published private(set) var authorizationState: FocusAuthorizationState = .notDetermined
    @Published private(set) var isRestrictionActive = false
    @Published var selectedApps = FamilyActivitySelection()

    private let center = AuthorizationCenter.shared
    private var settingsStore = ManagedSettingsStore()

    init() {
        refreshAuthorizationState()
    }

    func refreshAuthorizationState() {
        Task {
            let status = await center.authorizationStatus
            switch status {
            case .notDetermined:
                authorizationState = .notDetermined
            case .approved:
                authorizationState = .authorized
            case .denied:
                authorizationState = .denied
            case .pending:
                authorizationState = .pendingReview
            @unknown default:
                authorizationState = .unavailable
            }
        }
    }

    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            refreshAuthorizationState()
        } catch {
            authorizationState = .denied
        }
    }

    func applyRestriction() {
        guard authorizationState == .authorized else {
            isRestrictionActive = false
            return
        }
        guard !selectedApps.applications.isEmpty else {
            isRestrictionActive = false
            return
        }

        settingsStore.shield.applicationCategories = nil
        settingsStore.shield.applications = selectedApps.applications
        settingsStore.shield.applicationApplications = selectedApps.applications
        isRestrictionActive = true
    }

    func removeRestriction() {
        guard authorizationState == .authorized else {
            isRestrictionActive = false
            return
        }
        settingsStore.clearAllSettings()
        isRestrictionActive = false
    }

    func promptForAuthorizationIfNeeded() async {
        if authorizationState != .authorized {
            await requestAuthorization()
        }
    }

    func openScreenTimeSettingsIfNeeded() {
        guard authorizationState != .authorized else { return }
        Task {
            await requestAuthorization()
        }
    }
}