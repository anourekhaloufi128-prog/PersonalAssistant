import SwiftUI
import SwiftData

struct BusinessDashboardView: View {
    @Query private var projects: [BusinessProject]
    @Query private var leads: [BusinessLead]
    @Query private var tasks: [BusinessTask]
    @Query private var incomes: [BusinessIncome]
    @Query private var expenses: [BusinessExpense]
    @Query private var invoices: [BusinessInvoice]

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    StatCard(title: "Active projects", value: "\(activeProjectsCount)", icon: "folder", color: .blue)
                    StatCard(title: "Open leads", value: "\(openLeadsCount)", icon: "funnel", color: .orange)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                HStack(spacing: 12) {
                    StatCard(title: "Due today", value: "\(tasksDueToday)", icon: "clock", color: .red)
                    StatCard(title: "Outstanding", value: outstandingLabel, icon: "dollarsign", color: .green)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section("Revenue entered") {
                LabeledContent("Income", value: incomes.reduce(0) { $0 + $1.amount }.currencyLabel)
                LabeledContent("Expenses", value: expenses.reduce(0) { $0 + $1.amount }.currencyLabel)
                LabeledContent("Net", value: (incomes.reduce(0) { $0 + $1.amount } - expenses.reduce(0) { $0 + $1.amount }).currencyLabel)
                    .foregroundStyle(.secondary)
            } footer: {
                Text("Only shows figures you entered yourself. Note: This is not accounting or financial advice.")
            }

            Section("Follow-ups") {
                let dueLeads = leads
                    .filter { $0.followUpDate != nil && $0.status != .converted && $0.status != .lost }
                    .sorted { $0.followUpDate! < $1.followUpDate! }
                if dueLeads.isEmpty {
                    Text("No pending follow-ups.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(dueLeads.prefix(5), id: \.id) { lead in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(lead.name)
                                .font(.subheadline.weight(.medium))
                            Text("Follow up \(lead.followUpDate?.relativeDayLabel() ?? "")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var activeProjectsCount: Int {
        projects.filter { $0.status == .active }.count
    }

    private var openLeadsCount: Int {
        leads.filter { $0.status != .lost && $0.status != .converted }.count
    }

    private var tasksDueToday: Int {
        tasks.filter { $0.status == .todo && $0.dueDate.map { Calendar.current.isDateInToday($0) } == true }.count
    }

    private var outstandingLabel: String {
        invoices.filter(\.isOutstanding).reduce(0) { $0 + $1.amount }.currencyLabel
    }
}