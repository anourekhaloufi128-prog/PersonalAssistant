import SwiftUI
import SwiftData

struct BusinessFinanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BusinessIncome.receivedAt, order: .reverse) private var incomes: [BusinessIncome]
    @Query(sort: \BusinessExpense.paidAt, order: .reverse) private var expenses: [BusinessExpense]
    @State private var showingIncome = false
    @State private var showingExpense = false

    private var totalIncome: Double { incomes.reduce(0) { $0 + $1.amount } }
    private var totalExpenses: Double { expenses.reduce(0) { $0 + $1.amount } }

    var body: some View {
        List {
            Section("Summary") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(totalIncome.currencyLabel)
                            .font(.title2.bold())
                            .foregroundStyle(.green)
                        Spacer()
                        Label("Income", systemImage: "arrow.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(totalExpenses.currencyLabel)
                            .font(.title2.bold())
                            .foregroundStyle(.red)
                        Spacer()
                        Label("Expenses", systemImage: "arrow.up")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Divider()
                    HStack {
                        Text("Net")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text((totalIncome - totalExpenses).currencyLabel)
                            .font(.headline)
                            .foregroundStyle(totalIncome - totalExpenses >= 0 ? .green : .red)
                    }
                }
            } footer: {
                Text("Figures are entered manually and are not accounting or financial advice.")
            }

            Section {
                Button {
                    showingIncome = true
                } label: {
                    Label("Add Income", systemImage: "plus.circle.fill")
                        .foregroundStyle(.green)
                }
                Button {
                    showingExpense = true
                } label: {
                    Label("Add Expense", systemImage: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
            }

            Section("Recent Income") {
                if incomes.isEmpty {
                    Text("No income recorded.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(incomes.prefix(10)) { income in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(income.source.isEmpty ? "Income" : income.source)
                                    .font(.subheadline)
                                Text(income.receivedAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("+\(income.amount.currencyLabel)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.green)
                        }
                    }
                    .onDelete { offsets in
                        let recent = Array(incomes.prefix(10))
                        for index in offsets {
                            modelContext.delete(recent[index])
                        }
                    }
                }
            }

            Section("Recent Expenses") {
                if expenses.isEmpty {
                    Text("No expenses recorded.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(expenses.prefix(10)) { expense in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(expense.category.isEmpty ? "Expense" : expense.category)
                                    .font(.subheadline)
                                Text(expense.paidAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("-\(expense.amount.currencyLabel)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.red)
                        }
                    }
                    .onDelete { offsets in
                        let recent = Array(expenses.prefix(10))
                        for index in offsets {
                            modelContext.delete(recent[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("Finance")
        .sheet(isPresented: $showingIncome) {
            IncomeEditorView()
        }
        .sheet(isPresented: $showingExpense) {
            ExpenseEditorView()
        }
    }
}

struct IncomeEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var amount = 0.0
    @State private var source = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Amount", value: $amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                TextField("Source", text: $source)
                DatePicker("Date", selection: $date)
            }
            .navigationTitle("Add Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let income = BusinessIncome(amount: amount, source: source, receivedAt: date)
                        modelContext.insert(income)
                        dismiss()
                    }
                    .disabled(amount <= 0)
                }
            }
        }
    }
}

struct ExpenseEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var amount = 0.0
    @State private var category = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Amount", value: $amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                TextField("Category", text: $category)
                DatePicker("Date", selection: $date)
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let expense = BusinessExpense(amount: amount, category: category, paidAt: date)
                        modelContext.insert(expense)
                        dismiss()
                    }
                    .disabled(amount <= 0)
                }
            }
        }
    }
}

struct BusinessInvoicesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BusinessInvoice.issuedAt, order: .reverse) private var invoices: [BusinessInvoice]
    @State private var showingEditor = false

    var body: some View {
        List {
            Section("Outstanding") {
                let outstanding = invoices.filter(\.isOutstanding)
                if outstanding.isEmpty {
                    Text("No outstanding invoices.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(outstanding) { invoice in
                        InvoiceRow(invoice: invoice) {
                            markPaid(invoice)
                        }
                    }
                }
            }

            Section("All Invoices") {
                ForEach(invoices) { invoice in
                    InvoiceRow(invoice: invoice) {
                        markPaid(invoice)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        modelContext.delete(invoices[index])
                    }
                }
            }

            Section {
                Button {
                    showingEditor = true
                } label: {
                    Label("Add Invoice", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Invoices")
        .sheet(isPresented: $showingEditor) {
            InvoiceEditorView()
        }
        .overlay {
            if invoices.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: "No Invoices",
                    message: "Track invoices, amounts, and outstanding balances.",
                    actionTitle: "Add Invoice",
                    action: { showingEditor = true }
                )
            }
        }
    }

    private func markPaid(_ invoice: BusinessInvoice) {
        invoice.status = .paid
        invoice.paidAt = Date()
    }
}

struct InvoiceRow: View {
    let invoice: BusinessInvoice
    var onMarkPaid: (() -> Void)

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(invoice.invoiceNumber)
                    .font(.subheadline.weight(.medium))
                Text(invoice.issuedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(invoice.amount.currencyLabel)
                    .font(.subheadline.weight(.semibold))
                if invoice.isOutstanding {
                    Button("Mark paid", action: onMarkPaid)
                        .font(.caption)
                } else {
                    Text("Paid")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
    }
}

struct InvoiceEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var invoiceNumber = ""
    @State private var amount = 0.0
    @State private var status: InvoiceStatus = .unpaid
    @State private var issuedDate = Date()
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(14 * 86400)
    @State private var selectedClientID: UUID?

    @Query(sort: \BusinessClient.name) private var clients: [BusinessClient]

    var body: some View {
        NavigationStack {
            Form {
                Section("Invoice") {
                    TextField("Invoice number", text: $invoiceNumber)
                    TextField("Amount", value: $amount, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                    DatePicker("Issued", selection: $issuedDate)
                    Toggle("Has due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate)
                    }
                }
                Section("Client (optional)") {
                    Picker("Client", selection: $selectedClientID) {
                        Text("None").tag(UUID?.none)
                        ForEach(clients) { client in
                            Text(client.name).tag(client.id as UUID?)
                        }
                    }
                }
            }
            .navigationTitle("New Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let invoice = BusinessInvoice(invoiceNumber: invoiceNumber, amount: amount, issuedAt: issuedDate)
                        invoice.status = status
                        invoice.dueDate = hasDueDate ? dueDate : nil
                        if let selectedClientID {
                            invoice.client = clients.first { $0.id == selectedClientID }
                        }
                        modelContext.insert(invoice)
                        dismiss()
                    }
                    .disabled(invoiceNumber.isEmpty || amount <= 0)
                }
            }
        }
    }
}