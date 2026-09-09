import SwiftUI
import SwiftData

struct ActiveFocusView: View {
    let session: FocusSession
    @ObservedObject var manager: FocusSessionManager
    var onFinished: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var now = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "timer")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)

                VStack(spacing: 8) {
                    Text(session.label ?? session.subject?.name ?? "Focus Session")
                        .font(.title2.weight(.bold))
                    if let task = description {
                        Text(task)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(timeRemainingLabel)
                    .font(.system(size: 64, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(session.isPaused ? .secondary : .primary)

                Text(session.isPaused ? "Paused" : "Focus active")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(session.isPaused ? .orange : .green)

                Spacer()

                HStack(spacing: 16) {
                    Button {
                        if session.isPaused {
                            manager.resume()
                        } else {
                            manager.pause()
                        }
                    } label: {
                        Image(systemName: session.isPaused ? "play.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 48))
                    }
                    .disabled(session.completion != .inProgress)

                    Button {
                        manager.finish()
                        onFinished?()
                        dismiss()
                    } label: {
                        Label("End", systemImage: "stop.circle.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    Button {
                        manager.recordInterruption()
                        manager.cancel()
                        onFinished?()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .background(AppTheme.background)
            .navigationTitle("Focus Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                startTicker()
            }
        }
    }

    private func startTicker() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            now = Date()
            if session.completion != .inProgress && !session.isActive {
                timer.invalidate()
            }
        }
    }

    private var timeRemainingLabel: String {
        let interval = manager.remainingDuration(of: session)
        let total = Int(interval.rounded(.up))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var description: String? {
        if let task = session.task { return task.title }
        if let topic = session.topic { return topic.title }
        return nil
    }
}