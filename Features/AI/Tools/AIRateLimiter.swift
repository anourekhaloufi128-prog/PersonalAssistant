import Foundation

actor AIRateLimiter {
    private struct RequestRecord {
        let timestamp: Date
    }

    private var records: [String: [RequestRecord]] = [:]
    private let maxRequestsPerMinute: Int

    init(maxRequestsPerMinute: Int = 20) {
        self.maxRequestsPerMinute = maxRequestsPerMinute
    }

    func isAllowed(for userID: String) -> Bool {
        let now = Date()
        let cutoff = now.addingTimeInterval(-60)

        var recent = records[userID]?.filter { $0.timestamp > cutoff } ?? []
        recent.append(RequestRecord(timestamp: now))
        records[userID] = recent

        return recent.count <= maxRequestsPerMinute
    }

    func remainingQuota(for userID: String) -> Int {
        let now = Date()
        let cutoff = now.addingTimeInterval(-60)
        let recent = records[userID]?.filter { $0.timestamp > cutoff } ?? []
        return max(0, maxRequestsPerMinute - recent.count)
    }
}

struct AIResponseValidator {
    static func validateActionPayload(_ json: Any) -> Bool {
        guard let dict = json as? [String: Any],
              let action = dict["action"] as? String,
              AIActionName(rawValue: action) != nil else {
            return false
        }

        let allowedKeyTypes: [String: String] = [
            "action": "String",
            "parameters": "Dict"
        ]

        for (key, expectedType) in allowedKeyTypes {
            guard let value = dict[key] else { return false }
            switch expectedType {
            case "String":
                if !(value is String) { return false }
            case "Dict":
                if !(value is [String: Any]) { return false }
            default:
                return false
            }
        }

        if let parameters = dict["parameters"] as? [String: Any] {
            for (_, value) in parameters {
                if !(value is String) && !(value is Int) && !(value is Double) { return false }
            }
        }

        return true
    }

    static func sanitizeForLogging(_ text: String) -> String {
        text
            .replacingOccurrences(of: "api[_-]?key\\s*[=:]\\s*\\S+", with: "[REDACTED]", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "authorization\\s*[=:]\\s*\\S+", with: "[REDACTED]", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "password\\s*[=:]\\s*\\S+", with: "[REDACTED]", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "token\\s*[=:]\\s*\\S+", with: "[REDACTED]", options: [.regularExpression, .caseInsensitive])
    }
}