import WidgetKit
import SwiftUI

struct MyDayEntry: TimelineEntry {
    let date: Date

    var nowTitle: String {
        if let name = snapshot.nowSubjectName, !name.isEmpty {
            return "\(name) — \(snapshot.nowTaskTitle)"
        }
        return snapshot.nowTaskTitle
    }

    var nowMinutes: Int { snapshot.nowTaskMinutes }
    var nextTitle: String { snapshot.nextTaskTitle }
    var focusMinutesToday: Int { snapshot.focusMinutesToday }
    var studyMinutesToday: Int { snapshot.studyMinutesToday }

    let snapshot: WidgetSnapshot
}

struct MyDayProvider: TimelineProvider {
    func placeholder(in context: Context) -> MyDayEntry {
        MyDayEntry(
            date: Date(),
            snapshot: WidgetSnapshot(
                nowTaskTitle: "Algebra",
                nowTaskMinutes: 45,
                nowSubjectName: "Mathematics",
                nextTaskTitle: "Physics",
                focusMinutesToday: 60,
                studyMinutesToday: 80
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MyDayEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MyDayEntry>) -> Void) {
        let entries = [loadEntry(), loadEntry(date: Date().addingTimeInterval(1800))]
        let timeline = Timeline(entries: entries, policy: .after(Date().addingTimeInterval(1800)))
        completion(timeline)
    }

    private func loadEntry(date: Date = Date()) -> MyDayEntry {
        MyDayEntry(date: date, snapshot: WidgetSnapshot.read() ?? placeholderSnapshot())
    }

    private func placeholderSnapshot() -> WidgetSnapshot {
        WidgetSnapshot(
            nowTaskTitle: "Nothing pending",
            nowTaskMinutes: 0,
            nowSubjectName: nil,
            nextTaskTitle: "All caught up",
            focusMinutesToday: 0,
            studyMinutesToday: 0
        )
    }
}

struct MyDayWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: MyDayEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .systemLarge:
            largeWidget
        case .accessoryRectangular:
            lockScreenWidget
        case .accessoryCircular:
            circularWidget
        default:
            mediumWidget
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MY DAY")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(entry.nowTitle)
                .font(.headline)
                .lineLimit(2)
            if entry.nowMinutes > 0 {
                Text("\(entry.nowMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            Spacer(minLength: 0)
            Link(destination: deepLink("open")) {
                Text("OPEN")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumWidget: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("MY DAY")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 8) {
                    Link(destination: deepLink("start")) {
                        Text("START")
                    }
                    Link(destination: deepLink("open")) {
                        Text("OPEN")
                    }
                }
                .font(.caption.weight(.bold))
            }

            Text("Now: \(entry.nowTitle)")
                .font(.headline)
            Text("Next: \(entry.nextTitle)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MY DAY")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Link(destination: deepLink("ai")) {
                    Text("AI")
                        .font(.caption.weight(.bold))
                }
            }

            Text("Now: \(entry.nowTitle)")
                .font(.title3.weight(.bold))
            Text("\(entry.nowMinutes) min")
                .font(.headline)
                .foregroundStyle(.blue)

            Text("Next: \(entry.nextTitle)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                VStack(alignment: .leading) {
                    Text("\(entry.focusMinutesToday) min")
                        .font(.headline)
                    Text("focus")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(entry.studyMinutesToday) min")
                        .font(.headline)
                    Text("study")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var lockScreenWidget: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NEXT TASK")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(entry.nextTitle)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Text("\(entry.nowMinutes > 0 ? "\(entry.nowMinutes) min" : "")")
                .font(.caption2)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var circularWidget: some View {
        Gauge(value: Double(entry.focusMinutesToday), in: 0...120) {
            Image(systemName: "timer")
        } currentValueLabel: {
            Text("\(entry.focusMinutesToday)")
        }
        .gaugeStyle(.accessoryCircular)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func deepLink(_ action: String) -> URL {
        URL(string: "personalassistant://\(action)")!
    }
}

struct MyDayWidget: Widget {
    let kind = "MyDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MyDayProvider()) { entry in
            MyDayWidgetView(entry: entry)
        }
        .configurationDisplayName("My Day")
        .description("See what to do now and today's progress.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryCircular])
    }
}

struct PersonalAssistantWidgetsBundle: WidgetBundle {
    var body: some Widget {
        MyDayWidget()
    }
}