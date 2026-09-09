import SwiftUI
import SwiftData

struct WaterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WaterLog.loggedAt, order: .reverse) private var logs: [WaterLog]
    @State private var customAmount = 250
    @State private var showingCustom = false

    private var todayML: Int {
        logs.filter { Calendar.current.isDateInToday($0.loggedAt) }.reduce(0) { $0 + $1.amountML }
    }

    var body: some View {
        List {
            Section("Today") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(todayML) ml")
                            .font(.title.bold())
                        Spacer()
                        Text("goal 2000 ml")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: min(1, Double(todayML) / 2000))
                }
            }

            Section("Quick Log") {
                Button("+250 ml") { log(250) }
                Button("+500 ml") { log(500) }
                Button("Custom amount") { showingCustom = true }
            }

            Section("Log") {
                ForEach(logs.prefix(15)) { log in
                    HStack {
                        Text("+\(log.amountML) ml")
                            .font(.subheadline)
                        Spacer()
                        Text(log.loggedAt.timeLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Water")
        .sheet(isPresented: $showingCustom) {
            NavigationStack {
                Form {
                    Stepper("\(customAmount) ml", value: $customAmount, in: 50...2000, step: 50)
                    Button("Log \(customAmount) ml") {
                        log(customAmount)
                        showingCustom = false
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .navigationTitle("Custom Amount")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.height(220)])
        }
    }

    private func log(_ amount: Int) {
        let log = WaterLog(amountML: amount)
        modelContext.insert(log)
    }
}