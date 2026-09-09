import SwiftUI
import SwiftData

@main
struct PersonalAssistantApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var notificationManager = NotificationManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Subject.self,
            Topic.self,
            StudyTask.self,
            Exam.self,
            StudySession.self,
            Flashcard.self,
            Quiz.self,
            QuizQuestion.self,
            Note.self,
            FocusSession.self,
            FocusPolicy.self,
            BlockedApp.self,
            Habit.self,
            HabitLog.self,
            SleepLog.self,
            WaterLog.self,
            ExerciseLog.self,
            MoodLog.self,
            Goal.self,
            Milestone.self,
            BusinessClient.self,
            BusinessLead.self,
            BusinessProject.self,
            BusinessTask.self,
            BusinessIncome.self,
            BusinessExpense.self,
            BusinessInvoice.self,
            Idea.self,
            AIConversation.self,
            AIMessage.self,
            AIMemory.self,
            NotificationPreference.self,
            AppSettings.self,
            SyncRecord.self,
            DailyPlan.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(notificationManager)
                .task {
                    await appState.initialize()
                    await notificationManager.requestAuthorization()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
