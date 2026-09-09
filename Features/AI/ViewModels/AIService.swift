import Foundation
import UserNotifications

struct AIRequestPayload: Encodable {
    let prompt: String
    let systemPrompt: String
    let context: AIContext
    let userID: String
    let requestID: String
}

struct AIResponse: Decodable {
    let text: String
    let toolCall: AIActionRequest?
    let requiresNewPlan: Bool?
}

protocol AIServiceProtocol {
    func sendMessage(_ message: String, context: AIContext) async throws -> String
    func requestAction(_ message: String, context: AIContext) async throws -> AIActionRequest?
    func generateQuiz(subjectName: String, topic: String?, count: Int) async throws -> [QuizQuestionSeed]
    func generateFlashcards(subjectName: String, topic: String?, count: Int) async throws -> [FlashcardSeed]
}

struct QuizQuestionSeed: Codable {
    let question: String
    let options: [String]
    let correctIndex: Int
}

struct FlashcardSeed: Codable {
    let front: String
    let back: String
    let difficulty: String
}

final class AIService: AIServiceProtocol {
    private let apiClient: APIClient
    private var rateLimiter = AIRateLimiter()
    private let userID = "local-user"

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func sendMessage(_ message: String, context: AIContext) async throws -> String {
        guard await rateLimiter.isAllowed(for: userID) else {
            throw APIError.rateLimited
        }
        let payload = AIRequestPayload(
            prompt: message,
            systemPrompt: Self.systemPrompt,
            context: context,
            userID: userID,
            requestID: UUID().uuidString
        )
        let response: AIResponse = try await apiClient.request("ai/chat", method: .post, body: payload)
        return response.text
    }

    func requestAction(_ message: String, context: AIContext) async throws -> AIActionRequest? {
        guard await rateLimiter.isAllowed(for: userID) else {
            throw APIError.rateLimited
        }
        let prompt = """
        \(message)
        Return any structured action matching the user's intent as a JSON object with keys "action" and "parameters". If no action applies, return only "none".
        """
        let payload = AIRequestPayload(
            prompt: prompt,
            systemPrompt: Self.systemPrompt,
            context: context,
            userID: userID,
            requestID: UUID().uuidString
        )
        let response: AIResponse = try await apiClient.request("ai/action", method: .post, body: payload)
        return response.toolCall
    }

    func generateQuiz(subjectName: String, topic: String?, count: Int) async throws -> [QuizQuestionSeed] {
        let prompt = "Create a \(count)-question quiz about \(subjectName)\(topic.map { " - \($0)" } ?? ""). Include answers."
        let payload = AIRequestPayload(
            prompt: prompt,
            systemPrompt: Self.quizSystemPrompt,
            context: AIContext(),
            userID: userID,
            requestID: UUID().uuidString
        )
        let response: QuizResponse = try await apiClient.request("ai/quiz", method: .post, body: payload)
        return response.questions
    }

    func generateFlashcards(subjectName: String, topic: String?, count: Int) async throws -> [FlashcardSeed] {
        let prompt = "Create \(count) flashcards for \(subjectName)\(topic.map { " - \($0)" } ?? "")."
        let payload = AIRequestPayload(
            prompt: prompt,
            systemPrompt: Self.flashcardSystemPrompt,
            context: AIContext(),
            userID: userID,
            requestID: UUID().uuidString
        )
        let response: FlashcardResponse = try await apiClient.request("ai/flashcards", method: .post, body: payload)
        return response.flashcards
    }

    private static let systemPrompt = """
    You are a calm, direct, practical, supportive personal assistant. You help the user organize study, focus, wellness, business, and personal goals. You are never childish or excessively motivational. Keep responses concise. Never fabricate data the user did not provide. You recommend real, prepared actions.
    """

    private static let quizSystemPrompt = """
    You generate educational quiz questions. Each question has a stem, four options, and exactly one correct index (0-based). Return JSON only matching the requested schema.
    """

    private static let flashcardSystemPrompt = """
    You generate study flashcards. Each has a front, a back, and a difficulty (Easy/Medium/Hard). Return JSON only matching the requested schema.
    """

    private struct QuizResponse: Decodable {
        let questions: [QuizQuestionSeed]
    }

    private struct FlashcardResponse: Decodable {
        let flashcards: [FlashcardSeed]
    }
}