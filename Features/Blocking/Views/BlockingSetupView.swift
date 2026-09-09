import SwiftUI
import FamilyControls
import ManagedSettings

struct BlockingSetupView: View {
    @ObservedObject var service: FocusBlockingService
    @State private var showingPicker = false
    @State private var showingLimitations = false

    var body: some View {
        List {
            Section("Authorization") {
                HStack {
                    Label("Screen Time access", systemImage: "checkmark.shield")
                    Spacer()
                    Text(service.authorizationState.displayName)
                        .foregroundStyle(service.authorizationState == .authorized ? .green : .orange)
                }

                if service.authorizationState != .authorized {
                    Button {
                        showingLimitations = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(service.authorizationState.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Open Screen Time Settings")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }
            }

            Section("Blocked Applications") {
                if service.selectedApps.applications.isEmpty {
                    Text("No applications selected yet.")
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(service.selectedApps.applications.count) application(s) will be restricted during focus sessions.")
                        .font(.subheadline)
                }

                Button("Choose Applications") {
                    showingPicker = true
                }
                .disabled(service.authorizationState != .authorized)
            } footer: {
                Text("Only use this screen to select apps. This uses Apple's Family Controls app picker.")
            }

            Section("How it works") {
                LimitationsExplanationRow {
                    showingLimitations = true
                }
            }
        }
        .navigationTitle("Focus Protection")
        .familyActivityPicker(isPresented: $showingPicker, selection: $service.selectedApps)
        .sheet(isPresented: $showingLimitations) {
            NavigationStack {
                FocusLimitationsView()
            }
        }
    }
}

struct LimitationsExplanationRow: View {
    var action: (() -> Void)

    var body: some View {
        Button(action: action) {
            Label("iOS limitations", systemImage: "info.circle")
                .foregroundStyle(.blue)
        }
    }
}

struct FocusLimitationsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 44))
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity)

                Text("This feature uses Apple's Screen Time APIs.")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text("""
                iPhone controls which applications and behaviors are available to third-party apps. Some restrictions require Apple authorization (Screen Time approval) and may differ by iOS version.

                This app:
                • Requests authorization once, explicitly, through the system prompt.
                • Only restricts the applications you select.
                • Removes restrictions when the session ends, per your policy.
                • Never bypasses Apple's security model.

                If authorization is not approved, the app cannot restrict applications and will say so clearly. There is no alternative that bypasses Screen Time.
                """)
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationTitle("Focus Limitations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}