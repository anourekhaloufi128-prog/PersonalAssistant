import SwiftUI
import SwiftData

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var focusManager = FocusSessionManager()
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @State private var showingAddTask = false
    @State private var activeFocusSession: FocusSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let recommendation = viewModel.recommendation {
                        NextActionCard(recommendation: recommendation) {
                            startFocus(with: recommendation)
                        }
                    } else {
                        EmptyActionsCard()
                    }

                    todayPlanSection
                    progressSection
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(AppTheme.background)
            .navigationTitle("My Day")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: AIAssistantView()) {
                        Image(systemName: "sparkles")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                TaskEditView(mode: .create)
            }
            .refreshable {
                viewModel.loadToday()
                WidgetSnapshotService.refresh(modelContext: modelContext)
            }
            .toolbarVisibility(.automatic, for: .tabBar)
        }
        .onAppear {
            viewModel.configure(modelContext: modelContext)
            WidgetSnapshotService.refresh(modelContext: modelContext)
        }
        .sheet(item: $activeFocusSession) { session in
            ActiveFocusView(session: session, manager: focusManager) {
                viewModel.loadToday()
                WidgetSnapshotService.refresh(modelContext: modelContext)
            }
        }
    }

    private func startFocus(with recommendation: PriorityRecommendation) {
        let session = focusManager.startSession(
            plannedMinutes: recommendation.estimatedMinutes,
            label: recommendation.title
        )
        modelContext.insert(session)
        activeFocusSession = session
    }

    private var todayPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Today's Plan") {
                Button("Generate") {
                    viewModel.generateTodayPlan()
                    WidgetSnapshotService.refresh(modelContext: modelContext)
                }
            }

            if viewModel.isGeneratingPlan {
                LoadingSkeleton()
            } else if viewModel.todayPlanItems.isEmpty {
                Text("No plan yet. Generate a balanced plan for today.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.todayPlanItems.enumerated()), id: \.element.id) { index, item in
                        PlanRow(index: index + 1, item: item) {
                            viewModel.togglePlanItem(item)
                        }
                    }
                }
            }
        }
    }

    private var progressSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Progress")

            HStack(spacing: 12) {
                StatCard(
                    title: "Study today",
                    value: viewModel.todayStudyMinutes.minutesToHoursLabel,
                    icon: "book.fill",
                    color: .blue
                )
                StatCard(
                    title: "Focus today",
                    value: viewModel.todayFocusMinutes.minutesToHoursLabel,
                    icon: "timer",
                    color: .green
                )
            }
        }
    }
}

struct NextActionCard: View {
    let recommendation: PriorityRecommendation
    var onStart: (() -> Void)
    @State private var showDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("WHAT SHOULD I DO NOW?", systemImage: "bolt.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(spacing: 12) {
                Image(systemName: iconName(for: recommendation.category))
                    .font(.title2)
                    .foregroundStyle(AppTheme.categoryColor(recommendation.category))
                    .frame(width: 44, height: 44)
                    .background(
                        AppTheme.categoryColor(recommendation.category).opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 12)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.title3.weight(.bold))
                    Text("\(recommendation.estimatedMinutes) minutes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                CategoryBadge(category: recommendation.category)
            }

            Label(recommendation.reason, systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button {
                    onStart()
                } label: {
                    Label("START", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    showDetails = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.headline)
                }
                .buttonStyle(.bordered)
            }
        }
        .cardStyle(padding: 20)
        .background(
            LinearGradient(
                colors: [
                    AppTheme.categoryColor(recommendation.category).opacity(0.12),
                    AppTheme.cardBackground
                ],
                startPoint: .topLeading,
                endPoint: .center
            ),
            in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        )
        .sheet(isPresented: $showDetails) {
            RecommendationDetailView(recommendation: recommendation)
        }
    }

    private func iconName(for category: TaskCategory) -> String {
        switch category {
        case .study: return "graduationcap"
        case .business: return "briefcase"
        case .wellness: return "heart"
        case .personal: return "person"
        case .goal: return "target"
        }
    }
}

struct EmptyActionsCard: View {
    @State private var showIdea = false
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundStyle(.green)
            Text("Nothing pending")
                .font(.headline)
            Text("Add a task, exam, or business commitment and the assistant will prioritize it for you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

struct PlanRow: View {
    let index: Int
    let item: PlannedItem
    var onTap: (() -> Void)

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text("\(index)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(AppTheme.categoryColor(item.category), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(item.isCompleted ? .secondary : .primary)
                        .strikethrough(item.isCompleted)
                    if let reason = item.reason {
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()

                Text(item.estimatedMinutes.minutesToHoursLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
            }
            .cardStyle(padding: 12)
        }
        .buttonStyle(.plain)
    }
}

struct RecommendationDetailView: View {
    let recommendation: PriorityRecommendation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(recommendation.title)
                    .font(.title2.weight(.bold))
                Text(recommendation.reason)
                    .font(.body)
                    .foregroundStyle(.secondary)
                Text("Estimated time: \(recommendation.estimatedMinutes) minutes")
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .navigationTitle("Why this task?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

extension Notification.Name {
    static let startFocusSession = Notification.Name("startFocusSession")
}