import XCTest
@testable import PersonalAssistant

final class PriorityEngineTests: XCTestCase {
    func testRecommendationPicksUrgentFirst() {
        let engine = PriorityEngine()
        let urgent = StudyTask(title: "Physics revision", priority: .urgent, estimatedMinutes: 45)
        let normal = StudyTask(title: "Math homework", priority: .low, estimatedMinutes: 20)

        let recommendation = engine.recommendNextAction(
            tasks: [normal, urgent],
            businessTasks: [],
            exams: [],
            habits: []
        )

        XCTAssertEqual(recommendation?.title, "Physics revision")
    }

    func testRecommendationHonorsAvailableTime() {
        let engine = PriorityEngine()
        let long = StudyTask(title: "Long session", priority: .urgent, estimatedMinutes: 120)
        let short = StudyTask(title: "Quick review", priority: .medium, estimatedMinutes: 20)

        let recommendation = engine.recommendNextAction(
            tasks: [long, short],
            businessTasks: [],
            exams: [],
            habits: [],
            context: .init(now: Date(), energyLevel: .medium, timeAvailableMinutes: 30)
        )

        XCTAssertEqual(recommendation?.title, "Quick review")
    }

    func testRecommendationNilWhenNothingPending() {
        let engine = PriorityEngine()
        let done = StudyTask(title: "Completed", priority: .high, estimatedMinutes: 30)
        done.status = .completed

        let recommendation = engine.recommendNextAction(
            tasks: [done],
            businessTasks: [],
            exams: [],
            habits: []
        )

        XCTAssertNil(recommendation)
    }

    func testExamSurfacesSoonestExam() {
        let engine = PriorityEngine()
        let exam = Exam(title: "Algebra Exam", examDate: Date().addingTimeInterval(2 * 86400))
        exam.preparationProgress = 10

        let recommendation = engine.recommendNextAction(
            tasks: [],
            businessTasks: [],
            exams: [exam],
            habits: []
        )

        XCTAssertEqual(recommendation?.title, "Algebra Exam")
        XCTAssertEqual(recommendation?.reason, "Exam is in 2 days")
    }
}

final class StudyPlannerTests: XCTestCase {
    func testPlannerBalancesCategories() {
        let planner = StudyPlanner()
        let math = Subject(name: "Mathematics")
        let task = StudyTask(title: "Algebra", category: .study, estimatedMinutes: 45)
        task.subject = math
        let business = BusinessTask(title: "Proposal", estimatedMinutes: 30)

        let plan = planner.createDailyPlan(input: .init(
            tasks: [task],
            businessTasks: [business],
            exams: [],
            habits: [],
            availableMinutes: 180
        ))

        XCTAssertGreaterThan(plan.count, 0)
        XCTAssertTrue(plan.contains { $0.category == .study })
        XCTAssertTrue(plan.contains { $0.category == .business })
    }

    func testPlannerDoesNotOverflowTime() {
        let planner = StudyPlanner()
        let tasks = (0..<10).map { StudyTask(title: "Task \($0)", estimatedMinutes: 60) }

        let plan = planner.createDailyPlan(input: .init(
            tasks: tasks,
            businessTasks: [],
            exams: [],
            habits: [],
            availableMinutes: 120
        ))

        let total = plan.reduce(0) { $0 + $1.minutes }
        XCTAssertLessThanOrEqual(total, 120)
    }
}

final class StreakCalculatorTests: XCTestCase {
    func testCurrentStreakCountsBackwardsFromToday() {
        let today = Date()
        let calendar = Calendar.current
        let day1 = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: today)!)
        let day2 = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -2, to: today)!)
        let day3 = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -4, to: today)!)

        XCTAssertEqual(StreakCalculator.currentStreak(dates: [day1, day2, day3], calendar: calendar), 2)
    }

    func testBestStreakFindsLongestRun() {
        let today = Date()
        let calendar = Calendar.current
        let dates: [Date] = (0..<5)
            .map { offset in
                calendar.startOfDay(for: calendar.date(byAdding: .day, value: -offset, to: today)!)
            }

        XCTAssertEqual(StreakCalculator.bestStreak(dates: dates, calendar: calendar), 5)
    }

    func testCompletionRate() {
        XCTAssertEqual(StreakCalculator.completionRate(loggedDays: 5, totalDays: 10), 0.5)
        XCTAssertEqual(StreakCalculator.completionRate(loggedDays: 0, totalDays: 0), 0)
    }
}

final class QuizScorerTests: XCTestCase {
    func testScoringComputesPercentage() {
        let quiz = Quiz(title: "Test")
        let q1 = QuizQuestion(question: "Q1", options: ["A", "B"], correctIndex: 0)
        q1.userAnswerIndex = 0
        let q2 = QuizQuestion(question: "Q2", options: ["A", "B"], correctIndex: 0)
        q2.userAnswerIndex = 1

        let result = QuizScorer.score(questions: [q1, q2])
        XCTAssertEqual(result.correct, 1)
        XCTAssertEqual(result.total, 2)
        XCTAssertEqual(result.percentage, 50)
    }
}

final class AIActionValidationTests: XCTestCase {
    func testValidateActionPayloadAcceptsValid() {
        let valid: [String: Any] = [
            "action": "createTask",
            "parameters": ["title": "Study math"]
        ]
        XCTAssertTrue(AIResponseValidator.validateActionPayload(valid))
    }

    func testValidateActionPayloadRejectsUnknownAction() {
        let invalid: [String: Any] = [
            "action": "dropDatabase",
            "parameters": [:]
        ]
        XCTAssertFalse(AIResponseValidator.validateActionPayload(invalid))
    }

    func testValidateActionPayloadRejectsWrongTypes() {
        let invalid: [String: Any] = [
            "action": "createTask",
            "parameters": ["title": 42]
        ]
        XCTAssertFalse(AIResponseValidator.validateActionPayload(invalid))
    }

    func testSanitizerRedactsKeys() {
        let text = "Key=secret123 auth_token=abc password=xyz"
        let sanitized = AIResponseValidator.sanitizeForLogging(text)
        XCTAssertFalse(sanitized.contains("secret123"))
        XCTAssertFalse(sanitized.contains("abc"))
        XCTAssertFalse(sanitized.contains("xyz"))
    }
}

final class FocusSessionManagerTests: XCTestCase {
    func testRemainingTimeComputedFromEndDate() {
        let manager = FocusSessionManager()
        let session = manager.startSession(plannedMinutes: 45, label: "Math")
        XCTAssertGreaterThan(session.endDate ?? Date.distantPast, Date())
        XCTAssertGreaterThan(manager.remainingDuration(of: session), 0)
    }

    func testFinishMarksCompletion() {
        let manager = FocusSessionManager()
        let session = manager.startSession(plannedMinutes: 25, label: "Study")
        manager.finish()
        XCTAssertEqual(session.completion, .completed)
        XCTAssertFalse(session.isActive)
        XCTAssertNotNil(session.endedAt)
    }

    func testCancelMarksSkipped() {
        let manager = FocusSessionManager()
        let session = manager.startSession(plannedMinutes: 25, label: "Study")
        manager.cancel()
        XCTAssertEqual(session.completion, .skipped)
        XCTAssertFalse(session.isActive)
    }
}

final class TimeWindowCalculatorTests: XCTestCase {
    func testNoScheduleAlwaysApplies() {
        XCTAssertTrue(TimeWindowCalculator.isWithinSchedule(startHour: nil, endHour: nil))
    }

    func testWithinWindow() {
        let date = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
        XCTAssertTrue(TimeWindowCalculator.isWithinSchedule(startHour: 8, endHour: 18, now: date))
    }

    func testOutsideWindow() {
        let date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
        XCTAssertFalse(TimeWindowCalculator.isWithinSchedule(startHour: 8, endHour: 18, now: date))
    }
}