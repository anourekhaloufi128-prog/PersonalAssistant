import SwiftUI
import SwiftData

struct StudyHistoryView: View {
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]

    var body: some View {
        List {
            Section("This Week") {
                HStack {
                    StatCard(title: "This week", value: weeklyMinutes.minutesToHoursLabel, icon: "clock.fill", color: .blue)
                    StatCard(title: "Sessions", value: "\(sessions.count)", icon: "number", color: .green)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section("Sessions") {
                ForEach(sessions.prefix(30)) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(session.subject?.name ?? "Study session")
                                .font(.subheadline.weight(.medium))
                            if let topic = session.topic {
                                Text(topic.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(session.durationMinutes) min")
                                .font(.subheadline.weight(.semibold))
                            Text(session.completion.rawValue)
                                .font(.caption2)
                                .foregroundStyle(session.completion == .completed ? .green : .orange)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Study History")
    }

    private var weeklyMinutes: Int {
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { $0.startedAt > weekStart }.reduce(0) { $0 + $1.durationMinutes }
    }
}