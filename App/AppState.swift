import SwiftUI
import SwiftData

@MainActor
final class AppState: ObservableObject {
    @Published var isInitialized = false
    @Published var currentTab: Tab = .home
    @Published var isOffline = false
    @Published var showOnboarding = false
    @Published var currentUser: UserProfile?

    let aiService: AIServiceProtocol
    let syncEngine: SyncEngineProtocol
    let notificationManager: NotificationManager
    let priorityEngine: PriorityEngine

    init() {
        self.aiService = AIService()
        self.syncEngine = SyncEngine()
        self.notificationManager = NotificationManager()
        self.priorityEngine = PriorityEngine()
    }

    func initialize() async {
        await syncEngine.startListening()
        checkOnboarding()
        isInitialized = true
    }

    private func checkOnboarding() {
        if currentUser == nil {
            showOnboarding = true
        }
    }

    enum Tab: String, CaseIterable {
        case home = "Home"
        case study = "Study"
        case focus = "Focus"
        case business = "Business"
        case wellness = "Wellness"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .study: return "book.fill"
            case .focus: return "timer"
            case .business: return "briefcase.fill"
            case .wellness: return "heart.fill"
            }
        }
    }
}
