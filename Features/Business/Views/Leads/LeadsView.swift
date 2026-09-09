import SwiftUI
import SwiftData

struct LeadsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BusinessLead.createdAt, order: .reverse) private var leads: [BusinessLead]
    @State private var showingEditor = false

    var body: some View {
        List {
            ForEach(leads) { lead in
                NavigationLink {
                    LeadDetailView(lead: lead)
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(lead.name)
                                .font(.subheadline.weight(.medium))
                            if !lead.company.isEmpty {
                                Text(lead.company)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if lead.potentialValue > 0 {
                                Text(lead.potentialValue.currencyLabel)
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text("\(lead.probability)%")
                                .font(.caption.weight(.semibold))
                            if let followUp = lead.followUpDate {
                                Text(followUp.relativeDayLabel())
                                    .font(.caption2)
                                    .foregroundStyle(followUp < Date() ? .red : .secondary)
                            }
                        }
                    }
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    modelContext.delete(leads[index])
                }
            }

            Section {
                Button {
                    showingEditor = true
                } label: {
                    Label("Add Lead", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Leads")
        .sheet(isPresented: $showingEditor) {
            LeadEditorView()
        }
        .overlay {
            if leads.isEmpty {
                EmptyStateView(
                    icon: "funnel",
                    title: "No Leads",
                    message: "Track potential clients, probabilities, and follow-up dates.",
                    actionTitle: "Add Lead",
                    action: { showingEditor = true }
                )
            }
        }
    }
}

struct LeadEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var company = ""
    @State private var service = ""
    @State private var potentialValue = 0.0
    @State private var probability = 20
    @State private var hasFollowUp = false
    @State private var followUpDate = Date().addingTimeInterval(86400)
    @State private var nextAction = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Lead") {
                    TextField("Name", text: $name)
                    TextField("Company", text: $company)
                    TextField("Service", text: $service)
                }
                Section("Value") {
                    TextField("Potential value", value: $potentialValue, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                    Stepper("Probability: \(probability)%", value: $probability, in: 5...100, step: 5)
                }
                Section("Follow-up") {
                    Toggle("Set follow-up", isOn: $hasFollowUp)
                    if hasFollowUp {
                        DatePicker("Follow-up date", selection: $followUpDate)
                    }
                    TextField("Next action", text: $nextAction)
                }
                Section {
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("New Lead")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let lead = BusinessLead(name: name, company: company, service: service, potentialValue: potentialValue)
                        lead.probability = probability
                        lead.followUpDate = hasFollowUp ? followUpDate : nil
                        lead.nextAction = nextAction
                        lead.notes = notes
                        modelContext.insert(lead)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct LeadDetailView: View {
    let lead: BusinessLead

    var body: some View {
        Form {
            Section("Lead") {
                Text(lead.name).font(.headline)
                LabeledContent("Company", value: lead.company.isEmpty ? "—" : lead.company)
                LabeledContent("Service", value: lead.service.isEmpty ? "—" : lead.service)
                LabeledContent("Status", value: lead.status.displayName)
                LabeledContent("Probability", value: "\(lead.probability)%")
                if lead.potentialValue > 0 {
                    LabeledContent("Potential value", value: lead.potentialValue.currencyLabel)
                }
                if let followUp = lead.followUpDate {
                    LabeledContent("Follow-up", value: followUp.formatted(date: .abbreviated, time: .shortened))
                }
                if !lead.nextAction.isEmpty {
                    LabeledContent("Next action", value: lead.nextAction)
                }
            }
            if !lead.notes.isEmpty {
                Section("Notes") {
                    Text(lead.notes)
                }
            }
        }
        .navigationTitle(lead.name)
    }
}