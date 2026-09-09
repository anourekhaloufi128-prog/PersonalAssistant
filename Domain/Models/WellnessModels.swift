import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var habitDescription: String
    var frequency: HabitFrequency
    var targetCount: Int
    var unit: String
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    var userProfile: UserProfile?

    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog]?

    init(name: String, frequency: HabitFrequency = .daily, targetCount: Int = 1) {
        self.id = UUID()
        self.name = name
        self.habitDescription = ""
        self.frequency = frequency
        self.targetCount = targetCount
        self.unit = "times"
        self.isArchived = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        let logDates = Set((logs ?? []).map { calendar.startOfDay(for: $0.loggedAt) })
        var streak = 0
        var day = calendar.startOfDay(for: Date())
        while logDates.contains(day) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return streak
    }
}

enum HabitFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

@Model
final class HabitLog {
    var id: UUID
    var loggedAt: Date
    var count: Int
    var notes: String

    var habit: Habit?

    init(loggedAt: Date = Date(), count: Int = 1) {
        self.id = UUID()
        self.loggedAt = loggedAt
        self.count = count
        self.notes = ""
    }
}

@Model
final class SleepLog {
    var id: UUID
    var bedtime: Date
    var wakeTime: Date
    var quality: SleepQuality
    var notes: String

    init(bedtime: Date, wakeTime: Date, quality: SleepQuality = .medium) {
        self.id = UUID()
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.quality = quality
        self.notes = ""
    }

    var durationHours: Double {
        wakeTime.timeIntervalSince(bedtime) / 3600.0
    }
}

enum SleepQuality: String, Codable, CaseIterable {
    case poor = "Poor"
    case fair = "Fair"
    case medium = "Medium"
    case good = "Good"
    case excellent = "Excellent"
}

@Model
final class WaterLog {
    var id: UUID
    var amountML: Int
    var loggedAt: Date

    init(amountML: Int, loggedAt: Date = Date()) {
        self.id = UUID()
        self.amountML = amountML
        self.loggedAt = loggedAt
    }
}

@Model
final class ExerciseLog {
    var id: UUID
    var exerciseType: ExerciseType
    var durationMinutes: Int
    var exerciseDate: Date
    var notes: String
    var source: ExerciseSource

    init(exerciseType: ExerciseType, durationMinutes: Int, exerciseDate: Date = Date()) {
        self.id = UUID()
        self.exerciseType = exerciseType
        self.durationMinutes = durationMinutes
        self.exerciseDate = exerciseDate
        self.notes = ""
        self.source = .manual
    }
}

enum ExerciseType: String, Codable, CaseIterable {
    case walking = "Walking"
    case running = "Running"
    case cycling = "Cycling"
    case sports = "Sports"
    case stretching = "Stretching"
    case strength = "Strength"
    case custom = "Custom"
}

enum ExerciseSource: String, Codable {
    case manual = "Manual"
    case healthKit = "HealthKit"
}

@Model
final class MoodLog {
    var id: UUID
    var mood: MoodLevel
    var energy: EnergyLevel
    var loggedAt: Date
    var note: String

    init(mood: MoodLevel, energy: EnergyLevel, loggedAt: Date = Date()) {
        self.id = UUID()
        self.mood = mood
        self.energy = energy
        self.loggedAt = loggedAt
        self.note = ""
    }
}

enum MoodLevel: String, Codable, CaseIterable {
    case veryLow = "Very Low"
    case low = "Low"
    case neutral = "Neutral"
    case good = "Good"
    case veryGood = "Very Good"
}