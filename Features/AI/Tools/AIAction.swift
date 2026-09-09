import Foundation

enum AIActionName: String, Codable, CaseIterable {
    case createTask
    case completeTask
    case rescheduleTask
    case createStudyPlan
    case startFocus
    case completeFocus
    case createHabit
    case logWater
    case logExercise
    case createBusinessTask
    case createClient
    case createGoal
    case recommendNextAction
    case explain
    case createQuiz
    case createFlashcards
    case deleteTask
    case deleteClient
    case deleteBusinessProject
    case deleteFinancialRecord
    case disableProtectionRules

    var isDestructive: Bool {
        switch self {
        case .deleteTask, .deleteClient, .deleteBusinessProject, .deleteFinancialRecord, .disableProtectionRules:
            return true
        default:
            return false
        }
    }
}

enum AIPermission: String, Codable, CaseIterable, Comparable {
    case readTasks = "READ_TASKS"
    case createTask = "CREATE_TASK"
    case editTask = "EDIT_TASK"
    case deleteTask = "DELETE_TASK"
    case readBusiness = "READ_BUSINESS"
    case createBusinessTask = "CREATE_BUSINESS_TASK"
    case startFocus = "START_FOCUS"
    case readGoals = "READ_GOALS"
    case createGoal = "CREATE_GOAL"

    var sortOrder: Int {
        switch self {
        case .readTasks: return 0
        case .createTask: return 1
        case .editTask: return 2
        case .deleteTask: return 3
        case .readBusiness: return 4
        case .createBusinessTask: return 5
        case .startFocus: return 6
        case .readGoals: return 7
        case .createGoal: return 8
        }
    }

    static func < (lhs: AIPermission, rhs: AIPermission) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

struct AIActionRequest: Codable {
    let action: AIActionName
    let parameters: [String: String]
    let requiresConfirmation: Bool

    static func from(json: Any) -> AIActionRequest? {
        guard
            let dict = json as? [String: Any],
            let actionString = dict["action"] as? String,
            let action = AIActionName(rawValue: actionString)
        else { return nil }
        let params = (dict["parameters"] as? [String: Any])?.compactMapValues { String(describing: $0) } ?? [:]
        return AIActionRequest(
            action: action,
            parameters: params,
            requiresConfirmation: dict["requiresConfirmation"] as? Bool ?? action.isDestructive
        )
    }
}

struct AIActionResult {
    let success: Bool
    let message: String
    let needsConfirmation: Bool
    let relatedID: UUID?

    init(success: Bool, message: String, needsConfirmation: Bool = false, relatedID: UUID? = nil) {
        self.success = success
        self.message = message
        self.needsConfirmation = needsConfirmation
        self.relatedID = relatedID
    }
}