import SwiftUI
import SwiftData

enum AppDeepLink {
    case openApp
    case startFocus
    case openAI
    case openTab(AppState.Tab)

    init?(url: URL) {
        guard url.scheme == "personalassistant" else { return nil }
        switch url.host {
        case "open":
            self = .openApp
        case "start":
            self = .startFocus
        case "ai":
            self = .openAI
        case "tab":
            if let value = url.pathComponents.last, let tab = AppState.Tab(rawValue: value) {
                self = .openTab(tab)
            } else {
                self = .openApp
            }
        default:
            self = .openApp
        }
    }
}

struct DeepLinkHandlerModifier: ViewModifier {
    @EnvironmentObject var appState: AppState

    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                guard let link = AppDeepLink(url: url) else { return }
                switch link {
                case .openApp:
                    appState.currentTab = .home
                case .startFocus:
                    appState.currentTab = .focus
                case .openAI:
                    appState.currentTab = .home
                case .openTab(let tab):
                    appState.currentTab = tab
                }
            }
    }
}

extension View {
    func handleDeepLinks() -> some View {
        modifier(DeepLinkHandlerModifier())
    }
}