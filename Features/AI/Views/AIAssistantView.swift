import SwiftUI
import SwiftData

struct AIAssistantView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AIAssistantViewModel()
    @State private var showingMemory = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if viewModel.messages.isEmpty {
                            welcomeMessage
                        }

                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }

                        if viewModel.isLoading {
                            HStack {
                                ActivityIndicatorView(style: .medium)
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let last = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            promptBar
        }
        .navigationTitle("Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingMemory = true
                } label: {
                    Image(systemName: "brain.head.profile")
                }
            }
        }
        .sheet(isPresented: $showingMemory) {
            MemoryView()
        }
        .task {
            viewModel.configure(modelContext: modelContext)
        }
    }

    private var welcomeMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ask me anything")
                .font(.title2.weight(.bold))
            Text("""
            "What should I do now?"
            "I have one hour."
            "Move Physics to tomorrow."
            "I finished Mathematics."
            "Create a quiz about algebra."
            "Add a task to contact my client."
            "Start a focus session."
            """)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineSpacing(6)
        }
        .cardStyle()
    }

    private var promptBar: some View {
        HStack(spacing: 10) {
            TextField("Message", text: $viewModel.input, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20))

            Button {
                Task { await viewModel.send() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(viewModel.input.isEmpty ? .secondary : .blue)
            }
            .disabled(viewModel.input.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

struct MessageBubble: View {
    let message: AIMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 40)
            }
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 2) {
                Text(message.content)
                    .font(.subheadline)
                    .textSelection(.enabled)
                Text(message.createdAt.timeLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(
                message.role == .user
                    ? Color.blue.opacity(0.15)
                    : AppTheme.cardBackground,
                in: RoundedRectangle(cornerRadius: 16)
            )
            if message.role == .assistant {
                Spacer(minLength: 40)
            }
        }
    }
}

@MainActor
final class AIAssistantViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var input = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var aiService: AIService?
    private var executor: AIActionExecutor?
    private var contextAssembler: ContextAssembler?

    func configure(modelContext: ModelContext) {
        guard aiService == nil else { return }
        let ai = AIService()
        aiService = ai
        executor = AIActionExecutor(modelContext: modelContext)
        contextAssembler = ContextAssembler(modelContext: modelContext)
        appendSystemMessageIfNeeded()
    }

    func send() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        let userMessage = AIMessage(content: text, role: .user)
        messages.append(userMessage)
        input = ""
        isLoading = true
        errorMessage = nil

        do {
            let context = contextAssembler?.assemble(for: text) ?? AIContext()
            let response = try await aiService?.sendMessage(text, context: context) ?? "AI is not configured. Check your connection."

            if let action = try await aiService?.requestAction(text, context: context),
               AIResponseValidator.validateActionPayload(actionDictionary(from: action)) {
                let result = executor?.execute(action)
                if let result {
                    let executionText = actionNeedsConfirmation(result.needsConfirmation)
                        ? "I'd like to confirm: \(result.message)"
                        : result.message
                    messages.append(AIMessage(content: "\(response)\n\n[\(executionText)]", role: .assistant))
                }
            } else {
                messages.append(AIMessage(content: response, role: .assistant))
            }
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "Something went wrong connecting to the assistant."
            errorMessage = message
            messages.append(AIMessage(content: message, role: .assistant))
        }

        isLoading = false
    }

    private func appendSystemMessageIfNeeded() {
        guard messages.isEmpty else { return }
        let welcome = AIMessage(
            content: "I'm here to help you decide what to do next. Try asking \"What should I study now?\"",
            role: .assistant
        )
        messages.append(welcome)
    }

    private func actionDictionary(from action: AIActionRequest) -> Any {
        [
            "action": action.action.rawValue,
            "parameters": action.parameters,
            "requiresConfirmation": action.requiresConfirmation
        ]
    }

    private func actionNeedsConfirmation(_ needsConfirmation: Bool) -> Bool {
        needsConfirmation
    }
}