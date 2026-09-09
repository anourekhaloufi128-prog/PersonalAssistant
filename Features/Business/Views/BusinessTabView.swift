import SwiftUI
import SwiftData

struct BusinessTabView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Overview") {
                    NavigationLink {
                        BusinessDashboardView()
                    } label: {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                    }
                }

                Section("Relations") {
                    NavigationLink {
                        ClientsView()
                    } label: {
                        Label("Clients", systemImage: "person.2.fill")
                    }
                    NavigationLink {
                        LeadsView()
                    } label: {
                        Label("Leads", systemImage: "funnel.fill")
                    }
                }

                Section("Work") {
                    NavigationLink {
                        BusinessProjectsView()
                    } label: {
                        Label("Projects", systemImage: "folder.fill")
                    }
                    NavigationLink {
                        BusinessTasksView()
                    } label: {
                        Label("Tasks", systemImage: "checkmark.circle")
                    }
                }

                Section("Finance") {
                    NavigationLink {
                        BusinessFinanceView()
                    } label: {
                        Label("Income & Expenses", systemImage: "dollarsign.circle.fill")
                    }
                    NavigationLink {
                        BusinessInvoicesView()
                    } label: {
                        Label("Invoices", systemImage: "doc.text.fill")
                    }
                }

                Section("More") {
                    NavigationLink {
                        IdeasView()
                    } label: {
                        Label("Ideas", systemImage: "lightbulb.fill")
                    }
                    NavigationLink {
                        GoalsView(isPartOfBusiness: true)
                    } label: {
                        Label("Business Goals", systemImage: "target")
                    }
                }
            }
            .navigationTitle("Business")
        }
    }
}