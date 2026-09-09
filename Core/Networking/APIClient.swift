import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(statusCode: Int, message: String?)
    case decodingFailed
    case offline
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The server address is invalid."
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .serverError(_, let message):
            return message ?? "The server encountered an error."
        case .decodingFailed:
            return "Could not read the server response."
        case .offline:
            return "You are offline. AI features require an internet connection."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        }
    }
}

actor APIClient {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = AppConfiguration.shared.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func request<T: Decodable>(
        _ path: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil
    ) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = try? SecureTokenStore.shared.readAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            switch http.statusCode {
            case 200...299:
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    throw APIError.decodingFailed
                }
            case 401:
                throw APIError.unauthorized
            case 429:
                throw APIError.rateLimited
            default:
                throw APIError.serverError(statusCode: http.statusCode, message: nil)
            }
        } catch let error as URLError {
            if error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
                throw APIError.offline
            }
            throw APIError.invalidResponse
        }
    }

    func send(_ path: String, method: HTTPMethod = .post, body: Encodable? = nil) async throws {
        let _: EmptyResponse = try await request(path, method: method, body: body)
    }

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case patch = "PATCH"
        case put = "PUT"
        case delete = "DELETE"
    }
}

struct EmptyResponse: Decodable {}