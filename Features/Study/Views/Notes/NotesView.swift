import SwiftUI
import SwiftData

struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]
    @State private var showingEditor = false

    var body: some View {
        List {
            ForEach(notes) { note in
                NavigationLink {
                    NoteEditorView(note: note)
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(note.title)
                            .font(.subheadline.weight(.medium))
                        Text(note.content.isEmpty ? "Empty note" : note.content.prefix(80) + "...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    modelContext.delete(notes[index])
                }
            }

            Section {
                Button {
                    showingEditor = true
                } label: {
                    Label("Add Note", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Notes")
        .sheet(isPresented: $showingEditor) {
            NoteEditorView()
        }
        .overlay {
            if notes.isEmpty {
                EmptyStateView(
                    icon: "note.text",
                    title: "No Notes",
                    message: "Capture lecture notes, summaries, and ideas by subject.",
                    actionTitle: "Add Note",
                    action: { showingEditor = true }
                )
            }
        }
    }
}

struct NoteEditorView: View {
    var note: Note?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var content = ""
    @State private var selectedSubjectID: UUID?

    @Query(sort: \Subject.name) private var subjects: [Subject]

    init(note: Note? = nil) {
        self.note = note
        _title = State(initialValue: note?.title ?? "")
        _content = State(initialValue: note?.content ?? "")
        _selectedSubjectID = State(initialValue: note?.subject?.id)
    }

    var body: some View {
        Form {
            Section {
                TextField("Title", text: $title)
                TextField("Content", text: $content, axis: .vertical)
                    .lineLimit(12...)
                Picker("Subject (optional)", selection: $selectedSubjectID) {
                    Text("None").tag(UUID?.none)
                    ForEach(subjects) { subject in
                        Text(subject.name).tag(subject.id as UUID?)
                    }
                }
            }
        }
        .navigationTitle(note == nil ? "New Note" : "Edit Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let target: Note
                    if let note {
                        target = note
                        target.title = title
                        target.content = content
                        target.updatedAt = Date()
                    } else {
                        target = Note(title: title, content: content)
                        modelContext.insert(target)
                    }
                    if let selectedSubjectID {
                        target.subject = subjects.first { $0.id == selectedSubjectID }
                    }
                    dismiss()
                }
                .disabled(title.isEmpty)
            }
        }
    }
}