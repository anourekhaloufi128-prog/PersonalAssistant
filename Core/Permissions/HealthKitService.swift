import Foundation
import HealthKit

@MainActor
final class HealthKitService: ObservableObject {
    @Published var isAuthorized = false
    @Published var isAvailable = HKHealthStore.isHealthDataAvailable()

    private let store = HKHealthStore()

    func requestAuthorization() async {
        guard isAvailable else { return }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        do {
            try await store.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    func readStepsToday() async -> Double? {
        guard isAuthorized, isAvailable else { return nil }
        let type = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type, predicate: predicate)],
            sortDescriptors: []
        )
        do {
            let samples = try await descriptor.result(for: store)
            return samples.compactMap { $0 as? HKQuantitySample }
                .reduce(0.0) { $0 + $1.quantity.doubleValue(for: .count()) }
        } catch {
            return nil
        }
    }

    func readSleepLastNight() async -> (bedtime: Date?, wakeTime: Date?)? {
        guard isAuthorized, isAvailable else { return nil }
        let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let start = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: type, predicate: predicate)],
            sortDescriptors: []
        )
        do {
            let samples = try await descriptor.result(for: store)
            let inBed = samples.compactMap { $0 as? HKCategorySample }
                .filter { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue }
            let start = inBed.min(by: { $0.startDate < $1.startDate })?.startDate
            let end = inBed.max(by: { $0.endDate < $1.endDate })?.endDate
            guard let start else { return nil }
            return (start, end ?? start)
        } catch {
            return nil
        }
    }
}