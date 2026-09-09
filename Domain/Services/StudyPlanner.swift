import Foundation

struct PlannedSession: Identifiable, Equatable {
    let id = UUID()
    let taskTitle: String
    let category: TaskCategory
    let subjectName: String?
    let minutes: Int
    let reason: String
    let startIndex: Int
}

struct StudyPlanner {
    struct PlanInput {
        var tasks: [StudyTask] = []
        var businessTasks: [BusinessTask] = []
        var exams: [Exam] = []
        var habits: [Habit] = []
        var availableMinutes: Int
        var preferredSessionMinutes: Int = 45
        var breakMinutes: Int = 10
        var energyLevel: EnergyLevel = .medium
    }

    func createDailyPlan(input: PlanInput) -> [PlannedSession] {
        var plan: [PlannedSession] = []
        var usedMinutes = 0

        let urgent = input.exams.filter { $0.isUpcoming && $0.daysRemaining <= 3 }
            .sorted { $0.daysRemaining < $1.daysRemaining }
        let studyTasks = input.tasks.filter { $0.status == .todo || $0.status == .inProgress }
            .sorted { $0.priority > $1.priority }

        if let exam = urgent.first {
            let minutes = min(input.preferredSessionMinutes, input.availableMinutes - usedMinutes)
            if minutes >= 20 {
                plan.append(PlannedSession(
                    taskTitle: exam.subject?.name ?? exam.title,
                    category: .study,
                    subjectName: exam.subject?.name,
                    minutes: minutes,
                    reason: "Exam in \(exam.daysRemaining) day\(exam.daysRemaining == 1 ? "" : "s")",
                    startIndex: plan.count
                ))
                usedMinutes += minutes
            }
        }

        for task in studyTasks where usedMinutes + task.estimatedMinutes <= input.availableMinutes {
            plan.append(PlannedSession(
                taskTitle: task.title,
                category: task.category,
                subjectName: task.subject?.name,
                minutes: task.estimatedMinutes,
                reason: task.deadline.map {
                    "Due \(Calendar.current.isDateInToday($0) ? "today" : "\($0.formatted(date: .abbreviated, time: .omitted))")"
                } ?? "Selected priority",
                startIndex: plan.count
            ))
            usedMinutes += task.estimatedMinutes
        }

        for task in input.businessTasks.filter({ $0.status == .todo })
            .sorted(by: { $0.priority > $1.priority })
            where usedMinutes + task.estimatedMinutes <= input.availableMinutes {
            plan.append(PlannedSession(
                taskTitle: task.title,
                category: .business,
                subjectName: nil,
                minutes: task.estimatedMinutes,
                reason: "Business priority",
                startIndex: plan.count
            ))
            usedMinutes += task.estimatedMinutes
        }

        if usedMinutes < input.availableMinutes {
            let wellnessMinutes = min(20, input.availableMinutes - usedMinutes)
            if wellnessMinutes >= 15 {
                plan.append(PlannedSession(
                    taskTitle: "Movement break",
                    category: .wellness,
                    subjectName: nil,
                    minutes: wellnessMinutes,
                    reason: "Balance your day",
                    startIndex: plan.count
                ))
            }
        }

        return plan
    }
}