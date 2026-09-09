import SwiftUI
import SwiftData

extension Double {
    var currencyLabel: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: self)) ?? "$\(self)"
    }
}

struct ClientsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BusinessClient.name) private var clients: [BusinessClient]
    @State private var showingEditor = false

    var body: some View {
        List {
            Section("Clients") {
                ForEach(clients) { client in
                    NavigationLink {
                        ClientDetailView(client: client)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(client.name)
                                    .font(.subheadline.weight(.medium))
                                if !client.company.isEmpty {
                                    Text(client.company)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(client.status.displayName)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor(client.status).opacity(0.15), in: Capsule())
                                .foregroundStyle(statusColor(client.status))
                        }
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        modelContext.delete(clients[index])
                    }
                }
            }

            Section {
                Button {
                    showingEditor = true
                } label: {
                    Label("Add Client", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Clients")
        .sheet(isPresented: $showingEditor) {
            ClientEditorView()
        }
        .overlay {
            if clients.isEmpty {
                EmptyStateView(
                    icon: "person.2",
                    title: "No Clients",
                    message: "Track your clients, their status, projects, and invoices.",
                    actionTitle: "Add Client",
                    action: { showingEditor = true }
                )
            }
        }
    }

    private func statusColor(_ status: ClientStatus) -> Color {
        switch status {
        case .lead: return .orange
        case .contacted: return .blue
        case .negotiating: return .purple
        case .active: return .green
        case .completed: return .gray
        case .lost: return .red
        }
    }
}

struct ClientEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var company = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var status: ClientStatus = .lead
    @State private var notes = ""
    @State private var source = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact") {
                    TextField("Name", text: $name)
                    TextField("Company", text: $company)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                }
                Section {
                    Picker("Status", selection: $status) {
                        ForEach(ClientStatus.allCases, id: \.self) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                    TextField("Source", text: $source)
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("New Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let client = BusinessClient(name: name, company: company, status: status)
                        client.phone = phone
                        client.email = email
                        client.notes = notes
                        client.source = source
                        modelContext.insert(client)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct ClientDetailView: View {
    let client: BusinessClient

    var body: some View {
        Form {
            Section("Client") {
                Text(client.name).font(.headline)
                if !client.company.isEmpty {
                    LabeledContent("Company", value: client.company)
                }
                if !client.phone.isEmpty {
                    LabeledContent("Phone", value: client.phone)
                }
                if !client.email.isEmpty {
                    LabeledContent("Email", value: client.email)
                }
                LabeledContent("Status", value: client.status.displayName)
            }
            Section("Projects") {
                if let projects = client.projects, !projects.isEmpty {
                    ForEach(projects) { project in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(project.title)
                                .font(.subheadline.weight(.medium))
                            Text(project.status.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("No projects.")
                        .foregroundStyle(.secondary)
                }
            }
            Section("Invoices") {
                if let invoices = client.invoices, !invoices.isEmpty {
                    ForEach(invoices) { invoice in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(invoice.invoiceNumber)
                                    .font(.subheadline)
                                Text(invoice.status.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(invoice.amount.currencyLabel)
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                } else {
                    Text("No invoices.")
                        .foregroundStyle(.secondary)
                }
            }
            if !client.notes.isEmpty {
                Section("Notes") {
                    Text(client.notes)
                }
            }
        }
        .navigationTitle(client.name)
    }
}