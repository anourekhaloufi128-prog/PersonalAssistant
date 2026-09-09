import SwiftUI
import SwiftData

struct FlashcardsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var flashcards: [Flashcard]
    @State private var isReviewing = false

    var body: some View {
        List {
            Section("Review") {
                Button {
                    isReviewing = true
                } label: {
                    Label("Review Flashcards", systemImage: "rectangle.on.rectangle.angled")
                }
                .disabled(flashcards.isEmpty)
            }

            Section("All Flashcards") {
                ForEach(flashcards) { card in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.front)
                            .font(.subheadline.weight(.semibold))
                        Text(card.back)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        modelContext.delete(flashcards[index])
                    }
                }
            }

            Section {
                NavigationLink {
                    FlashcardEditorView()
                } label: {
                    Label("Add Flashcard", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Flashcards")
        .fullScreenCover(isPresented: $isReviewing) {
            if !flashcards.isEmpty {
                FlashcardReviewView(cards: flashcards.shuffled())
            }
        }
        .overlay {
            if flashcards.isEmpty {
                EmptyStateView(
                    icon: "rectangle.on.rectangle.angled",
                    title: "No Flashcards",
                    message: "Create flashcards to remember key concepts, formulas, and vocabulary.",
                    actionTitle: "Add Flashcard",
                    action: {}
                )
            }
        }
    }
}

struct FlashcardEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var front = ""
    @State private var back = ""
    @State private var selectedSubjectID: UUID?
    @State private var selectedTopicID: UUID?

    @Query(sort: \Subject.name) private var subjects: [Subject]

    var body: some View {
        Form {
            Section("Card") {
                TextField("Front (question)", text: $front, axis: .vertical)
                TextField("Back (answer)", text: $back, axis: .vertical)
            }
            Section("Context") {
                Picker("Subject (optional)", selection: $selectedSubjectID) {
                    Text("None").tag(UUID?.none)
                    ForEach(subjects) { subject in
                        Text(subject.name).tag(subject.id as UUID?)
                    }
                }
            }
        }
        .navigationTitle("New Flashcard")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let card = Flashcard(front: front, back: back)
                    if let selectedSubjectID {
                        card.subject = subjects.first { $0.id == selectedSubjectID }
                    }
                    modelContext.insert(card)
                    dismiss()
                }
                .disabled(front.isEmpty || back.isEmpty)
            }
        }
    }
}

struct FlashcardReviewView: View {
    let cards: [Flashcard]
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var isFlipped = false

    var body: some View {
        VStack(spacing: 24) {
            header
            Spacer()
            cardView
            Spacer()
            controls
        }
        .padding()
        .background(AppTheme.background)
    }

    private var header: some View {
        HStack {
            Text("\(index + 1) of \(cards.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var cardView: some View {
        Button {
            withAnimation(.spring(duration: 0.4)) {
                isFlipped.toggle()
            }
        } label: {
            VStack(spacing: 20) {
                Text(isFlipped ? cards[index].back : cards[index].front)
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)
                Text(isFlipped ? "Front" : "Back (tap to flip)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 320)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private var controls: some View {
        HStack(spacing: 20) {
            Button {
                markKnown()
            } label: {
                Label("Known", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            Button {
                markReviewAgain()
            } label: {
                Label("Review Again", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .disabled(index >= cards.count - 1)
    }

    private func markKnown() {
        let card = cards[index]
        card.isKnown = true
        card.reviewCount += 1
        card.lastReviewedAt = Date()
        nextCard()
    }

    private func markReviewAgain() {
        let card = cards[index]
        card.reviewCount += 1
        card.lastReviewedAt = Date()
        nextCard()
    }

    private func nextCard() {
        withAnimation(.spring(duration: 0.4)) {
            isFlipped = false
            if index < cards.count - 1 {
                index += 1
            } else {
                dismiss()
            }
        }
    }
}