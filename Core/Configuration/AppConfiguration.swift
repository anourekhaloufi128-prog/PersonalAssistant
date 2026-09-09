import Foundation

enum AppConfiguration {
    static let shared = AppConfiguration()

    let apiBaseURL: URL
    let supabaseURL: URL?
    let supabaseAnonKey: String?

    /// Secure configuration loaded from environment without exposing secrets in the repository.
    /// Set via Xcode build settings (INFOPLIST_KEY or a generated Config.swift).
    private init() {
        let env = ProcessInfo.processInfo.environment
        self.apiBaseURL = URL(string: env["API_BASE_URL"] ?? "https://api.your-domain.example") ?? URL(string: "https://api.your-domain.example")!
        if let urlString = env["SUPABASE_URL"] {
            self.supabaseURL = URL(string: urlString)
        } else {
            self.supabaseURL = nil
        }
        self.supabaseAnonKey = env["SUPABASE_ANON_KEY"]
    }

    /// These values ship as empty placeholders only. Real keys are injected at build time
    /// and never committed to source control. Service-role and AI provider keys are
    /// server-side only and are NOT shipped with the iOS app.
    static let isAIEnabled = true
    static let isCloudSyncAvailable = false
    static let minimumDeploymentTarget: String = "17.0"
    static let appVersion = "1.0.0"
    static let buildNumber = "1"
    static let bundleIdentifier = "com.anwar.personalassistant"
}