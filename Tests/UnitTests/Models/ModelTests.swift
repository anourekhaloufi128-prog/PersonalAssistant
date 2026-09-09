import XCTest
@testable import PersonalAssistant

final class DataIntegrityTests: XCTestCase {
    func testSubjectOwnsTopicsCascade() {
        let subject = Subject(name: "Mathematics")
        let topic = Topic(title: "Algebra")
        topic.subject = subject

        XCTAssertEqual(topic.subject?.name, subject.name)
    }

    func testTaskStatusTransitions() {
        let task = StudyTask(title: "Homework")
        XCTAssertEqual(task.status, .todo)
        task.status = .inProgress
        XCTAssertEqual(task.status, .inProgress)
        task.status = .completed
        XCTAssertEqual(task.status, .completed)
    }

    func testExamDaysRemaining() {
        let examTomorrow = Exam(title: "Test", examDate: Date().addingTimeInterval(86400))
        XCTAssertEqual(examTomorrow.daysRemaining, 1)
        XCTAssertTrue(examTomorrow.isUpcoming)
    }

    func testPriorityComparable() {
        XCTAssertLessThan(TaskPriority.low, TaskPriority.urgent)
        XCTAssertGreaterThan(TaskPriority.urgent, TaskPriority.high)
        XCTAssertEqual(TaskPriority.medium.sortOrder, 1)
    }
}

final class ModelEnumsTests: XCTestCase {
    func testTaskStatusDisplayNames() {
        XCTAssertEqual(TaskStatus.todo.displayName, "To Do")
        XCTAssertEqual(TaskStatus.completed.displayName, "Completed")
    }

    func testTopicStatusRawValues() {
        XCTAssertEqual(TopicStatus.notStarted.rawValue, "NOT_STARTED")
        XCTAssertEqual(TopicStatus.inProgress.rawValue, "IN_PROGRESS")
        XCTAssertEqual(TopicStatus.completed.rawValue, "COMPLETED")
    }

    func testClientStatuses() {
        XCTAssertEqual(ClientStatus.active.displayName, "Active")
        XCTAssertEqual(ClientStatus.negotiating.displayName, "Negotiating")
    }

    func testAIXActionDestructiveFlag() {
        XCTAssertTrue(AIActionName.deleteTask.isDestructive)
        XCTAssertFalse(AIActionName.createTask.isDestructive)
    }
}

final class HabitIntegrationTests: XCTestCase {
    func testLoggedTodayDetection() {
        let habit = Habit(name: "Read")
        let log = HabitLog(loggedAt: Date(), count: 1)
        log.habit = habit
        XCTAssertTrue(habit.loggedToday)
        XCTAssertEqual(habit.todayCount, 1)
    }
}

final class BusinessCalculationsTests: XCTestCase {
    func testProjectedProfit() {
        let project = BusinessProject(title: "Website", estimatedRevenue: 1000, costs: 400)
        XCTAssertEqual(project.projectedProfit, 600)
    }

    func testOutstandingInvoice() {
        let invoice = BusinessInvoice(invoiceNumber: "INV-001", amount: 200)
        XCTAssertTrue(invoice.isOutstanding)
        invoice.status = .paid
        XCTAssertFalse(invoice.isOutstanding)
    }
}

final class WellnessCalculationsTests: XCTestCase {
    func testSleepDuration() {
        let calendar = Calendar.current
        let bedtime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
        let wake = calendar.date(byAdding: .hour, value: 8, to: bedtime) ?? Date()
        let log = SleepLog(bedtime: bedtime, wakeTime: wake)
        XCTAssertEqual(log.durationHours, 8, accuracy: 0.01)
    }

    func testMasteryCalculatorProgress() {
        XCTAssertEqual(MasteryCalculator.updateMastery(current: 0, sessionCount: 1), 8)
        XCTAssertEqual(MasteryCalculator.updateMastery(current: 90, sessionCount: 1), 90)
    }
}