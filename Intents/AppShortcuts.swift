import AppIntents
import WidgetKit

struct WhatShouldIDoNowIntent: AppIntent {
    static var title: LocalizedStringResource = "What should I do now?"
    static var description = IntentDescription("Get a recommendation for your next most useful action.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Your next action is ready in the My Day screen.")
    }
}

struct StartFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Focus"
    static var description = IntentDescription("Start a focus session.")

    @Parameter(title: "Minutes", default: 45)
    var minutes: Int

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let safe = max(5, min(minutes, 180))
        return .result(dialog: "Starting a \(safe) minute focus session.")
    }
}

struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add a Task"
    static var description = IntentDescription("Quickly add a task.")

    @Parameter(title: "Title")
    var title: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Task \"\(title)\" added.")
    }
}

struct LogWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Water"
    static var description = IntentDescription("Log a glass of water.")

    @Parameter(title: "Amount (ml)", default: 250)
    var amount: Int

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Logged \(amount) ml of water.")
    }
}

struct ShowBusinessTasksIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Business Tasks"
    static var description = IntentDescription("Show your pending business tasks.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Your business tasks are in the Business tab.")
    }
}

struct OpenTodayPlanIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Today's Plan"
    static var description = IntentDescription("Open the My Day screen.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Opening today's plan.")
    }
}

struct PersonalAssistantShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: WhatShouldIDoNowIntent(),
            phrases: [
                "What should I do now with \(.applicationName)?",
                "\(.applicationName) what should I do now"
            ],
            shortTitle: "What should I do now?",
            systemImageName: "bolt.fill"
        )
        AppShortcut(
            intent: StartFocusIntent(),
            phrases: [
                "Start a focus session with \(.applicationName)",
                "\(.applicationName) start focus"
            ],
            shortTitle: "Start Focus",
            systemImageName: "timer"
        )
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Add a task to \(.applicationName)",
                "\(.applicationName) add a task"
            ],
            shortTitle: "Add Task",
            systemImageName: "checklist"
        )
        AppShortcut(
            intent: LogWaterIntent(),
            phrases: [
                "Log water with \(.applicationName)",
                "\(.applicationName) log water"
            ],
            shortTitle: "Log Water",
            systemImageName: "drop.fill"
        )
        AppShortcut(
            intent: ShowBusinessTasksIntent(),
            phrases: [
                "Show my business tasks with \(.applicationName)",
                "\(.applicationName) business tasks"
            ],
            shortTitle: "Business Tasks",
            systemImageName: "briefcase.fill"
        )
        AppShortcut(
            intent: OpenTodayPlanIntent(),
            phrases: [
                "Open today's plan with \(.applicationName)",
                "\(.applicationName) open today"
            ],
            shortTitle: "Today's Plan",
            systemImageName: "calendar"
        )
    }
}