import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.showOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.currentTab) {
            DashboardView()
                .tag(AppState.Tab.home)
                .tabItem {
                    Label("Home", systemImage: AppState.Tab.home.icon)
                }

            StudyTabView()
                .tag(AppState.Tab.study)
                .tabItem {
                    Label("Study", systemImage: AppState.Tab.study.icon)
                }

            FocusTabView()
                .tag(AppState.Tab.focus)
                .tabItem {
                    Label("Focus", systemImage: AppState.Tab.focus.icon)
                }

            BusinessTabView()
                .tag(AppState.Tab.business)
                .tabItem {
                    Label("Business", systemImage: AppState.Tab.business.icon)
                }

            WellnessTabView()
                .tag(AppState.Tab.wellness)
                .tabItem {
                    Label("Wellness", systemImage: AppState.Tab.wellness.icon)
                }
        }
    }
}
