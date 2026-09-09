import SwiftUI

struct OfflineBanner: View {
    let isOffline: Bool

    var body: some View {
        if isOffline {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                Text("OFFLINE MODE — AI features require an internet connection")
                    .font(.caption.weight(.medium))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.15))
            .foregroundStyle(.orange)
        }
    }
}

struct ErrorStateView: View {
    let title: String
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let retryAction {
                Button("Retry", action: retryAction)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct InterruptedFocusRecoveryCard: View {
    let session: FocusSession
    var onResume: (() -> Void)
    var onFinish: (() -> Void)
    var onDiscard: (() -> Void)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Your focus session was interrupted.", systemImage: "exclamationmark.triangle")
                .font(.headline)
            Text(session.label ?? "Focus session")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Button("Resume", action: onResume)
                    .buttonStyle(.borderedProminent)
                Button("Finish", action: onFinish)
                    .buttonStyle(.bordered)
                Button("Discard", role: .destructive, action: onDiscard)
                    .buttonStyle(.bordered)
            }
        }
        .cardStyle()
    }
}