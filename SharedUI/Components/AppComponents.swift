import SwiftUI

enum AppTheme {
    static let accent = Color.accentColor
    static let background = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary

    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 16
    static let spacingLarge: CGFloat = 24

    static let cornerRadius: CGFloat = 16
    static let cardCornerRadius: CGFloat = 20

    static func categoryColor(_ category: TaskCategory) -> Color {
        switch category {
        case .study: return .blue
        case .business: return .orange
        case .wellness: return .green
        case .personal: return .purple
        case .goal: return .indigo
        }
    }

    static func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )
    }
}

struct CategoryBadge: View {
    let category: TaskCategory

    var body: some View {
        Text(category.rawValue)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.categoryColor(category), in: Capsule())
    }
}

struct PriorityBadge: View {
    let priority: TaskPriority

    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(AppTheme.priorityColor(priority))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .overlay(Capsule().stroke(AppTheme.priorityColor(priority), lineWidth: 1))
    }
}

struct ProgressRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.weight(.bold))
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline)
            }
        }
    }
}

struct LoadingSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.background.secondary)
                .frame(height: 16)
                .frame(maxWidth: 180)
            RoundedRectangle(cornerRadius: 8)
                .fill(.background.secondary)
                .frame(height: 14)
            RoundedRectangle(cornerRadius: 8)
                .fill(.background.secondary)
                .frame(height: 14)
                .frame(maxWidth: 240)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }
}

struct QuickAddMenu: View {
    var addTask: (() -> Void)? = nil
    var addClient: (() -> Void)? = nil
    var logWater: (() -> Void)? = nil
    var saveIdea: (() -> Void)? = nil

    var body: some View {
        Menu {
            if let addTask {
                Button(action: addTask) {
                    Label("Add Task", systemImage: "checklist")
                }
            }
            if let addClient {
                Button(action: addClient) {
                    Label("Add Client", systemImage: "person.crop.circle.badge.plus")
                }
            }
            if let logWater {
                Button(action: logWater) {
                    Label("Log Water", systemImage: "drop.fill")
                }
            }
            if let saveIdea {
                Button(action: saveIdea) {
                    Label("Save Idea", systemImage: "lightbulb")
                }
            }
        } label: {
            Image(systemName: "plus")
                .font(.headline)
        }
    }
}