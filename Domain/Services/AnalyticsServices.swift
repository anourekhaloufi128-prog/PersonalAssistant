import Foundation

struct StreakCalculator {
    static func currentStreak(dates: [Date], calendar: Calendar = .current) -> Int {
        guard !dates.isEmpty else { return 0 }
        let daySet = Set(dates.map { calendar.startOfDay(for: $0) })
        var streak = 0
        var cursor = calendar.startOfDay(for: Date())
        while daySet.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    static func completionRate(loggedDays: Int, totalDays: Int) -> Double {
        guard totalDays > 0 else { return 0 }
        return Double(loggedDays) / Double(totalDays)
    }

    static func bestStreak(dates: [Date], calendar: Calendar = .current) -> Int {
        let sorted = dates.map { calendar.startOfDay(for: $0) }.sorted()
        guard !sorted.isEmpty else { return 0 }
        var best = 1
        var current = 1
        for i in 1..<sorted.count {
            if let dayDiff = calendar.dateComponents([.day], from: sorted[i - 1], to: sorted[i]).day,
               dayDiff == 1 {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }
}

struct QuizScorer {
    static func score(questions: [QuizQuestion]) -> (correct: Int, total: Int, percentage: Double) {
        let answered = questions
        let correct = answered.filter(\.isCorrect).count
        let total = answered.count
        let percentage = total == 0 ? 0 : (Double(correct) / Double(total)) * 100
        return (correct, total, percentage)
    }
}

struct MasteryCalculator {
    static func updateMastery(current: Int, sessionCount: Int) -> Int {
        let progress = min(Double(sessionCount) * 8.0, 90.0)
        return max(Int(current), Int(progress))
    }
}

struct TimeWindowCalculator {
    static func isWithinSchedule(startHour: Int?, endHour: Int?, now: Date = Date()) -> Bool {
        guard let startHour else { return true }
        guard let endHour else { return true }
        let hour = Calendar.current.component(.hour, from: now)
        if startHour <= endHour {
            return hour >= startHour && hour < endHour
        }
        return hour >= startHour || hour < endHour
    }
}