//
//  WidgetSnapshotService.swift
//  PersonalAssistant
//
//  Builds the widget snapshot from the SwiftData store and asks WidgetKit
//  to refresh the timeline. App target only.
//

import Foundation
import SwiftData
import WidgetKit

struct WidgetSnapshotService {
    static func refresh(modelContext: ModelContext) {
        let pending = (try? modelContext.fetch(FetchDescriptor<StudyTask>()))?
            .filter { $0.status == .todo } ?? []
        let nowTask = pending.sorted { $0.priority > $1.priority }.first
        let nextTask = pending.dropFirst().first

        let focusSessions = (try? modelContext.fetch(FetchDescriptor<FocusSession>())) ?? []
        let studySessions = (try? modelContext.fetch(FetchDescriptor<StudySession>())) ?? []

        let focusToday = focusSessions
            .filter { Calendar.current.isDate($0.startedAt, inSameDayAs: Date()) }
            .reduce(0) { $0 + $1.actualDurationMinutes }
        let studyToday = studySessions
            .filter { Calendar.current.isDate($0.startedAt, inSameDayAs: Date()) }
            .reduce(0) { $0 + $1.durationMinutes }

        let snapshot = WidgetSnapshot(
            nowTaskTitle: nowTask?.title ?? "Nothing pending",
            nowTaskMinutes: nowTask?.estimatedMinutes ?? 0,
            nowSubjectName: nowTask?.subject?.name,
            nextTaskTitle: nextTask?.title ?? "All caught up",
            focusMinutesToday: focusToday,
            studyMinutesToday: studyToday
        )

        WidgetSnapshot.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}