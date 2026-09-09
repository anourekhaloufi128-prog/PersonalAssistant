import Foundation
import SwiftData

@MainActor
final class AIActionExecutor {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func execute(_ request: AIActionRequest) -> AIActionResult {
        switch request.action {
        case .createTask:
            return createTask(request)
        case .completeTask:
            return completeTask(request)
        case .rescheduleTask:
            return rescheduleTask(request)
        case .createStudyPlan, .recommendNextAction:
            return .init(success: true, message: "Planning is handled by the planner service.")
        case .startFocus:
            return .init(success: true, message: "Focus session service is ready.")
        case .completeFocus:
            return .init(success: true, message: "Focus session ended.")
        case .createHabit:
            return createHabit(request)
        case .logWater:
            return logWater(request)
        case .logExercise:
            return logExercise(request)
        case .createBusinessTask:
            return createBusinessTask(request)
        case .createClient:
            return createClient(request)
        case .createGoal:
            return createGoal(request)
        case .explain:
            return .init(success: true, message: "Explanation requested. Please ask the tutor.")
        case .createQuiz:
            return .init(success: false, message: "Quiz generation is available in the Study module.")
        case .createFlashcards:
            return .init(success: false, message: "Flashcard generation is available in the Study module.")
        case .deleteTask:
            return deleteTask(request)
        case .deleteClient:
            return deleteClient(request)
        case .deleteBusinessProject:
            return deleteBusinessProject(request)
        case .deleteFinancialRecord:
            return .init(success: false, message: "Financial record deletion is disabled by policy.")
        case .disableProtectionRules:
            return .init(success: false, message: "Protection rules cannot be disabled by the AI.")
        }
    }

    private func createTask(_ request: AIActionRequest) -> AIActionResult {
        guard let title = request.parameters["title"] else {
            return .init(success: false, message: "A task title is required.")
        }
        let task = StudyTask(
            title: title,
            description: request.parameters["description"] ?? "",
            category: TaskCategory(rawValue: request.parameters["category"] ?? "") ?? .study,
            priority: TaskPriority(rawValue: request.parameters["priority"] ?? "") ?? .medium,
            estimatedMinutes: Int(request.parameters["estimatedMinutes"] ?? "") ?? 30
        )
        task.createdViaAI = true
        if let deadlineISO = request.parameters["deadline"], let deadline = ISO8601DateFormatter().date(from: deadlineISO) {
            task.deadline = deadline
        }
        modelContext.insert(task)
        return .init(success: true, message: "Task created.", relatedID: task.id)
    }

    private func completeTask(_ request: AIActionRequest) -> AIActionResult {
        guard let idString = request.parameters["id"], let id = UUID(uuidString: idString) else {
            return .init(success: false, message: "A valid task ID is required.")
        }
        let descriptor = FetchDescriptor<StudyTask>(predicate: #Predicate { $0.id == id })
        guard let task = try? modelContext.fetch(descriptor).first else {
            return .init(success: false, message: "Task not found.")
        }
        task.status = .completed
        task.completedAt = Date()
        task.updatedAt = Date()
        return .init(success: true, message: "Task completed.", relatedID: id)
    }

    private func rescheduleTask(_ request: AIActionRequest) -> AIActionResult {
        guard let idString = request.parameters["id"], let id = UUID(uuidString: idString) else {
            return .init(success: false, message: "A valid task ID is required.")
        }
        let descriptor = FetchDescriptor<StudyTask>(predicate: #Predicate { $0.id == id })
        guard let task = try? modelContext.fetch(descriptor).first else {
            return .init(success: false, message: "Task not found.")
        }
        if let deadlineISO = request.parameters["deadline"], let deadline = ISO8601DateFormatter().date(from: deadlineISO) {
            task.deadline = deadline
            task.updatedAt = Date()
            return .init(success: true, message: "Task rescheduled.", relatedID: id)
        }
        return .init(success: false, message: "A new deadline is required.")
    }

    private func createHabit(_ request: AIActionRequest) -> AIActionResult {
        guard let name = request.parameters["name"] else {
            return .init(success: false, message: "A habit name is required.")
        }
        let habit = Habit(name: name)
        if let targetString = request.parameters["targetCount"], let target = Int(targetString) {
            habit.targetCount = target
        }
        modelContext.insert(habit)
        return .init(success: true, message: "Habit created.", relatedID: habit.id)
    }

    private func logWater(_ request: AIActionRequest) -> AIActionResult {
        let amount = Int(request.parameters["amountML"] ?? "250") ?? 250
        let log = WaterLog(amountML: amount)
        modelContext.insert(log)
        return .init(success: true, message: "Water logged.")
    }

    private func logExercise(_ request: AIActionRequest) -> AIActionResult {
        let duration = Int(request.parameters["durationMinutes"] ?? "20") ?? 20
        let type = ExerciseType(rawValue: request.parameters["type"] ?? "") ?? .custom
        let log = ExerciseLog(exerciseType: type, durationMinutes: duration)
        modelContext.insert(log)
        return .init(success: true, message: "Exercise logged.", relatedID: log.id)
    }

    private func createBusinessTask(_ request: AIActionRequest) -> AIActionResult {
        guard let title = request.parameters["title"] else {
            return .init(success: false, message: "A business task title is required.")
        }
        let kind = BusinessTaskKind(rawValue: request.parameters["kind"] ?? "") ?? .general
        let task = BusinessTask(title: title, description: request.parameters["description"] ?? "", kind: kind)
        modelContext.insert(task)
        return .init(success: true, message: "Business task created.", relatedID: task.id)
    }

    private func createClient(_ request: AIActionRequest) -> AIActionResult {
        guard let name = request.parameters["name"] else {
            return .init(success: false, message: "A client name is required.")
        }
        let client = BusinessClient(name: name, company: request.parameters["company"] ?? "")
        client.email = request.parameters["email"] ?? ""
        modelContext.insert(client)
        return .init(success: true, message: "Client created.", relatedID: client.id)
    }

    private func createGoal(_ request: AIActionRequest) -> AIActionResult {
        guard let name = request.parameters["name"] else {
            return .init(success: false, message: "A goal name is required.")
        }
        let goal = Goal(name: name)
        modelContext.insert(goal)
        return .init(success: true, message: "Goal created.", relatedID: goal.id)
    }

    private func deleteTask(_ request: AIActionRequest) -> AIActionResult {
        guard let idString = request.parameters["id"], let id = UUID(uuidString: idString) else {
            return .init(success: false, message: "A valid task ID is required.")
        }
        let descriptor = FetchDescriptor<StudyTask>(predicate: #Predicate { $0.id == id })
        guard let task = try? modelContext.fetch(descriptor).first else {
            return .init(success: false, message: "Task not found.")
        }
        modelContext.delete(task)
        return .init(success: true, message: "Task deleted.")
    }

    private func deleteClient(_ request: AIActionRequest) -> AIActionResult {
        guard let idString = request.parameters["id"], let id = UUID(uuidString: idString) else {
            return .init(success: false, message: "A valid client ID is required.")
        }
        let descriptor = FetchDescriptor<BusinessClient>(predicate: #Predicate { $0.id == id })
        guard let client = try? modelContext.fetch(descriptor).first else {
            return .init(success: false, message: "Client not found.")
        }
        modelContext.delete(client)
        return .init(success: true, message: "Client deleted.")
    }

    private func deleteBusinessProject(_ request: AIActionRequest) -> AIActionResult {
        guard let idString = request.parameters["id"], let id = UUID(uuidString: idString) else {
            return .init(success: false, message: "A valid project ID is required.")
        }
        let descriptor = FetchDescriptor<BusinessProject>(predicate: #Predicate { $0.id == id })
        guard let project = try? modelContext.fetch(descriptor).first else {
            return .init(success: false, message: "Project not found.")
        }
        modelContext.delete(project)
        return .init(success: true, message: "Project deleted.")
    }
}