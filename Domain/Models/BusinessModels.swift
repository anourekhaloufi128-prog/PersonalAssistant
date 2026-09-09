import Foundation
import SwiftData

@Model
final class BusinessClient {
    var id: UUID
    var name: String
    var company: String
    var phone: String
    var email: String
    var status: ClientStatus
    var notes: String
    var source: String
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus

    var userProfile: UserProfile?

    @Relationship(deleteRule: .cascade, inverse: \BusinessProject.client)
    var projects: [BusinessProject]?

    @Relationship(deleteRule: .cascade, inverse: \BusinessTask.client)
    var tasks: [BusinessTask]?

    @Relationship(deleteRule: .cascade, inverse: \BusinessInvoice.client)
    var invoices: [BusinessInvoice]?

    init(name: String, company: String = "", status: ClientStatus = .lead) {
        self.id = UUID()
        self.name = name
        self.company = company
        self.phone = ""
        self.email = ""
        self.status = status
        self.notes = ""
        self.source = ""
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncStatus = .local
    }
}

enum ClientStatus: String, Codable, CaseIterable {
    case lead = "LEAD"
    case contacted = "CONTACTED"
    case negotiating = "NEGOTIATING"
    case active = "ACTIVE"
    case completed = "COMPLETED"
    case lost = "LOST"

    var displayName: String {
        self.rawValue.capitalized
    }
}

@Model
final class BusinessLead {
    var id: UUID
    var name: String
    var company: String
    var service: String
    var potentialValue: Double
    var probability: Int
    var followUpDate: Date?
    var nextAction: String
    var status: LeadStatus
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    var userProfile: UserProfile?

    init(name: String, company: String = "", service: String = "", potentialValue: Double = 0) {
        self.id = UUID()
        self.name = name
        self.company = company
        self.service = service
        self.potentialValue = potentialValue
        self.probability = 20
        self.nextAction = ""
        self.status = .new
        self.notes = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum LeadStatus: String, Codable, CaseIterable {
    case new = "NEW"
    case contacted = "CONTACTED"
    case qualified = "QUALIFIED"
    case converted = "CONVERTED"
    case lost = "LOST"

    var displayName: String {
        self.rawValue.capitalized
    }
}

@Model
final class BusinessProject {
    var id: UUID
    var title: String
    var projectDescription: String
    var deadline: Date?
    var status: ProjectStatus
    var estimatedRevenue: Double
    var costs: Double
    var createdAt: Date
    var updatedAt: Date

    var client: BusinessClient?

    @Relationship(deleteRule: .cascade, inverse: \BusinessTask.project)
    var tasks: [BusinessTask]?

    init(title: String, description: String = "", estimatedRevenue: Double = 0, costs: Double = 0) {
        self.id = UUID()
        self.title = title
        self.projectDescription = description
        self.status = .planning
        self.estimatedRevenue = estimatedRevenue
        self.costs = costs
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var projectedProfit: Double {
        estimatedRevenue - costs
    }
}

enum ProjectStatus: String, Codable, CaseIterable {
    case planning = "PLANNING"
    case active = "ACTIVE"
    case waiting = "WAITING"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"

    var displayName: String {
        self.rawValue.capitalized
    }
}

@Model
final class BusinessTask {
    var id: UUID
    var title: String
    var taskDescription: String
    var status: TaskStatus
    var priority: TaskPriority
    var dueDate: Date?
    var estimatedMinutes: Int
    var kind: BusinessTaskKind
    var createdAt: Date
    var updatedAt: Date

    var client: BusinessClient?
    var project: BusinessProject?
    var linkedStudyTask: StudyTask?

    init(title: String, description: String = "", kind: BusinessTaskKind = .general, priority: TaskPriority = .medium) {
        self.id = UUID()
        self.title = title
        self.taskDescription = description
        self.status = .todo
        self.priority = priority
        self.estimatedMinutes = 30
        self.kind = kind
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum BusinessTaskKind: String, Codable, CaseIterable {
    case contactClient = "Contact Client"
    case proposal = "Proposal"
    case buildWebsite = "Build Website"
    case sendInvoice = "Send Invoice"
    case followUp = "Follow Up"
    case fixIssue = "Fix Issue"
    case researchLead = "Research Lead"
    case content = "Content"
    case general = "General"
}

@Model
final class BusinessIncome {
    var id: UUID
    var amount: Double
    var source: String
    var receivedAt: Date
    var category: String
    var notes: String
    var syncStatus: SyncStatus

    init(amount: Double, source: String, receivedAt: Date = Date()) {
        self.id = UUID()
        self.amount = amount
        self.source = source
        self.receivedAt = receivedAt
        self.category = ""
        self.notes = ""
        self.syncStatus = .local
    }
}

@Model
final class BusinessExpense {
    var id: UUID
    var amount: Double
    var category: String
    var paidAt: Date
    var notes: String
    var syncStatus: SyncStatus

    init(amount: Double, category: String, paidAt: Date = Date()) {
        self.id = UUID()
        self.amount = amount
        self.category = category
        self.paidAt = paidAt
        self.notes = ""
        self.syncStatus = .local
    }
}

@Model
final class BusinessInvoice {
    var id: UUID
    var invoiceNumber: String
    var amount: Double
    var status: InvoiceStatus
    var issuedAt: Date
    var dueDate: Date?
    var paidAt: Date?
    var notes: String

    var client: BusinessClient?

    init(invoiceNumber: String, amount: Double, issuedAt: Date = Date()) {
        self.id = UUID()
        self.invoiceNumber = invoiceNumber
        self.amount = amount
        self.status = .unpaid
        self.issuedAt = issuedAt
        self.notes = ""
    }

    var isOutstanding: Bool {
        status == .unpaid || status == .overdue
    }
}

enum InvoiceStatus: String, Codable, CaseIterable {
    case draft = "DRAFT"
    case sent = "SENT"
    case unpaid = "UNPAID"
    case overdue = "OVERDUE"
    case paid = "PAID"
    case cancelled = "CANCELLED"

    var displayName: String {
        self.rawValue.capitalized
    }
}

@Model
final class Idea {
    var id: UUID
    var title: String
    var ideaDescription: String
    var category: IdeaCategory
    var createdAt: Date
    var isPinned: Bool

    init(title: String, description: String = "", category: IdeaCategory = .general) {
        self.id = UUID()
        self.title = title
        self.ideaDescription = description
        self.category = category
        self.createdAt = Date()
        self.isPinned = false
    }
}

enum IdeaCategory: String, Codable, CaseIterable {
    case business = "Business"
    case app = "App"
    case website = "Website"
    case content = "Content"
    case study = "Study"
    case general = "General"
}