import SwiftUI
import SwiftData

struct SleepView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SleepLog.bedtime, order: .reverse) private var logs: [SleepLog]

    var body: some View {
        List {
            if let last = logs.first {
                Section("Last Night") {
                    VStack(alignment: .leading, spacing: 8) {
                        LabeledContent("Duration", value: String(format: "%.1f hours", last.durationHours))
                        LabeledContent("Quality", value: last.quality.rawValue)
                        LabeledContent("Bedtime", value: last.bedtime.timeLabel)
                        LabeledContent("Wake", value: last.wakeTime.timeLabel)
                    }
                }
            }

            Section("Log Sleep") {
                SleepLogEditorView()
            }

            Section("History") {
                ForEach(logs) { log in
                    HStack {
                        Text(log.bedtime.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f h", log.durationHours))
                            .font(.caption.weight(.semibold))
                        Text(log.quality.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Sleep")
    }
}

struct SleepLogEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var bedtime = defaultBedtime
    @State private var wakeTime = defaultWake
    @State private var quality: SleepQuality = .medium
    @State private var notes = ""

    var body: some View {
        VStack(spacing: 12) {
            DatePicker("Bedtime", selection: $bedtime)
            DatePicker("Wake time", selection: $wakeTime)
            Picker("Quality", selection: $quality) {
                ForEach(SleepQuality.allCases, id: \.self) { q in
                    Text(q.rawValue).tag(q)
                }
            }
            .pickerStyle(.segmented)

            Button {
                let log = SleepLog(bedtime: bedtime, wakeTime: wakeTime, quality: quality)
                log.notes = notes
                modelContext.insert(log)
                reset()
            } label: {
                Text("Save Sleep Entry")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .navigationBarBackButtonHidden(false)
        }
        .padding(.vertical, 8)
    }

    private func reset() {
        bedtime = Self.defaultBedtime
        wakeTime = Self.defaultWake
        quality = .medium
    }

    private static var defaultBedtime: Date {
        guard let date = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) else { return Date() }
        return date
    }

    private static var defaultWake: Date {
        guard let date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) else { return Date() }
        return date
    }
}