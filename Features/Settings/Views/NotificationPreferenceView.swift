import SwiftUI
import SwiftData
import UserNotifications

struct NotificationPreferenceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [NotificationPreference]
    @State private var morningTime = Date()
    @State private var eveningTime = Date()

    @StateObject private var notificationManager = NotificationManager()

    var body: some View {
        Form {
            Section {
                Button {
                    Task {
                        await notificationManager.requestAuthorization()
                    }
                } label: {
                    Label("Request notification permission", systemImage: "bell.badge")
                }
            }

            Section("Reminder Types") {
                ForEach(NotificationType.allCases, id: \.self) { type in
                    NotificationToggleRow(type: type, isOn: binding(for: type))
                }
            } footer: {
                Text("Notifications are never sent to spam. Each reminder can be toggled individually.")
            }
        }
        .navigationTitle("Notifications")
    }

    private func binding(for type: NotificationType) -> Binding<Bool> {
        Binding(
            get: {
                preferences.first { $0.type == type }?.isEnabled ?? true
            },
            set: { newValue in
                if let pref = preferences.first(where: { $0.type == type }) {
                    pref.isEnabled = newValue
                } else {
                    let pref = NotificationPreference(type: type, isEnabled: newValue)
                    modelContext.insert(pref)
                }
                try? modelContext.save()
            }
        )
    }
}

struct NotificationToggleRow: View {
    let type: NotificationType
    let isOn: Binding<Bool>

    var body: some View {
        Toggle(type.rawValue, isOn: isOn)
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("themePreference") private var themeRaw = "system"
    @AppStorage("reduceMotion") private var reduceMotion = false

    var body: some View {
        Form {
            Section("Theme") {
                Picker("Appearance", selection: $themeRaw) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
            }
            Section("Motion") {
                Toggle("Reduce motion", isOn: $reduceMotion)
            }
        }
        .navigationTitle("Appearance")
    }
}