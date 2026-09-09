import SwiftUI
import SwiftData

struct MemoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AIMemory.category) private var memories: [AIMemory]
    @State private var showingEditor = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("The assistant stores only useful preferences you choose to keep. It never stores the whole database, and never reads health or financial details for memory.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Stored Memories") {
                    if memories.isEmpty {
                        Text("No memories stored yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(memories) { memory in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(memory.key)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Toggle("", isOn: Binding(
                                        get: { memory.isEnabled },
                                        set: { memory.isEnabled = $0 }
                                    ))
                                    .labelsHidden()
                                }
                                Text(memory.value)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(memory.category)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                modelContext.delete(memories[index])
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showingEditor = true
                    } label: {
                        Label("Add Memory", systemImage: "plus")
                    }
                }

                Section {
                    Button("Clear All Memories", role: .destructive) {
                        for memory in memories {
                            modelContext.delete(memory)
                        }
                    }
                }
            }
            .navigationTitle("AI Memory")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingEditor) {
                MemoryEditorView()
            }
        }
    }
}

struct MemoryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var key = ""
    @State private var value = ""
    @State private var category = "preference"

    var body: some View {
        NavigationStack {
            Form {
                TextField("Key (e.g. preferred_study_duration)", text: $key)
                    .autocapitalization(.none)
                TextField("Value", text: $value)
                TextField("Category", text: $category)
                    .autocapitalization(.none)
            }
            .navigationTitle("New Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let memory = AIMemory(key: key, value: value, category: category)
                        modelContext.insert(memory)
                        dismiss()
                    }
                    .disabled(key.isEmpty || value.isEmpty)
                }
            }
        }
    }
}