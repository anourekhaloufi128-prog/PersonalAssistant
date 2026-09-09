import Foundation

struct PriorityRecommendation: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let category: TaskCategory
    let estimatedMinutes: Int
    let reason: String
    let priority: TaskPriority
    let underlyingTaskID: UUID?
    let targetDate: Date?
}

struct PriorityEngine {
    struct RecommendationContext {
        var now: Date = Date()
        var energyLevel: EnergyLevel = .medium
        var timeAvailableMinutes: Int?
    }

    func recommendNextAction(
        tasks: [StudyTask],
        businessTasks: [BusinessTask],
        exams: [Exam],
        habits: [Habit],
        context: RecommendationContext = RecommendationContext()
    ) -> PriorityRecommendation? {
        var candidates: [PriorityRecommendation] = []

        let pendingTasks = tasks.filter { $0.status == .todo || $0.status == .inProgress }
        for task in pendingTasks {
            candidates.append(
                PriorityRecommendation(
                    title: task.title,
                    category: task.category,
                    estimatedMinutes: task.estimatedMinutes,
                    reason: reason(for: task, in: context),
                    priority: task.priority,
                    underlyingTaskID: task.id,
                    targetDate: task.deadline
                )
            )
        }

        let pendingBusiness = businessTasks.filter { $0.status == .todo }
        for task in pendingBusiness {
            candidates.append(
                PriorityRecommendation(
                    title: task.title,
                    category: .business,
                    estimatedMinutes: task.estimatedMinutes,
                    reason: businessReason(for: task, in: context),
                    priority: task.priority,
                    underlyingTaskID: task.id,
                    targetDate: task.dueDate
                )
            )
        }

        let upcomingExams = exams.filter { $0.isUpcoming && $0.daysRemaining >= 0 && $0.daysRemaining <= 7 }
            .sorted { $0.daysRemaining < $1.daysRemaining }

        if let soonestExam = upcomingExams.first, soonestExam.preparationProgress < 80 {
            candidates.append(
                PriorityRecommendation(
                    title: soonestExam.title,
                    category: .study,
                    estimatedMinutes: 45,
                    reason: "Exam is in \(soonestExam.daysRemaining) day\(soonestExam.daysRemaining == 1 ? "" : "s")",
                    priority: .urgent,
                    underlyingTaskID: nil,
                    targetDate: soonestExam.examDate
                )
            )
        }

        guard !candidates.isEmpty else { return nil }

        if let available = context.timeAvailableMinutes {
            let fits = candidates.filter { $0.estimatedMinutes <= available }.sorted(by: { $0.priority > $1.priority })
            if let best = fits.first {
                return best
            }
        }

        return candidates.sorted { $0.priority > $1.priority }.first
    }

    private func reason(for task: StudyTask, in context: RecommendationContext) -> String {
        if task.priority == .urgent { return "Marked as urgent" }
        if let deadline = task.deadline {
            let days = Calendar.current.dateComponents([.day], from: context.now, to: deadline).day ?? 0
            if days <= 1 { return "Due today" }
            if days == 2 { return "Deadline is in 2 days" }
        }
        if task.category == .study && context.energyLevel == .high {
            return "Good time for focused study"
        }
        return "Pending \(task.category.rawValue.lowercased()) task"
    }

    private func businessReason(for task: BusinessTask, in context: RecommendationContext) -> String {
        if task.priority == .urgent { return "Important business commitment" }
        if let due = task.dueDate {
            let days = Calendar.current.dateComponents([.day], from: context.now, to: due).day ?? 0
            if days <= 1 { return "Business deadline today" }
        }
        switch task.kind {
        case .followUp: return "Following up keeps the lead moving"
        case .sendInvoice: return "Outstanding invoice needs attention"
        default: return "Pending business task"
        }
    }
}