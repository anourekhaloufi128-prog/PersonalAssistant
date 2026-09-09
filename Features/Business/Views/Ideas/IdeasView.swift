import SwiftUI
import SwiftData

struct IdeasView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Idea.createdAt, order: .reverse) private var ideas: [Idea]
    @State private var showingEditor = false

    var body: some View {
        List {
            ForEach(ideas) { idea in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text(idea.title)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(idea.category.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if !idea.ideaDescription.isEmpty {
                        Text(idea.ideaDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(idea.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
            .onDelete { offsets in
                for index in offsets {
                    modelContext.delete(ideas[index])
                }
            }

            Section {
                Button {
                    showingEditor = true
                } label: {
                    Label("Save Idea", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Ideas")
        .sheet(isPresented: $showingEditor) {
            IdeaEditorView()
        }
        .overlay {
            if ideas.isEmpty {
                EmptyStateView(
                    icon: "lightbulb",
                    title: "No Ideas Yet",
                    message: "Capture business, app, website, content and study ideas as they come.",
                    actionTitle: "Save Idea",
                    action: { showingEditor = true }
                )
            }
        }
    }
}

struct IdeaEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var ideaDescription = ""
    @State private var category: IdeaCategory = .general

    var body: some View {
        NavigationStack {
            Form {
                TextField("Idea", text: $title)
                TextField("Details", text: $ideaDescription, axis: .vertical)
                Picker("Category", selection: $category) {
                    ForEach(IdeaCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
            }
            .navigationTitle("Save Idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let idea = Idea(title: title, description: ideaDescription, category: category)
                        modelContext.insert(idea)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}