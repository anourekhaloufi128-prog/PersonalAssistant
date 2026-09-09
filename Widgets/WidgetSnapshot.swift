//
//  WidgetSnapshot.swift
//  PersonalAssistantWidgets
//
//  Shared snapshot written by the app and read by the widget extension.
//  Compiled into BOTH the app and widget targets.
//

import Foundation

struct WidgetSnapshot: Codable, Equatable {
    var nowTaskTitle: String
    var nowTaskMinutes: Int
    var nowSubjectName: String?
    var nextTaskTitle: String
    var focusMinutesToday: Int
    var studyMinutesToday: Int

    static let suiteName = "group.com.anwar.personalassistant"
    static let key = "widget.snapshot"

    static func read(from defaults: UserDefaults = UserDefaults(suiteName: suiteName) ?? .standard) -> WidgetSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    static func save(_ snapshot: WidgetSnapshot, to defaults: UserDefaults = UserDefaults(suiteName: suiteName) ?? .standard) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }
}