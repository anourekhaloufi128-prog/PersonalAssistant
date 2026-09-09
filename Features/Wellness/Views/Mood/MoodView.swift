import SwiftUI
import SwiftData

struct MoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MoodLog.loggedAt, order: .reverse) private var logs: [MoodLog]

    var body: some View {
        List {
            Section("How do you feel now?") {
                MoodLogEditorView()
            }
            Section("History") {
                ForEach(logs.prefix(20)) { log in
                    HStack {
                        Text(moodIcon(log.mood))
                        VStack(alignment: .leading) {
                            Text(log.mood.rawValue)
                                .font(.subheadline.weight(.medium))
                            if !log.note.isEmpty {
                                Text(log.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(log.energy.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(log.loggedAt.timeLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Mood & Energy")
    }

    private func moodIcon(_ mood: MoodLevel) -> String {
        switch mood {
        case .veryLow: return "😔"
        case .low: return "😕"
        case .neutral: return "😐"
        case .good: return "🙂"
        case .veryGood: return "😄"
        }
    }
}

struct MoodLogEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var mood: MoodLevel = .neutral
    @State private var energy: EnergyLevel = .medium
    @State private var note = ""

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ForEach(MoodLevel.allCases, id: \.self) { level in
                    Button {
                        mood = level
                    } label: {
                        Text(moodIcon(level))
                            .font(.title2)
                            .padding(10)
                            .background(mood == level ? Color.blue.opacity(0.2) : Color.clear, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 16) {
                ForEach(EnergyLevel.allCases, id: \.self) { level in
                    Button {
                        energy = level
                    } label: {
                        Text(level.rawValue)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(energy == level ? Color.green.opacity(0.2) : Color.clear, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("Optional note", text: $note)

            Button {
                let log = MoodLog(mood: mood, energy: energy)
                log.note = note
                modelContext.insert(log)
                note = ""
                mood = .neutral
                energy = .medium
            } label: {
                Text("Save Check-in")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 8)
    }

    private func moodIcon(_ mood: MoodLevel) -> String {
        switch mood {
        case .veryLow: return "😔"
        case .low: return "😕"
        case .neutral: return "😐"
        case .good: return "🙂"
        case .veryGood: return "😄"
        }
    }
}