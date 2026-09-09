import Foundation
import SwiftData

struct AIContext: Encodable {
    var studyContext: StudyContext?
    var taskContext: TaskContext?
    var businessContext: BusinessContext?
    var goalContext: GoalContext?
    var wellnessContext: WellnessContext?
    var focusContext: FocusContext?
    var preferences: MemoryContext?
}

struct StudyContext: Encodable {
    var subjects: [CompactSubject]
    var exams: [CompactExam]
    var recentStudyMinutes: Int
}

struct TaskContext: Encodable {
    var pendingTasks: [CompactTask]
    var tasksDueToday: Int
    var completedToday: Int
}

struct BusinessContext: Encodable {
    var pendingBusinessTasks: [CompactBusinessTask]
    var activeProjects: Int
    var openLeads: Int
    var followUpsDueSoon: Int
}

struct GoalContext: Encodable {
    var activeGoals: [CompactGoal]
}

struct WellnessContext: Encodable {
    var sleepLastNight: Double?
    var waterTodayML: Int
    var exerciseMinutesThisWeek: Int
    var habitCompletionsToday: Int
}

struct FocusContext: Encodable {
    var focusMinutesToday: Int
    var sessionsCompletedToday: Int
    var activeSession: Bool
}

struct MemoryContext: Encodable {
    var preferredStudyDuration: Int
    var preferredBreakDuration: Int
    var preferredStudyTime: String
    var energyLevel: String
}

struct CompactSubject: Codable {
    var id: UUID
    var name: String
    var difficulty: String
    var averageMastery: Double
}

struct CompactExam: Codable {
    var id: UUID
    var title: String
    var daysRemaining: Int
    var preparationProgress: Int
}

struct CompactTask: Codable {
    var id: UUID
    var title: String
    var category: String
    var priority: String
    var status: String
    var deadline: Date?
    var estimatedMinutes: Int
}

struct CompactBusinessTask: Codable {
    var id: UUID
    var title: String
    var kind: String
    var status: String
    var dueDate: Date?
}

struct CompactGoal: Codable {
    var id: UUID
    var name: String
    var progress: Double
    var targetDate: Date?
}

struct ContextAssembler {
    let modelContext: ModelContext

    func assemble(for request: String) -> AIContext {
        let lowercased = request.lowercased()
        var context = AIContext()

        let businessKeywords = ["client", "lead", "business", "invoice", "project", "follow"]
        let studyKeywords = ["study", "exam", "subject", "math", "physics", "revision", "homework", "quiz"]
        let wellnessKeywords = ["water", "sleep", "habit", "exercise", "mood", "energy"]
        let goalKeywords = ["goal", "milestone", "target"]
        let focusKeywords = ["focus", "concentrate", "pomodoro"]

        if studyKeywords.contains(where: lowercased.contains) { context.studyContext = buildStudyContext() }
        if businessKeywords.contains(where: lowercased.contains) { context.businessContext = buildBusinessContext() }
        if wellnessKeywords.contains(where: lowercased.contains) { context.wellnessContext = buildWellnessContext() }
        if goalKeywords.contains(where: lowercased.contains) { context.goalContext = buildGoalContext() }
        if focusKeywords.contains(where: lowercased.contains) { context.focusContext = buildFocusContext() }
        if request.isEmpty || lowercased.contains("now") || lowercased.contains("today") || lowercased.contains("plan") {
            context.taskContext = buildTaskContext()
        }

        context.preferences = loadPreferences()
        return context
    }

    private func buildStudyContext() -> StudyContext {
        let subjects = (try? modelContext.fetch(FetchDescriptor<Subject>())) ?? []
        let exams = (try? modelContext.fetch(FetchDescriptor<Exam>())) ?? []
        let sessions = (try? modelContext.fetch(FetchDescriptor<StudySession>())) ?? []

        let recentMinutes = sessions
            .filter { Calendar.current.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.durationMinutes }

        return StudyContext(
            subjects: subjects.filter { !$0.isArchived }.map {
                CompactSubject(id: $0.id, name: $0.name, difficulty: $0.difficulty.rawValue, averageMastery: $0.averageMastery)
            },
            exams: exams.filter(\.isUpcoming).map {
                CompactExam(id: $0.id, title: $0.title, daysRemaining: max(0, $0.daysRemaining), preparationProgress: $0.preparationProgress)
            },
            recentStudyMinutes: recentMinutes
        )
    }

    private func buildTaskContext() -> TaskContext {
        let tasks = (try? modelContext.fetch(FetchDescriptor<StudyTask>())) ?? []
        let today = Calendar.current.startOfDay(for: Date())

        return TaskContext(
            pendingTasks: tasks.filter { $0.status == .todo }.map {
                CompactTask(id: $0.id, title: $0.title, category: $0.category.rawValue, priority: $0.priority.rawValue, status: $0.status.rawValue, deadline: $0.deadline, estimatedMinutes: $0.estimatedMinutes)
            },
            tasksDueToday: tasks.filter { $0.deadline != nil && Calendar.current.isDate($0.deadline!, inSameDayAs: today) }.count,
            completedToday: tasks.filter { $0.completedAt != nil && Calendar.current.isDate($0.completedAt!, inSameDayAs: today) }.count
        )
    }

    private func buildBusinessContext() -> BusinessContext {
        let tasks = (try? modelContext.fetch(FetchDescriptor<BusinessTask>())) ?? []
        let projects = (try? modelContext.fetch(FetchDescriptor<BusinessProject>())) ?? []
        let leads = (try? modelContext.fetch(FetchDescriptor<BusinessLead>())) ?? []

        return BusinessContext(
            pendingBusinessTasks: tasks.filter { $0.status == .todo }.map {
                CompactBusinessTask(id: $0.id, title: $0.title, kind: $0.kind.rawValue, status: $0.status.rawValue, dueDate: $0.dueDate)
            },
            activeProjects: projects.filter { $0.status == .active }.count,
            openLeads: leads.filter { $0.status != .lost && $0.status != .converted }.count,
            followUpsDueSoon: leads.filter { $0.followUpDate != nil && $0.followUpDate! < Date().addingTimeInterval(3 * 86400) }.count
        )
    }

    private func buildGoalContext() -> GoalContext {
        let goals = (try? modelContext.fetch(FetchDescriptor<Goal>())) ?? []
        return GoalContext(activeGoals: goals.filter { !$0.isCompleted && !$0.isArchived }.map {
            CompactGoal(id: $0.id, name: $0.name, progress: $0.progress, targetDate: $0.targetDate)
        })
    }

    private func buildWellnessContext() -> WellnessContext {
        let sleep = (try? modelContext.fetch(FetchDescriptor<SleepLog>())) ?? []
        let water = (try? modelContext.fetch(FetchDescriptor<WaterLog>())) ?? []
        let exercise = (try? modelContext.fetch(FetchDescriptor<ExerciseLog>())) ?? []
        let habitLogs = (try? modelContext.fetch(FetchDescriptor<HabitLog>())) ?? []

        let lastNight = sleep.max(by: { $0.bedtime < $1.bedtime })
        let waterToday = water.filter { Calendar.current.isDateInToday($0.loggedAt) }.reduce(0) { $0 + $1.amountML }
        let exerciseThisWeek = exercise.filter { Calendar.current.isDate($0.exerciseDate, inSameDayAs: Date()) }.reduce(0) { $0 + $1.durationMinutes }

        return WellnessContext(
            sleepLastNight: lastNight.flatMap { $0.wakeTime > $0.bedtime ? $0.durationHours : nil },
            waterTodayML: waterToday,
            exerciseMinutesThisWeek: exerciseThisWeek,
            habitCompletionsToday: habitLogs.filter { Calendar.current.isDateInToday($0.loggedAt) }.count
        )
    }

    private func buildFocusContext() -> FocusContext {
        let sessions = (try? modelContext.fetch(FetchDescriptor<FocusSession>())) ?? []
        let todaySessions = sessions.filter { Calendar.current.isDate($0.startedAt, inSameDayAs: Date()) }
        return FocusContext(
            focusMinutesToday: todaySessions.reduce(0) { $0 + $1.actualDurationMinutes },
            sessionsCompletedToday: todaySessions.filter { $0.completion == .completed }.count,
            activeSession: todaySessions.contains(where: \.isActive)
        )
    }

    private func loadPreferences() -> MemoryContext {
        let memories = (try? modelContext.fetch(FetchDescriptor<AIMemory>())) ?? []
        func value(for key: String, fallback: String) -> String {
            memories.first { $0.key == key && $0.isEnabled }?.value ?? fallback
        }
        func intValue(for key: String, fallback: Int) -> Int {
            Int(value(for: key, fallback: String(fallback))) ?? fallback
        }
        return MemoryContext(
            preferredStudyDuration: intValue(for: "preferred_study_duration", fallback: 45),
            preferredBreakDuration: intValue(for: "preferred_break_duration", fallback: 10),
            preferredStudyTime: value(for: "preferred_study_time", fallback: "morning"),
            energyLevel: value(for: "energy_level", fallback: "Medium")
        )
    }
}