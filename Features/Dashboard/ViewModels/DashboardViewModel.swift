import Foundation
import SwiftData

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var recommendation: PriorityRecommendation?
    @Published var todayPlanItems: [PlannedItem] = []
    @Published var totalPlannedMinutes = 0
    @Published var completedMinutes = 0
    @Published var todayFocusMinutes = 0
    @Published var todayStudyMinutes = 0
    @Published var isGeneratingPlan = false

    private let priorityEngine = PriorityEngine()
    private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadToday()
    }

    func loadToday() {
        guard let modelContext else { return }
        let tasks = (try? modelContext.fetch(FetchDescriptor<StudyTask>())) ?? []
        let businessTasks = (try? modelContext.fetch(FetchDescriptor<BusinessTask>())) ?? []
        let exams = (try? modelContext.fetch(FetchDescriptor<Exam>())) ?? []
        let habits = (try? modelContext.fetch(FetchDescriptor<Habit>())) ?? []
        let focusSessions = (try? modelContext.fetch(FetchDescriptor<FocusSession>())) ?? []
        let studySessions = (try? modelContext.fetch(FetchDescriptor<StudySession>())) ?? []

        recommendation = priorityEngine.recommendNextAction(
            tasks: tasks,
            businessTasks: businessTasks,
            exams: exams,
            habits: habits
        )

        loadPlanItems()

        todayFocusMinutes = focusSessions
            .filter { Calendar.current.isDate($0.startedAt, inSameDayAs: Date()) }
            .reduce(0) { $0 + $1.actualDurationMinutes }
        todayStudyMinutes = studySessions
            .filter { Calendar.current.isDate($0.startedAt, inSameDayAs: Date()) }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    func generateTodayPlan() {
        guard let modelContext else { return }
        isGeneratingPlan = true

        let tasks = (try? modelContext.fetch(FetchDescriptor<StudyTask>())) ?? []
        let businessTasks = (try? modelContext.fetch(FetchDescriptor<BusinessTask>())) ?? []
        let exams = (try? modelContext.fetch(FetchDescriptor<Exam>())) ?? []
        let habits = (try? modelContext.fetch(FetchDescriptor<Habit>())) ?? []

        let planner = StudyPlanner()
        let input = StudyPlanner.PlanInput(
            tasks: tasks,
            businessTasks: businessTasks,
            exams: exams,
            habits: habits,
            availableMinutes: 480,
            preferredSessionMinutes: 45,
            breakMinutes: 10
        )
        let sessions = planner.createDailyPlan(input: input)

        let descriptor = FetchDescriptor<DailyPlan>(
            predicate: #Predicate { Calendar.current.isDate($0.date, inSameDayAs: Date()) }
        )
        let existing = (try? modelContext.fetch(descriptor))?.first
        let plan: DailyPlan
        if let existing {
            plan = existing
            if let items = plan.items {
                for item in items { modelContext.delete(item) }
            }
        } else {
            plan = DailyPlan(date: Date())
            modelContext.insert(plan)
        }

        for (index, session) in sessions.enumerated() {
            let item = PlannedItem(
                title: session.taskTitle,
                category: session.category,
                estimatedMinutes: session.minutes,
                reason: session.reason
            )
            item.sortOrder = index
            item.plan = plan
            modelContext.insert(item)
        }

        try? modelContext.save()
        loadPlanItems(count: sessions.count)
        totalPlannedMinutes = sessions.reduce(0) { $0 + $1.minutes }
        isGeneratingPlan = false
    }

    private func loadPlanItems(count: Int = 0) {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<DailyPlan>(
            predicate: #Predicate { Calendar.current.isDate($0.date, inSameDayAs: Date()) }
        )
        if let plan = (try? modelContext.fetch(descriptor))?.first {
            todayPlanItems = (plan.items ?? []).sorted { $0.sortOrder < $1.sortOrder }
            totalPlannedMinutes = todayPlanItems.reduce(0) { $0 + $1.estimatedMinutes }
            completedMinutes = todayPlanItems.filter(\.isCompleted).reduce(0) { $0 + $1.estimatedMinutes }
        }
    }

    func togglePlanItem(_ item: PlannedItem) {
        item.isCompleted.toggle()
        todayPlanItems = todayPlanItems.sorted { $0.sortOrder < $1.sortOrder }
    }
}